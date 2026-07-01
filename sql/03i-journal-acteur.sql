-- Stock'ESAT — Ajoute "qui" (acteur) au journal des produits.
-- Chaque fonction d'écriture pose une variable de session app.acteur,
-- lue par le trigger log_produit.

alter table journal_produits add column if not exists acteur text;

-- Trigger enrichi avec l'acteur
create or replace function log_produit()
returns trigger language plpgsql as $$
declare v_act text := nullif(current_setting('app.acteur', true), '');
begin
  if TG_OP = 'INSERT' then
    insert into journal_produits(action, produit_ref, produit_nom, acteur)
    values ('Création', NEW.ref, NEW.nom, v_act);
  elsif TG_OP = 'DELETE' then
    insert into journal_produits(action, produit_ref, produit_nom, acteur)
    values ('Suppression', OLD.ref, OLD.nom, v_act);
  elsif TG_OP = 'UPDATE' then
    if OLD.actif and not NEW.actif then
      insert into journal_produits(action, produit_ref, produit_nom, acteur)
      values ('Archivage', NEW.ref, NEW.nom, v_act);
    elsif (NEW.nom, NEW.seuil_mini, NEW.seuil_cible, NEW.categorie_id,
           NEW.site_id, NEW.unite, NEW.photo_url, NEW.actif)
       is distinct from
          (OLD.nom, OLD.seuil_mini, OLD.seuil_cible, OLD.categorie_id,
           OLD.site_id, OLD.unite, OLD.photo_url, OLD.actif) then
      insert into journal_produits(action, produit_ref, produit_nom, details, acteur)
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
        ), ''), v_act);
    end if;
  end if;
  return null;
end; $$;

-- ── Mobile : RPCs admin (acteur = nom de l'opérateur) ──
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
  return v_produit;
end; $$;
grant execute on function admin_ajouter_produit to anon;

create or replace function admin_modifier_produit(
  p_pin text, p_produit_id uuid, p_nom text,
  p_categorie_id uuid default null, p_site_id uuid default null,
  p_unite text default null, p_seuil_mini int default null,
  p_seuil_cible int default null, p_photo_url text default null
) returns produits language plpgsql security definer as $$
declare v_role text; v_nom text; v produits;
begin
  select role, nom into v_role, v_nom from operateurs
  where actif and pin_hash = crypt(p_pin, pin_hash);
  if v_role is null or v_role <> 'admin' then
    raise exception 'Accès refusé : compte admin requis';
  end if;
  perform set_config('app.acteur', coalesce(v_nom, ''), true);
  update produits set
    nom = coalesce(p_nom, nom), categorie_id = coalesce(p_categorie_id, categorie_id),
    site_id = coalesce(p_site_id, site_id), unite = coalesce(p_unite, unite),
    seuil_mini = coalesce(p_seuil_mini, seuil_mini), seuil_cible = coalesce(p_seuil_cible, seuil_cible),
    photo_url = coalesce(p_photo_url, photo_url), modifie_le = now()
  where id = p_produit_id returning * into v;
  if v.stock_courant <= v.seuil_mini then
    if not exists (select 1 from alertes where produit_id = v.id and statut = 'Ouverte') then
      insert into alertes(produit_id, type, stock_declenchement)
      values (v.id, case when v.stock_courant <= v.seuil_rupture then 'Rupture' else 'Sous seuil' end, v.stock_courant);
    end if;
  else
    update alertes set statut = 'Résolue' where produit_id = v.id and statut = 'Ouverte';
  end if;
  return v;
end; $$;
grant execute on function admin_modifier_produit to anon;

create or replace function admin_supprimer_produit(p_pin text, p_produit_id uuid)
returns text language plpgsql security definer as $$
declare v_role text; v_nom text; v_hist boolean;
begin
  select role, nom into v_role, v_nom from operateurs
  where actif and pin_hash = crypt(p_pin, pin_hash);
  if v_role is null or v_role <> 'admin' then
    raise exception 'Accès refusé : compte admin requis';
  end if;
  perform set_config('app.acteur', coalesce(v_nom, ''), true);
  v_hist := exists(select 1 from mouvements where produit_id = p_produit_id)
         or exists(select 1 from lignes_missions where produit_id = p_produit_id);
  if v_hist then
    update produits set actif = false, modifie_le = now() where id = p_produit_id;
    update alertes set statut = 'Résolue' where produit_id = p_produit_id and statut = 'Ouverte';
    return 'archivé';
  else
    delete from alertes where produit_id = p_produit_id;
    delete from inventaires where produit_id = p_produit_id;
    delete from produits where id = p_produit_id;
    return 'supprimé';
  end if;
end; $$;
grant execute on function admin_supprimer_produit to anon;

-- ── Web : RPCs (acteur = 'Axel') ──
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
  return v;
end; $$;

create or replace function web_modifier_produit(
  p_produit_id uuid, p_nom text, p_categorie_id uuid, p_site_id uuid,
  p_unite text, p_seuil_mini int, p_seuil_cible int, p_photo_url text
) returns produits language plpgsql security definer as $$
declare v produits;
begin
  perform set_config('app.acteur', 'Axel', true);
  update produits set
    nom = coalesce(p_nom, nom), categorie_id = p_categorie_id, site_id = p_site_id,
    unite = p_unite, seuil_mini = coalesce(p_seuil_mini, seuil_mini),
    seuil_cible = coalesce(p_seuil_cible, seuil_cible),
    photo_url = coalesce(p_photo_url, photo_url), modifie_le = now()
  where id = p_produit_id returning * into v;
  if v.stock_courant <= v.seuil_mini then
    if not exists (select 1 from alertes where produit_id = v.id and statut = 'Ouverte') then
      insert into alertes(produit_id, type, stock_declenchement)
      values (v.id, case when v.stock_courant <= v.seuil_rupture then 'Rupture' else 'Sous seuil' end, v.stock_courant);
    end if;
  else
    update alertes set statut = 'Résolue' where produit_id = v.id and statut = 'Ouverte';
  end if;
  return v;
end; $$;

create or replace function web_supprimer_produit(p_produit_id uuid)
returns text language plpgsql security definer as $$
declare v_hist boolean;
begin
  perform set_config('app.acteur', 'Axel', true);
  v_hist := exists(select 1 from mouvements where produit_id = p_produit_id)
         or exists(select 1 from lignes_missions where produit_id = p_produit_id);
  if v_hist then
    update produits set actif = false, modifie_le = now() where id = p_produit_id;
    update alertes set statut = 'Résolue' where produit_id = p_produit_id and statut = 'Ouverte';
    return 'archivé';
  else
    delete from alertes where produit_id = p_produit_id;
    delete from inventaires where produit_id = p_produit_id;
    delete from produits where id = p_produit_id;
    return 'supprimé';
  end if;
end; $$;

revoke all on function web_creer_produit(text,text,uuid,uuid,text,int,int,int,text) from public;
revoke all on function web_modifier_produit(uuid,text,uuid,uuid,text,int,int,text) from public;
revoke all on function web_supprimer_produit(uuid) from public;
grant execute on function web_creer_produit(text,text,uuid,uuid,text,int,int,int,text) to service_role;
grant execute on function web_modifier_produit(uuid,text,uuid,uuid,text,int,int,text) to service_role;
grant execute on function web_supprimer_produit(uuid) to service_role;
