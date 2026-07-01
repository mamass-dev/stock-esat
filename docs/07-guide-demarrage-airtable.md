# 7 — Guide de démarrage Airtable (pas-à-pas, sans code)

Objectif : en ~1 h, avoir une base qui **gère vraiment le stock** avec 3 tables + 1 automatisation.
À la fin, quand tu ajoutes une ligne « Sortie », le stock du produit **baisse tout seul**.

---

## Étape 0 — Créer la base
1. Va sur **airtable.com**, crée un compte (le plan gratuit suffit pour tester ; passe en **Team** plus tard pour les automatisations avancées).
2. Clique **« Create a base »** → **« Start from scratch »**.
3. Renomme la base : double-clic sur son nom → `Stock'ESAT`.

Airtable crée une table `Table 1` par défaut. On va la transformer en `Catégories`.

---

## Étape 1 — Table `Catégories`
1. Double-clic sur l'onglet `Table 1` → renomme en **`Catégories`**.
2. Supprime les colonnes inutiles (Notes, Assignee, Status) : clic sur le ▾ de l'en-tête → **Delete field**.
3. Renomme la 1re colonne `Name` → **`Nom`** (type *Single line text*, garde-le).
4. Ajoute une colonne (bouton **+** à droite) : **`Ordre`** → type **Number**.
5. Saisis ces lignes (une par catégorie) :

```
Nom                | Ordre
Détergents         | 1
Désinfectants      | 2
Sacs poubelle      | 3
Papier             | 4
Lavettes           | 5
Microfibres        | 6
Éponges            | 7
Gants              | 8
Produits sanitaires| 9
Consommables       | 10
Petit matériel     | 11
```

---

## Étape 2 — Table `Emplacements`
1. En bas, à côté des onglets, clique **+ Add or import** → **Create empty table** → nomme-la **`Emplacements`**.
2. Colonnes :
   - `Code` (Single line text) — la colonne principale
   - `Libellé` (Single line text)
   - `Zone` (Single select : A, B, C…)
3. Saisis quelques emplacements :

```
Code | Libellé                 | Zone
A01  | Étagère A – bas gauche   | A
A02  | Étagère A – bas droite   | A
B15  | Étagère B – niveau 1     | B
C03  | Local sanitaire          | C
```

---

## Étape 3 — Table `Produits` (la plus importante)
1. **+ Add or import** → **Create empty table** → **`Produits`**.
2. Crée les colonnes suivantes (bouton **+**, choisis bien le **type**) :

| Colonne | Type Airtable | Réglage |
|---|---|---|
| `Nom` | Single line text | colonne principale |
| `Réf` | Single line text | ex. `DET-SOL-5L` |
| `Photo` | **Attachment** | on y mettra la photo |
| `Catégorie` | **Link to another record** → `Catégories` | 1 seule |
| `Emplacement` | **Link to another record** → `Emplacements` | 1 seule |
| `Unité` | Single select | bidon, sac, carton, boîte, pièce, rouleau |
| `Prix unitaire HT` | **Currency** (€) | pour la valeur |
| `Stock courant` | **Number** (entier) | **ne pas remplir à la main plus tard** |
| `Seuil mini` | Number | déclenche le 🟠 |
| `Seuil cible` | Number | stock à reconstituer |

3. **Colonne « Statut » automatique** — bouton **+** → type **Formula** → nomme **`Statut`** → colle :
```
IF({Stock courant} <= 0, "🔴 Rupture",
  IF({Stock courant} <= {Seuil mini}, "🟠 Faible", "🟢 OK"))
```
4. **Colonne « Valeur stock »** — type **Formula** → nomme **`Valeur stock`** → colle :
```
{Stock courant} * {Prix unitaire HT}
```
5. Saisis **10 produits réels** pour tester (mets un `Stock courant` de départ, ex. 20). Relie chaque produit à sa `Catégorie` et son `Emplacement` (clic dans la cellule → choisir).

Exemple de ligne :
```
Nom: Détergent sol 5L | Réf: DET-SOL-5L | Catégorie: Détergents |
Emplacement: A01 | Unité: bidon | Prix: 8,50 € | Stock courant: 24 |
Seuil mini: 6 | Seuil cible: 30
```
→ La colonne `Statut` doit afficher **🟢 OK** toute seule. 🎉

---

## Étape 4 — Table `Mouvements` (le journal)
1. **+ Add or import** → **`Mouvements`**.
2. Colonnes :

| Colonne | Type | Réglage |
|---|---|---|
| `Type` | Single select | valeurs : **Entrée**, **Sortie**, **Correction** |
| `Produit` | **Link to another record** → `Produits` | |
| `Quantité` | Number | toujours positive |
| `Stock avant` | Number | *(rempli par l'automatisation)* |
| `Stock après` | Number | *(rempli par l'automatisation)* |
| `Date/Heure` | **Created time** | automatique |

> La colonne principale peut rester `Name` (Airtable exige une 1re colonne) ; laisse-la vide, ou renomme-la `Note`.

---

## Étape 5 — L'AUTOMATISATION A1 (le cœur : le stock bouge tout seul)

C'est l'étape magique. On va dire à Airtable :
« Quand on crée un mouvement, mets à jour le stock du produit. »

1. En haut à droite, clique **Automations**.
2. **+ Create automation** → nomme-la **`A1 - Maj stock`**.
3. **Trigger (déclencheur)** : *When a record is created* → Table : **Mouvements**.
   - Clique **Test trigger** (crée d'abord une ligne test dans Mouvements : Type=Sortie, Produit=un produit, Quantité=2).
4. **+ Add action** → *Run a script* (Airtable Scripting). Colle ce script :

```javascript
// A1 - Met à jour le stock du produit à partir d'un mouvement
let inputConfig = input.config();
let mouvementsTable = base.getTable("Mouvements");
let produitsTable = base.getTable("Produits");

// récupère le mouvement qui vient d'être créé
let recordId = inputConfig.recordId;
let mvt = await mouvementsTable.selectRecordAsync(recordId);

let type = mvt.getCellValueAsString("Type");
let qte = mvt.getCellValue("Quantité") || 0;
let produitLien = mvt.getCellValue("Produit");

if (produitLien && produitLien.length > 0) {
    let produitId = produitLien[0].id;
    let produit = await produitsTable.selectRecordAsync(produitId);
    let stockAvant = produit.getCellValue("Stock courant") || 0;

    // signe selon le type
    let delta = (type === "Entrée") ? qte : -qte;
    let stockApres = stockAvant + delta;

    // met à jour le produit
    await produitsTable.updateRecordAsync(produitId, {
        "Stock courant": stockApres
    });
    // écrit les snapshots dans le mouvement
    await mouvementsTable.updateRecordAsync(recordId, {
        "Stock avant": stockAvant,
        "Stock après": stockApres
    });
}
```

5. **Configurer l'input du script** : dans le panneau du script, section **Input variables** → ajoute une variable **`recordId`** = *Record (from trigger) → Airtable record ID*.
6. Clique **Test** → vérifie que le stock du produit a bien bougé.
7. **Active** l'automatisation (toggle en haut à droite : **On**).

### ✅ Test final
- Va dans `Mouvements`, ajoute une ligne : Type=**Sortie**, Produit=**Détergent sol 5L**, Quantité=**3**.
- Regarde la table `Produits` : `Stock courant` est passé de 24 à **21**, `Statut` toujours 🟢.
- Dans `Mouvements`, `Stock avant`=24 et `Stock après`=21 se sont remplis seuls.

**Tu as un système de gestion de stock fonctionnel.** L'app Flutter ne fera qu'ajouter ces lignes de mouvement automatiquement via un scan.

---

## Étape 6 — Vue « Stock temps réel » (bonus, 2 min)
1. Table `Produits` → en haut à gauche des vues → **+ → Grid view** → nomme **`Stock temps réel`**.
2. Clique **Sort** → trier par `Statut` (les 🔴 et 🟠 remontent).
3. (Optionnel) **Group** par `Emplacement` dans une autre vue → tu retrouves « scanner un emplacement = voir ses produits ».

---

## Ce qu'il te reste après ça
- Ajouter progressivement les autres tables (`Opérateurs`, `Alertes`, `Missions`…) — voir `03-airtable.md`.
- Automatisation **A2** (créer une alerte sous le seuil) sur le même principe.
- Générer un **token API** (Airtable → *Developer hub → Personal access tokens*) — il servira **au proxy backend**, pas à l'app directement.

> ⚠️ Ne mets **jamais** ce token dans l'app Flutter. Il vivra uniquement côté serveur (proxy). Pour l'instant, tu n'en as pas besoin : tu testes tout dans Airtable.
