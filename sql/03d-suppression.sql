-- Stock'ESAT — Suppression de produit réservée ADMIN (mobile + web)
-- Vérifie le PIN + rôle 'admin'. Suppression réelle si aucun historique,
-- sinon archivage (actif = false) pour préserver la traçabilité.

create or replace function admin_supprimer_produit(p_pin text, p_produit_id uuid)
returns text
language plpgsql
security definer
as $$
declare
  v_role text;
  v_hist boolean;
begin
  select role into v_role
  from operateurs
  where actif and pin_hash = crypt(p_pin, pin_hash);

  if v_role is null or v_role <> 'admin' then
    raise exception 'Accès refusé : compte admin requis';
  end if;

  v_hist := exists(select 1 from mouvements where produit_id = p_produit_id)
         or exists(select 1 from lignes_missions where produit_id = p_produit_id);

  if v_hist then
    -- Archivage (historique préservé)
    update produits set actif = false, modifie_le = now()
      where id = p_produit_id;
    update alertes set statut = 'Résolue'
      where produit_id = p_produit_id and statut = 'Ouverte';
    return 'archivé';
  else
    -- Suppression réelle (aucun historique)
    delete from alertes where produit_id = p_produit_id;
    delete from inventaires where produit_id = p_produit_id;
    delete from produits where id = p_produit_id;
    return 'supprimé';
  end if;
end;
$$;

grant execute on function admin_supprimer_produit to anon;
