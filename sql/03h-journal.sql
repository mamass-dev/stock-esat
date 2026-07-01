-- Stock'ESAT — Journal des actions sur les produits (création/modif/suppression)
-- Horodaté automatiquement. Ignore les changements de stock (= mouvements).

create table if not exists journal_produits (
  id          uuid primary key default gen_random_uuid(),
  action      text not null,           -- Création | Modification | Archivage | Suppression
  produit_ref text,
  produit_nom text,
  details     text,
  cree_le     timestamptz default now()
);

alter table journal_produits enable row level security;  -- lecture serveur uniquement

create or replace function log_produit()
returns trigger language plpgsql as $$
begin
  if TG_OP = 'INSERT' then
    insert into journal_produits(action, produit_ref, produit_nom)
    values ('Création', NEW.ref, NEW.nom);

  elsif TG_OP = 'DELETE' then
    insert into journal_produits(action, produit_ref, produit_nom)
    values ('Suppression', OLD.ref, OLD.nom);

  elsif TG_OP = 'UPDATE' then
    if OLD.actif and not NEW.actif then
      insert into journal_produits(action, produit_ref, produit_nom)
      values ('Archivage', NEW.ref, NEW.nom);

    elsif (NEW.nom, NEW.seuil_mini, NEW.seuil_cible, NEW.categorie_id,
           NEW.site_id, NEW.unite, NEW.photo_url, NEW.actif)
       is distinct from
          (OLD.nom, OLD.seuil_mini, OLD.seuil_cible, OLD.categorie_id,
           OLD.site_id, OLD.unite, OLD.photo_url, OLD.actif) then
      insert into journal_produits(action, produit_ref, produit_nom, details)
      values ('Modification', NEW.ref, NEW.nom,
        nullif(concat_ws(', ',
          case when NEW.nom is distinct from OLD.nom then 'nom' end,
          case when NEW.seuil_mini is distinct from OLD.seuil_mini then 'seuil mini' end,
          case when NEW.seuil_cible is distinct from OLD.seuil_cible then 'seuil cible' end,
          case when NEW.categorie_id is distinct from OLD.categorie_id then 'catégorie' end,
          case when NEW.site_id is distinct from OLD.site_id then 'site' end,
          case when NEW.unite is distinct from OLD.unite then 'unité' end,
          case when NEW.photo_url is distinct from OLD.photo_url then 'photo' end,
          case when NEW.actif and not OLD.actif then 'réactivation' end
        ), ''));
    end if;
    -- sinon : seul le stock a changé (mouvement) -> pas de log
  end if;
  return null;
end; $$;

drop trigger if exists trg_log_produit on produits;
create trigger trg_log_produit
  after insert or update or delete on produits
  for each row execute function log_produit();
