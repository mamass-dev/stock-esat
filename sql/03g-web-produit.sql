-- Stock'ESAT — Supprimer/modifier un produit depuis le web SANS PIN
-- (autorisé par la session du dashboard, via service_role côté serveur).
-- Fonctions réservées à service_role.

create or replace function web_supprimer_produit(p_produit_id uuid)
returns text language plpgsql security definer as $$
declare v_hist boolean;
begin
  v_hist := exists(select 1 from mouvements where produit_id = p_produit_id)
         or exists(select 1 from lignes_missions where produit_id = p_produit_id);
  if v_hist then
    update produits set actif = false, modifie_le = now() where id = p_produit_id;
    update alertes set statut = 'Résolue'
      where produit_id = p_produit_id and statut = 'Ouverte';
    return 'archivé';
  else
    delete from alertes where produit_id = p_produit_id;
    delete from inventaires where produit_id = p_produit_id;
    delete from produits where id = p_produit_id;
    return 'supprimé';
  end if;
end; $$;

create or replace function web_modifier_produit(
  p_produit_id   uuid,
  p_nom          text,
  p_categorie_id uuid,
  p_site_id      uuid,
  p_unite        text,
  p_seuil_mini   int,
  p_seuil_cible  int,
  p_photo_url    text
)
returns produits language plpgsql security definer as $$
declare v produits;
begin
  update produits set
    nom          = coalesce(p_nom, nom),
    categorie_id = p_categorie_id,
    site_id      = p_site_id,
    unite        = p_unite,
    seuil_mini   = coalesce(p_seuil_mini, seuil_mini),
    seuil_cible  = coalesce(p_seuil_cible, seuil_cible),
    photo_url    = coalesce(p_photo_url, photo_url),  -- null = garder la photo
    modifie_le   = now()
  where id = p_produit_id
  returning * into v;

  if v.stock_courant <= v.seuil_mini then
    if not exists (select 1 from alertes where produit_id = v.id and statut = 'Ouverte') then
      insert into alertes(produit_id, type, stock_declenchement)
      values (v.id,
              case when v.stock_courant <= v.seuil_rupture then 'Rupture' else 'Sous seuil' end,
              v.stock_courant);
    end if;
  else
    update alertes set statut = 'Résolue' where produit_id = v.id and statut = 'Ouverte';
  end if;
  return v;
end; $$;

revoke all on function web_supprimer_produit(uuid) from public;
revoke all on function web_modifier_produit(uuid, text, uuid, uuid, text, int, int, text) from public;
grant execute on function web_supprimer_produit(uuid) to service_role;
grant execute on function web_modifier_produit(uuid, text, uuid, uuid, text, int, int, text) to service_role;
