-- Stock'ESAT — Photos produits (Supabase Storage)
-- Bucket public en lecture ; upload autorisé à l'app (anon) ; MAJ de photo_url
-- via une RPC qui ne touche QUE la colonne photo_url (opérateurs).

-- 1) Bucket public
insert into storage.buckets (id, name, public)
values ('produits-photos', 'produits-photos', true)
on conflict (id) do nothing;

-- 2) Policies Storage pour la clé anon (upload + maj + lecture sur CE bucket)
drop policy if exists photos_insert on storage.objects;
create policy photos_insert on storage.objects
  for insert to anon with check (bucket_id = 'produits-photos');

drop policy if exists photos_update on storage.objects;
create policy photos_update on storage.objects
  for update to anon using (bucket_id = 'produits-photos')
  with check (bucket_id = 'produits-photos');

drop policy if exists photos_select on storage.objects;
create policy photos_select on storage.objects
  for select to anon using (bucket_id = 'produits-photos');

-- 3) RPC : définir la photo d'un produit (ne modifie que photo_url)
--    Cohérent avec le modèle : l'app (anon) peut faire des opérations
--    opérationnelles à faible risque, pas des modifications sensibles.
create or replace function definir_photo_produit(p_produit_id uuid, p_photo_url text)
returns void
language plpgsql
security definer
as $$
begin
  update produits
     set photo_url = p_photo_url, modifie_le = now()
   where id = p_produit_id;
end;
$$;

grant execute on function definir_photo_produit to anon;
