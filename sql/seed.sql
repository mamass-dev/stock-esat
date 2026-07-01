-- Stock'ESAT — Données de test (idempotent)

-- Sites (multi-sites)
insert into sites(nom, ville) values
('Quetigny','Quetigny'),
('Chenôve','Chenôve'),
('Ahuy','Ahuy')
on conflict do nothing;

-- Catégories
insert into categories(nom, ordre) values
('Détergents',1),('Désinfectants',2),('Sacs poubelle',3),('Papier',4),
('Lavettes',5),('Gants',6),('Produits sanitaires',7),('Consommables',8)
on conflict do nothing;

-- Produits rattachés au site Quetigny (exemple)
insert into produits(ref, nom, categorie_id, site_id, unite, prix_unitaire_ht, stock_courant, seuil_mini, seuil_cible)
values
('DET-SOL-5L','Détergent sol 5L',
   (select id from categories where nom='Détergents'),
   (select id from sites where nom='Quetigny'),
   'bidon', 8.50, 24, 6, 30),
('GANT-NIT-M','Gants nitrile M',
   (select id from categories where nom='Gants'),
   (select id from sites where nom='Quetigny'),
   'boîte', 4.20, 12, 4, 20),
('SAC-130L','Sacs poubelle 130L',
   (select id from categories where nom='Sacs poubelle'),
   (select id from sites where nom='Quetigny'),
   'rouleau', 6.00, 3, 5, 15)
on conflict (ref) do nothing;

-- Opérateur (PIN 1234) + Responsable (PIN 4321)
insert into operateurs(nom, pin_hash, role) values
('Karim', crypt('1234', gen_salt('bf')), 'operateur'),
('Marc',  crypt('4321', gen_salt('bf')), 'responsable')
on conflict do nothing;
