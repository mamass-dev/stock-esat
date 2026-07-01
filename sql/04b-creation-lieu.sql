-- Stock'ESAT — Création de produit crée aussi la ligne de stock au lieu choisi.

create or replace function admin_ajouter_produit(
  p_pin text, p_ref text, p_nom text,
  p_categorie_id uuid default null, p_site_id uuid default null,
  p_unite text default null, p_prix numeric default 0,
  p_stock_initial int default 0, p_seuil_mini int default 0,
  p_seuil_cible int default 0, p_photo_url text default null
) returns produits language plpgsql security definer as $$
declare v_role text; v_nom text; v_produit produits;
begin
  select role, nom into v_role, v_nom from operateurs
  where actif and pin_hash = crypt(p_pin, pin_hash);
  if v_role is null or v_role <> 'admin' then
    raise exception 'Accès refusé : compte admin requis';
  end if;
  perform set_config('app.acteur', coalesce(v_nom, ''), true);
  if exists (select 1 from produits where ref = p_ref) then
    raise exception 'Cette référence existe déjà : %', p_ref;
  end if;
  insert into produits(ref, nom, categorie_id, site_id, unite, prix_unitaire_ht,
                       stock_courant, seuil_mini, seuil_cible, photo_url)
  values (p_ref, p_nom, p_categorie_id, p_site_id, p_unite, p_prix,
          p_stock_initial, p_seuil_mini, p_seuil_cible, p_photo_url)
  returning * into v_produit;
  if p_site_id is not null then
    insert into stocks(produit_id, site_id, stock_courant, seuil_mini, seuil_cible)
    values (v_produit.id, p_site_id, coalesce(p_stock_initial, 0),
            coalesce(p_seuil_mini, 0), coalesce(p_seuil_cible, 0))
    on conflict (produit_id, site_id) do update set
      stock_courant = excluded.stock_courant,
      seuil_mini = excluded.seuil_mini,
      seuil_cible = excluded.seuil_cible;
  end if;
  return v_produit;
end; $$;
grant execute on function admin_ajouter_produit to anon;

create or replace function web_creer_produit(
  p_ref text, p_nom text, p_categorie_id uuid, p_site_id uuid,
  p_unite text, p_stock int, p_seuil_mini int, p_seuil_cible int, p_photo_url text
) returns produits language plpgsql security definer as $$
declare v produits;
begin
  perform set_config('app.acteur', 'Axel', true);
  if exists (select 1 from produits where ref = p_ref) then
    raise exception 'La référence % existe déjà', p_ref;
  end if;
  insert into produits(ref, nom, categorie_id, site_id, unite,
                       stock_courant, seuil_mini, seuil_cible, photo_url)
  values (p_ref, p_nom, p_categorie_id, p_site_id, p_unite,
          coalesce(p_stock, 0), coalesce(p_seuil_mini, 0), coalesce(p_seuil_cible, 0), p_photo_url)
  returning * into v;
  if p_site_id is not null then
    insert into stocks(produit_id, site_id, stock_courant, seuil_mini, seuil_cible)
    values (v.id, p_site_id, coalesce(p_stock, 0),
            coalesce(p_seuil_mini, 0), coalesce(p_seuil_cible, 0))
    on conflict (produit_id, site_id) do update set
      stock_courant = excluded.stock_courant,
      seuil_mini = excluded.seuil_mini,
      seuil_cible = excluded.seuil_cible;
  end if;
  return v;
end; $$;
revoke all on function web_creer_produit(text,text,uuid,uuid,text,int,int,int,text) from public;
grant execute on function web_creer_produit(text,text,uuid,uuid,text,int,int,int,text) to service_role;
