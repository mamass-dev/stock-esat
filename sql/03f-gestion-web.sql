-- Stock'ESAT — Gestion des opérateurs depuis le web (via service_role côté serveur)
-- Le PIN est hashé côté base (bcrypt). Fonctions NON exposées à anon.

create or replace function creer_operateur(p_nom text, p_pin text, p_role text)
returns operateurs
language plpgsql
security definer
as $$
declare v operateurs;
begin
  insert into operateurs(nom, pin_hash, role)
  values (p_nom, crypt(p_pin, gen_salt('bf')), coalesce(p_role, 'operateur'))
  returning * into v;
  return v;
end;
$$;

create or replace function modifier_operateur(
  p_id uuid,
  p_nom text,
  p_role text,
  p_actif boolean,
  p_pin text default null   -- null = ne pas changer le PIN
)
returns operateurs
language plpgsql
security definer
as $$
declare v operateurs;
begin
  update operateurs set
    nom      = coalesce(p_nom, nom),
    role     = coalesce(p_role, role),
    actif    = coalesce(p_actif, actif),
    pin_hash = case when p_pin is null or p_pin = ''
                    then pin_hash
                    else crypt(p_pin, gen_salt('bf')) end
  where id = p_id
  returning * into v;
  return v;
end;
$$;

-- Sécurité : réservées au serveur (service_role). Jamais anon.
revoke all on function creer_operateur(text, text, text) from public;
revoke all on function modifier_operateur(uuid, text, text, boolean, text) from public;
grant execute on function creer_operateur(text, text, text) to service_role;
grant execute on function modifier_operateur(uuid, text, text, boolean, text) to service_role;
