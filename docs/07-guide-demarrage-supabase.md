# 7 — Guide de démarrage Supabase (pas-à-pas)

Objectif : en ~30 min, une base qui **gère vraiment le stock**. Quand tu insères une « Sortie », le stock baisse tout seul (trigger SQL) et une alerte se crée sous le seuil.

Tu connais déjà Supabase (UNBRAKE, hiddensunset, SOMIA…), donc ça va vite.

---

## Étape 1 — Créer le projet
1. **app.supabase.com** → **New project** → nom `stock-esat`, région `West EU (Paris)`, mot de passe DB fort (garde-le).
2. Attends ~2 min l'initialisation.

## Étape 2 — Créer tout le schéma d'un coup
1. Menu gauche → **SQL Editor** → **+ New query**.
2. Copie-colle **tout le bloc SQL de `03-supabase.md` §3bis.2** (les `create table …`).
3. **Run**. ✅ Tables créées.

## Étape 3 — Ajouter le trigger « stock » + les alertes
1. Nouvelle query → colle les blocs **§3bis.3** (trigger stock) puis **§3bis.4** (alertes) → **Run**.
2. Colle **§3bis.5** (`login_operateur`) → **Run**.

## Étape 4 — Activer la sécurité (RLS)
1. Nouvelle query → colle **§3bis.6** (toutes les policies) → **Run**.
   → Désormais l'app pourra lire les produits et insérer des mouvements, mais **pas** trafiquer les stocks.

## Étape 5 — Insérer des données de test
Nouvelle query → colle et adapte :
```sql
-- Catégories
insert into categories(nom, ordre) values
('Détergents',1),('Désinfectants',2),('Sacs poubelle',3),('Papier',4),
('Lavettes',5),('Gants',6),('Produits sanitaires',7),('Consommables',8);

-- Emplacements
insert into emplacements(code, libelle, zone) values
('A01','Étagère A bas gauche','A'),
('B15','Étagère B niveau 1','B'),
('C03','Local sanitaire','C');

-- Produits (on relie via sous-requêtes)
insert into produits(ref, nom, categorie_id, emplacement_id, unite, prix_unitaire_ht, stock_courant, seuil_mini, seuil_cible)
values
('DET-SOL-5L','Détergent sol 5L',
   (select id from categories where nom='Détergents'),
   (select id from emplacements where code='A01'),
   'bidon', 8.50, 24, 6, 30),
('GANT-NIT-M','Gants nitrile M',
   (select id from categories where nom='Gants'),
   (select id from emplacements where code='A01'),
   'boîte', 4.20, 12, 4, 20),
('SAC-130L','Sacs poubelle 130L',
   (select id from categories where nom='Sacs poubelle'),
   (select id from emplacements where code='B15'),
   'rouleau', 6.00, 3, 5, 15);

-- Un opérateur (PIN 1234) et un responsable (PIN 4321)
insert into operateurs(nom, pin_hash, role) values
('Karim', crypt('1234', gen_salt('bf')), 'operateur'),
('Marc',  crypt('4321', gen_salt('bf')), 'responsable');
```
Run.

## Étape 6 — LE TEST QUI PROUVE QUE ÇA MARCHE
```sql
-- Simuler une sortie de 3 bidons de détergent
insert into mouvements(type, produit_id, quantite, source)
values ('Sortie',
        (select id from produits where ref='DET-SOL-5L'),
        3, 'Manuel');

-- Vérifier
select nom, stock_courant from produits where ref='DET-SOL-5L';   -- 24 -> 21 ✅
select type, quantite, stock_avant, stock_apres from mouvements;  -- 24 -> 21 ✅
```
Et sur les **Sacs 130L** (stock 3, seuil 5) fais une entrée puis une sortie pour voir l'alerte :
```sql
insert into mouvements(type, produit_id, quantite)
values ('Sortie',(select id from produits where ref='SAC-130L'),1);

select * from alertes;              -- une alerte 'Sous seuil' créée automatiquement ✅
select * from v_produits_statut;    -- statut 🔴/🟠/🟢 calculé ✅
```

🎉 **Tu as un système de gestion de stock fonctionnel et sécurisé**, sans backend. L'app Flutter ne fera qu'insérer ces mouvements via un scan.

## Étape 7 — Tester la connexion opérateur
```sql
select * from login_operateur('1234');   -- renvoie Karim / operateur ✅
select * from login_operateur('0000');   -- renvoie 0 ligne (PIN faux) ✅
```

## Étape 8 — Storage photos (2 min)
1. Menu **Storage** → **New bucket** → nom `produits-photos` → **Public**.
2. Uploade une photo, copie son URL publique, mets-la dans `produits.photo_url` (Table Editor).

## Étape 9 — Récupérer les clés pour Flutter
**Settings → API** :
- `Project URL` et clé **`anon` (public)** → celles-ci vont dans l'app (sûres grâce à la RLS).
- ⚠️ La clé **`service_role`** ne va **JAMAIS** dans l'app (uniquement Edge Functions / serveur).

---

## Ce qu'il te reste ensuite
- Vues cockpit (`v_conso_mensuelle`, top produits, valorisation) — §3bis.8.
- Edge Function `/export` pour l'Excel — §3bis.8.
- Écran admin responsable OU utilisation directe du **Table Editor** Supabase pour gérer produits/photos/seuils.
- Passer au **squelette Flutter** : `supabase_flutter` + `mobile_scanner`, l'app lit les produits et insère les mouvements avec un `client_key` (UUID) pour l'idempotence offline.

## Rappel sécurité
- Clé **anon** dans l'app = OK (bridée par RLS).
- Table `operateurs` = **aucune policy** → invisible au client, on passe par `login_operateur`.
- PIN 4 chiffres = barrière d'usage, pas de sécurité forte : la vraie barrière est la RLS.
