-- Stock'ESAT — Modification de produit réservée ADMIN (mobile + web)
-- Vérifie PIN + rôle admin. Ne touche pas au stock (piloté par les mouvements)
-- ni à la référence (stable pour les QR déjà imprimés). Ré-évalue les alertes.

create or replace function admin_modifier_produit(
  p_pin          text,
  p_produit_id   uuid,
  p_nom          text,
  p_categorie_id uuid default null,
  p_site_id      uuid default null,
  p_unite        text default null,
  p_seuil_mini   int  default null,
  p_seuil_cible  int  default null,
  p_photo_url    text default null
)
returns produits
language plpgsql
security definer
as $$
declare
  v_role text;
  v_p    produits;
begin
  select role into v_role
  from operateurs
  where actif and pin_hash = crypt(p_pin, pin_hash);

  if v_role is null or v_role <> 'admin' then
    raise exception 'Accès refusé : compte admin requis';
  end if;

  update produits set
    nom          = coalesce(p_nom, nom),
    categorie_id = coalesce(p_categorie_id, categorie_id),
    site_id      = coalesce(p_site_id, site_id),
    unite        = coalesce(p_unite, unite),
    seuil_mini   = coalesce(p_seuil_mini, seuil_mini),
    seuil_cible  = coalesce(p_seuil_cible, seuil_cible),
    photo_url    = coalesce(p_photo_url, photo_url),
    modifie_le   = now()
  where id = p_produit_id
  returning * into v_p;

  -- Ré-évaluation des alertes (le seuil a pu changer)
  if v_p.stock_courant <= v_p.seuil_mini then
    if not exists (select 1 from alertes where produit_id = v_p.id and statut = 'Ouverte') then
      insert into alertes(produit_id, type, stock_declenchement)
      values (v_p.id,
              case when v_p.stock_courant <= v_p.seuil_rupture then 'Rupture' else 'Sous seuil' end,
              v_p.stock_courant);
    end if;
  else
    update alertes set statut = 'Résolue'
    where produit_id = v_p.id and statut = 'Ouverte';
  end if;

  return v_p;
end;
$$;

grant execute on function admin_modifier_produit to anon;
