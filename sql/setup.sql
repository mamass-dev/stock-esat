-- Stock'ESAT — Setup complet Supabase/Postgres
-- Idempotent : peut être rejoué sans erreur.

create extension if not exists pgcrypto;

-- ─────────────── Sites (multi-sites : Quetigny, Chenove, Ahuy…) ───────────────
create table if not exists sites (
  id       uuid primary key default gen_random_uuid(),
  nom      text not null,
  ville    text,
  adresse  text,
  actif    boolean default true,
  cree_le  timestamptz default now()
);

-- ─────────────── Référentiels ───────────────
create table if not exists categories (
  id          uuid primary key default gen_random_uuid(),
  nom         text not null,
  picto       text,
  couleur     text,
  ordre       int default 0,
  cree_le     timestamptz default now()
);

-- Emplacements : OPTIONNEL (rangement fin dans une pièce). Non requis au MVP.
create table if not exists emplacements (
  id          uuid primary key default gen_random_uuid(),
  code        text unique not null,
  libelle     text,
  zone        text,
  site_id     uuid references sites(id),
  cree_le     timestamptz default now()
);

create table if not exists fournisseurs (
  id            uuid primary key default gen_random_uuid(),
  nom           text not null,
  contact       text,
  email         text,
  telephone     text,
  delai_jours   int,
  cree_le       timestamptz default now()
);

create table if not exists operateurs (
  id          uuid primary key default gen_random_uuid(),
  nom         text not null,
  pin_hash    text not null,
  badge_uid   text,
  role        text not null default 'operateur'
              check (role in ('operateur','responsable','admin')),
  photo_url   text,
  actif       boolean default true,
  site_id     uuid references sites(id),
  cree_le     timestamptz default now()
);

create table if not exists produits (
  id                uuid primary key default gen_random_uuid(),
  ref               text unique not null,
  nom               text not null,
  photo_url         text,
  categorie_id      uuid references categories(id),
  site_id           uuid references sites(id),           -- site où le produit est stocké
  emplacement_id    uuid references emplacements(id),    -- optionnel (rangement fin)
  fournisseur_id    uuid references fournisseurs(id),
  unite             text,
  conditionnement   int,
  prix_unitaire_ht  numeric(10,2) default 0,
  stock_courant     int not null default 0,
  seuil_mini        int default 0,
  seuil_rupture     int default 0,
  seuil_cible       int default 0,
  actif             boolean default true,
  cree_le           timestamptz default now(),
  modifie_le        timestamptz default now()
);

create or replace view v_produits_statut as
select p.*,
  case
    when p.stock_courant <= p.seuil_rupture then '🔴 Rupture'
    when p.stock_courant <= p.seuil_mini    then '🟠 Faible'
    else '🟢 OK'
  end as statut,
  (p.stock_courant * p.prix_unitaire_ht) as valeur_stock
from produits p;

create table if not exists missions (
  id            uuid primary key default gen_random_uuid(),
  nom           text not null,
  description   text,
  assignee_id   uuid references operateurs(id),
  statut        text default 'À faire' check (statut in ('À faire','En cours','Terminée','Annulée')),
  type_mouvement text default 'Sortie',
  date_prevue   date,
  creee_par     uuid references operateurs(id),
  cree_le       timestamptz default now()
);

create table if not exists mouvements (
  id            uuid primary key default gen_random_uuid(),
  type          text not null check (type in ('Entrée','Sortie','Correction','Inventaire')),
  produit_id    uuid not null references produits(id),
  quantite      int not null check (quantite > 0),
  stock_avant   int,
  stock_apres   int,
  operateur_id  uuid references operateurs(id),
  emplacement_id uuid references emplacements(id),
  mission_id    uuid references missions(id),
  client_key    text unique,
  source        text default 'Scan',
  commentaire   text,
  cree_le       timestamptz default now()
);

create table if not exists lignes_missions (
  id               uuid primary key default gen_random_uuid(),
  mission_id       uuid not null references missions(id) on delete cascade,
  ordre            int not null,
  produit_id       uuid not null references produits(id),
  quantite_prevue  int not null,
  quantite_servie  int default 0,
  statut           text default 'En attente' check (statut in ('En attente','Servie','Passée'))
);

create table if not exists alertes (
  id                  uuid primary key default gen_random_uuid(),
  produit_id          uuid not null references produits(id),
  type                text check (type in ('Sous seuil','Rupture')),
  stock_declenchement int,
  statut              text default 'Ouverte' check (statut in ('Ouverte','Commandée','Résolue')),
  cree_le             timestamptz default now()
);

create table if not exists inventaires (
  id                uuid primary key default gen_random_uuid(),
  produit_id        uuid not null references produits(id),
  quantite_comptee  int not null,
  stock_theorique   int,
  operateur_id      uuid references operateurs(id),
  ajuste            boolean default false,
  cree_le           timestamptz default now()
);

-- ─────────────── Trigger stock (= A1) ───────────────
create or replace function maj_stock_apres_mouvement()
returns trigger language plpgsql security definer as $$
declare v_stock_avant int; v_delta int;
begin
  select stock_courant into v_stock_avant from produits where id = new.produit_id for update;
  v_delta := case when new.type = 'Entrée' then new.quantite else -new.quantite end;
  update produits set stock_courant = v_stock_avant + v_delta, modifie_le = now()
    where id = new.produit_id;
  new.stock_avant := v_stock_avant;
  new.stock_apres := v_stock_avant + v_delta;
  return new;
end; $$;

drop trigger if exists trg_maj_stock on mouvements;
create trigger trg_maj_stock before insert on mouvements
  for each row execute function maj_stock_apres_mouvement();

-- ─────────────── Alertes (= A2/A3) ───────────────
create or replace function gerer_alertes()
returns trigger language plpgsql security definer as $$
declare v_p produits%rowtype;
begin
  select * into v_p from produits where id = new.produit_id;
  if v_p.stock_courant <= v_p.seuil_mini then
    if not exists (select 1 from alertes where produit_id = v_p.id and statut = 'Ouverte') then
      insert into alertes(produit_id, type, stock_declenchement)
      values (v_p.id,
              case when v_p.stock_courant <= v_p.seuil_rupture then 'Rupture' else 'Sous seuil' end,
              v_p.stock_courant);
    end if;
  else
    update alertes set statut = 'Résolue' where produit_id = v_p.id and statut = 'Ouverte';
  end if;
  return new;
end; $$;

drop trigger if exists trg_alertes on mouvements;
create trigger trg_alertes after insert on mouvements
  for each row execute function gerer_alertes();

-- ─────────────── Login opérateur (PIN) ───────────────
create or replace function login_operateur(p_pin text)
returns table(id uuid, nom text, role text, photo_url text)
language plpgsql security definer as $$
begin
  return query
  select o.id, o.nom, o.role, o.photo_url
  from operateurs o
  where o.actif and o.pin_hash = crypt(p_pin, o.pin_hash);
end; $$;

-- ─────────────── Vues cockpit ───────────────
create or replace view v_conso_mensuelle as
select produit_id, date_trunc('month', cree_le) as mois, sum(quantite) as sorties
from mouvements where type = 'Sortie'
group by produit_id, date_trunc('month', cree_le);

-- ─────────────── RLS ───────────────
alter table sites           enable row level security;
alter table produits        enable row level security;
alter table categories      enable row level security;
alter table emplacements    enable row level security;
alter table mouvements      enable row level security;
alter table missions        enable row level security;
alter table lignes_missions enable row level security;
alter table alertes         enable row level security;
alter table operateurs      enable row level security;  -- aucune policy => bloqué au client

drop policy if exists lecture_sites on sites;
create policy lecture_sites on sites for select to anon using (true);
drop policy if exists lecture_produits on produits;
create policy lecture_produits on produits for select to anon using (true);
drop policy if exists lecture_categories on categories;
create policy lecture_categories on categories for select to anon using (true);
drop policy if exists lecture_emplacements on emplacements;
create policy lecture_emplacements on emplacements for select to anon using (true);
drop policy if exists lecture_missions on missions;
create policy lecture_missions on missions for select to anon using (true);
drop policy if exists lecture_lignes on lignes_missions;
create policy lecture_lignes on lignes_missions for select to anon using (true);
drop policy if exists insert_mouvements on mouvements;
create policy insert_mouvements on mouvements for insert to anon with check (true);
drop policy if exists lecture_mouvements on mouvements;
create policy lecture_mouvements on mouvements for select to anon using (true);
drop policy if exists lecture_alertes on alertes;
create policy lecture_alertes on alertes for select to anon using (true);
drop policy if exists update_lignes on lignes_missions;
create policy update_lignes on lignes_missions for update to anon using (true) with check (true);

-- Responsable authentifié : écriture complète produits
drop policy if exists resp_ecrit_produits on produits;
create policy resp_ecrit_produits on produits for all to authenticated using (true) with check (true);
