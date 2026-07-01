-- Stock'ESAT — Données de test (idempotent)

-- Sites (multi-sites)
insert into sites(nom, ville) values
('Quetigny','Quetigny'),
('Chenôve','Chenôve'),
('Ahuy','Ahuy')
on conflict do nothing;

-- Catégories (familles génériques)
insert into categories(nom, ordre) values
('Produits d''entretien',1),('Consommables',2),('Protection / EPI',3),('Matériel',4)
on conflict do nothing;

-- Produits rattachés au site Quetigny (exemple)
insert into produits(ref, nom, categorie_id, site_id, unite, prix_unitaire_ht, stock_courant, seuil_mini, seuil_cible)
values
('DET-SOL-5L','Détergent sol 5L',
   (select id from categories where nom='Produits d''entretien'),
   (select id from sites where nom='Quetigny'),
   'bidon', 8.50, 24, 6, 30),
('GANT-NIT-M','Gants nitrile M',
   (select id from categories where nom='Protection / EPI'),
   (select id from sites where nom='Quetigny'),
   'boîte', 4.20, 12, 4, 20),
('SAC-130L','Sacs poubelle 130L',
   (select id from categories where nom='Consommables'),
   (select id from sites where nom='Quetigny'),
   'rouleau', 6.00, 3, 5, 15)
on conflict (ref) do nothing;

-- Opérateur (PIN 1234) + Responsable (PIN 4321)
insert into operateurs(nom, pin_hash, role) values
('Karim', crypt('1234', gen_salt('bf')), 'operateur'),
('Marc',  crypt('4321', gen_salt('bf')), 'responsable')
on conflict do nothing;
