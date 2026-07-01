-- Stock'ESAT — Éditer/supprimer une ligne de stock (par lieu) depuis le web.

create or replace function web_modifier_stock(
  p_stock_id uuid, p_produit_id uuid, p_nom text, p_categorie_id uuid,
  p_unite text, p_seuil_mini int, p_seuil_cible int
) returns void language plpgsql security definer as $$
declare v stocks%rowtype;
begin
  perform set_config('app.acteur', 'Axel', true);
  update produits set nom = coalesce(p_nom, nom), categorie_id = p_categorie_id,
    unite = p_unite, modifie_le = now() where id = p_produit_id;
  update stocks set seuil_mini = coalesce(p_seuil_mini, seuil_mini),
    seuil_cible = coalesce(p_seuil_cible, seuil_cible), modifie_le = now()
    where id = p_stock_id;
  select * into v from stocks where id = p_stock_id;
  if v.stock_courant <= v.seuil_mini then
    if not exists (select 1 from alertes where produit_id = v.produit_id and site_id = v.site_id and statut = 'Ouverte') then
      insert into alertes(produit_id, site_id, type, stock_declenchement)
      values (v.produit_id, v.site_id, case when v.stock_courant <= v.seuil_rupture then 'Rupture' else 'Sous seuil' end, v.stock_courant);
    end if;
  else
    update alertes set statut = 'Résolue' where produit_id = v.produit_id and site_id = v.site_id and statut = 'Ouverte';
  end if;
end; $$;

create or replace function web_supprimer_stock(p_stock_id uuid)
returns void language plpgsql security definer as $$
declare v stocks%rowtype;
begin
  select * into v from stocks where id = p_stock_id;
  delete from alertes where produit_id = v.produit_id and site_id = v.site_id;
  delete from stocks where id = p_stock_id;
end; $$;

revoke all on function web_modifier_stock(uuid,uuid,text,uuid,text,int,int) from public;
revoke all on function web_supprimer_stock(uuid) from public;
grant execute on function web_modifier_stock(uuid,uuid,text,uuid,text,int,int) to service_role;
grant execute on function web_supprimer_stock(uuid) to service_role;
