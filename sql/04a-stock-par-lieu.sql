-- Stock'ESAT — Stock PAR LIEU (un produit peut être présent sur plusieurs lieux)
-- Le produit devient un catalogue ; le stock + les seuils vivent dans `stocks`.

-- 1. Table stocks (produit × lieu)
create table if not exists stocks (
  id            uuid primary key default gen_random_uuid(),
  produit_id    uuid not null references produits(id) on delete cascade,
  site_id       uuid not null references sites(id),
  stock_courant int not null default 0,
  seuil_mini    int default 0,
  seuil_rupture int default 0,
  seuil_cible   int default 0,
  modifie_le    timestamptz default now(),
  unique (produit_id, site_id)
);
alter table stocks enable row level security;
drop policy if exists lecture_stocks on stocks;
create policy lecture_stocks on stocks for select to anon using (true);
do $$ begin alter publication supabase_realtime add table stocks; exception when others then null; end $$;

-- 2. Migration : chaque produit affecté à un lieu -> une ligne de stock
insert into stocks(produit_id, site_id, stock_courant, seuil_mini, seuil_rupture, seuil_cible)
select id, site_id, stock_courant, seuil_mini, seuil_rupture, seuil_cible
from produits
where site_id is not null
on conflict (produit_id, site_id) do nothing;

-- 3. Le lieu du mouvement + le lieu de l'alerte
alter table mouvements add column if not exists site_id uuid references sites(id);
alter table alertes    add column if not exists site_id uuid references sites(id);

-- 4. Trigger stock : met à jour stocks(produit, lieu) — crée la ligne si absente
create or replace function maj_stock_apres_mouvement()
returns trigger language plpgsql security definer as $$
declare v_avant int; v_delta int;
begin
  if new.site_id is null then
    raise exception 'Un lieu (site_id) est requis pour enregistrer un mouvement';
  end if;
  insert into stocks(produit_id, site_id) values (new.produit_id, new.site_id)
    on conflict (produit_id, site_id) do nothing;
  select stock_courant into v_avant from stocks
    where produit_id = new.produit_id and site_id = new.site_id for update;
  v_delta := case when new.type = 'Entrée' then new.quantite else -new.quantite end;
  update stocks set stock_courant = v_avant + v_delta, modifie_le = now()
    where produit_id = new.produit_id and site_id = new.site_id;
  new.stock_avant := v_avant;
  new.stock_apres := v_avant + v_delta;
  return new;
end; $$;

-- 5. Trigger alertes : par (produit, lieu)
create or replace function gerer_alertes()
returns trigger language plpgsql security definer as $$
declare v_s stocks%rowtype;
begin
  select * into v_s from stocks
    where produit_id = new.produit_id and site_id = new.site_id;
  if v_s.stock_courant <= v_s.seuil_mini then
    if not exists (select 1 from alertes
                   where produit_id = v_s.produit_id and site_id = v_s.site_id and statut = 'Ouverte') then
      insert into alertes(produit_id, site_id, type, stock_declenchement)
      values (v_s.produit_id, v_s.site_id,
              case when v_s.stock_courant <= v_s.seuil_rupture then 'Rupture' else 'Sous seuil' end,
              v_s.stock_courant);
    end if;
  else
    update alertes set statut = 'Résolue'
    where produit_id = v_s.produit_id and site_id = v_s.site_id and statut = 'Ouverte';
  end if;
  return new;
end; $$;
