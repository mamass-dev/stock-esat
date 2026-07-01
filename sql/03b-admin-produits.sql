-- Stock'ESAT — Ajout de produits réservé aux comptes ADMIN
-- La barrière est côté base : la fonction vérifie le PIN + le rôle 'admin'.

create or replace function admin_ajouter_produit(
  p_pin           text,
  p_ref           text,
  p_nom           text,
  p_categorie_id  uuid    default null,
  p_site_id       uuid    default null,
  p_unite         text    default null,
  p_prix          numeric default 0,
  p_stock_initial int     default 0,
  p_seuil_mini    int     default 0,
  p_seuil_cible   int     default 0,
  p_photo_url     text    default null
)
returns produits
language plpgsql
security definer
as $$
declare
  v_role    text;
  v_produit produits;
begin
  -- 1) Vérifier que le PIN correspond à un compte admin ACTIF
  select role into v_role
  from operateurs
  where actif and pin_hash = crypt(p_pin, pin_hash);

  if v_role is null or v_role <> 'admin' then
    raise exception 'Accès refusé : compte admin requis';
  end if;

  -- 2) Empêcher un doublon de référence
  if exists (select 1 from produits where ref = p_ref) then
    raise exception 'Cette référence existe déjà : %', p_ref;
  end if;

  -- 3) Insérer le produit (stock initial posé directement)
  insert into produits(ref, nom, categorie_id, site_id, unite,
                       prix_unitaire_ht, stock_courant, seuil_mini, seuil_cible, photo_url)
  values (p_ref, p_nom, p_categorie_id, p_site_id, p_unite,
          p_prix, p_stock_initial, p_seuil_mini, p_seuil_cible, p_photo_url)
  returning * into v_produit;

  return v_produit;
end;
$$;

-- Autoriser l'app (clé anon) à APPELER les fonctions (la sécurité est dans la fonction).
grant execute on function admin_ajouter_produit to anon;
grant execute on function login_operateur to anon;

-- Créer un compte ADMIN de test (PIN 9999) — à personnaliser
insert into operateurs(nom, pin_hash, role)
values ('Admin', crypt('9999', gen_salt('bf')), 'admin')
on conflict do nothing;
