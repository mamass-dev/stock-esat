# 2 — Parcours utilisateurs & Maquettes UX (tous les écrans)

Conventions maquettes : `[ ... ]` = bouton géant. Les écrans sont pensés **mobile/tablette portrait**, une action principale par écran.

## 2.1 Carte des écrans

```
Connexion (PIN/Badge)
   └─ Accueil (4 boutons)
        ├─ Entrée de produits ──► Scan ► Fiche ► Quantité ► Récap ► Confirmation ► Accueil
        ├─ Sortie de produits ──► Scan ► Fiche ► Quantité ► Récap ► Confirmation ► Accueil
        │      └─ (variante) Scan Emplacement ► Liste produits de l'emplacement
        ├─ Consulter les stocks ► Liste/Recherche visuelle ► Fiche produit
        ├─ Mode Mission ────────► Étape 1..N guidées ► Fin de mission
        └─ Responsable (PIN+) ──► Cockpit / Alertes / Missions / Export / Étiquettes
```

## 2.2 Écran — Connexion

```
┌─────────────────────────────┐
│         STOCK'ESAT          │
│                             │
│      👋  Bonjour !          │
│   Tapez votre code          │
│                             │
│      ●  ●  ○  ○             │
│                             │
│    [ 1 ] [ 2 ] [ 3 ]        │
│    [ 4 ] [ 5 ] [ 6 ]        │
│    [ 7 ] [ 8 ] [ 9 ]        │
│    [ ⌫ ] [ 0 ] [ ✓ ]        │
│                             │
│   ou  [  📛  BADGE  ]        │
└─────────────────────────────┘
```
- Pavé numérique **géant** (seul « clavier » toléré). Feedback : point qui se remplit + vibration légère.
- Option badge NFC : approcher la carte, halo vert + vibration = connecté.

## 2.3 Écran — Accueil (4 boutons)

```
┌─────────────────────────────┐
│  Bonjour Karim 👋   [ 🔒 ]   │
├──────────────┬──────────────┤
│      📦      │      📤      │
│   ENTRÉE     │   SORTIE     │
├──────────────┼──────────────┤
│      📊      │      ⚙       │
│  CONSULTER   │ RESPONSABLE  │
└──────────────┴──────────────┘
       [ 🎯  MA MISSION ]        (visible si mission assignée)
```
- 4 tuiles carrées, plein écran, forte couleur + picto + un seul mot.
- Bandeau mission apparaît uniquement si le responsable a assigné une mission à l'opérateur.

## 2.4 Parcours SORTIE (cœur du produit, ≤ 7 étapes)

**Étape 1 — Scanner**
```
┌─────────────────────────────┐
│  📤  SORTIE                  │
│                             │
│   ┌───────────────────┐     │
│   │  [ viseur caméra ] │     │
│   │      ▢ ▢ ▢         │     │
│   └───────────────────┘     │
│                             │
│  Visez le QR du produit     │
│  ou de l'emplacement        │
│                             │
│  [ ❓ AIDE ]     [ ⬅ RETOUR ]│
└─────────────────────────────┘
```

**Étape 2 — Reconnaissance + Fiche produit**
```
┌─────────────────────────────┐
│   ┌───────────────────┐     │
│   │   GRANDE PHOTO     │     │
│   │     PRODUIT        │     │
│   └───────────────────┘     │
│   Détergent sol 5L          │
│                             │
│   Stock : 🟢  24            │
│   Emplacement : A01         │
│                             │
│   [ ✓ C'EST CE PRODUIT ]     │
│   [ ↻ SCANNER AUTRE ]        │
└─────────────────────────────┘
```
- Pastille couleur + nombre en très gros. TTS optionnel : lit « Détergent sol 5 litres, stock 24 ».

**Étape 3 — Quantité (+ / −)**
```
┌─────────────────────────────┐
│   Détergent sol 5L          │
│   ┌───────────────────┐     │
│   │      photo         │     │
│   └───────────────────┘     │
│                             │
│   [   –   ]   3   [   +   ]  │
│                (chiffre géant)│
│                             │
│   Il restera : 21 🟢         │
│                             │
│   [ ✓ VALIDER LA SORTIE ]    │
│   [ ⬅ ANNULER ]              │
└─────────────────────────────┘
```
- Boutons − / + immenses. Le « il restera » se recalcule en direct → devient 🟠/🔴 si on descend sous le seuil (retour visuel préventif).
- Aucun clavier : maintien appuyé accélère (avec limite).

**Étape 4 — Récapitulatif (anti-erreur)**
```
┌─────────────────────────────┐
│   Vous allez SORTIR :        │
│   ┌───────┐                  │
│   │ photo │  Détergent 5L    │
│   └───────┘                  │
│        3  bidons             │
│                             │
│   [ ✅  OUI, C'EST BON ]      │
│   [ ✏  MODIFIER ]            │
└─────────────────────────────┘
```

**Étape 5 — Confirmation**
```
┌─────────────────────────────┐
│           ✅                 │
│     C'EST ENREGISTRÉ !       │
│                             │
│   Détergent 5L  −3          │
│   Nouveau stock : 21 🟢      │
│                             │
│   [ ➕ AUTRE PRODUIT ]        │
│   [ 🏠 RETOUR ACCUEIL ]       │
└─────────────────────────────┘
```
- Grand ✅ animé + **vibration de succès** + son court + TTS « C'est enregistré ». Retour auto à l'accueil après 8 s si aucune action.

## 2.5 Parcours ENTRÉE (réception)
Identique à la sortie, sémantique inversée :
Scan → Fiche → `[ − ] N [ + ]` **« Quantité reçue »** → Récap → Confirmation (« +N, nouveau stock »). Option : **photo du produit** demandée si la fiche n'en a pas encore (alimente la photothèque).

## 2.6 Parcours SCAN EMPLACEMENT
```
Scan A01
┌─────────────────────────────┐
│  📍 Emplacement A01          │
├─────────────────────────────┤
│ [photo] Détergent 5L   24 🟢 │
│ [photo] Désinfectant   4  🟠 │
│ [photo] Sacs 130L      0  🔴 │
└─────────────────────────────┘
  Touchez un produit pour Entrée/Sortie
```

## 2.7 Écran — CONSULTER les stocks
```
┌─────────────────────────────┐
│  📊 STOCKS     [ 🔎 ] [🎙]    │
│  Filtres : [Tous][🟠][🔴]     │
├─────────────────────────────┤
│ [photo] Gants nitrile  120🟢 │
│ [photo] Éponges vertes  8 🟠 │
│ [photo] Papier essuie   0 🔴 │
│ [photo] Lavettes bleues 60🟢 │
└─────────────────────────────┘
```
- Recherche visuelle par **catégorie à pictos** (Détergents, Sacs, Papier, Gants…) plutôt que par texte.
- Recherche vocale optionnelle (🎙). Tri par défaut : ruptures et faibles en haut.

## 2.8 MODE MISSION (assistant guidé)
```
┌─────────────────────────────┐
│  🎯 Chariot sanitaire        │
│  Étape 2 / 5                 │
│  ▓▓▓▓░░░░░░  40%             │
├─────────────────────────────┤
│  Allez à l'emplacement       │
│        📍  A01               │
│   ┌───────┐                  │
│   │ photo │ Détergent 5L     │
│   └───────┘                  │
│   Prenez :  2  bidons        │
│                             │
│  [ 📷 SCANNER POUR VALIDER ]  │
│  [ ⏭ PASSER (indispo) ]      │
└─────────────────────────────┘
```
- Le scan de confirmation **garantit** que l'opérateur est au bon endroit / bon produit (sécurité anti-erreur).
- « Passer » consigne une ligne non servie (rupture/introuvable) → visible côté responsable.
- Fin : écran « 🎉 Mission terminée ! » + récap + vibration.

## 2.9 Écran — RESPONSABLE (après PIN renforcé)
```
┌─────────────────────────────┐
│  ⚙ ESPACE RESPONSABLE        │
├──────────────┬──────────────┤
│ 📊 COCKPIT   │ 🚨 À COMMANDER│
├──────────────┼──────────────┤
│ 🎯 MISSIONS  │ 🧾 EXPORT     │
├──────────────┼──────────────┤
│ 🏷 ÉTIQUETTES│ 🧮 INVENTAIRE │
└──────────────┴──────────────┘
```

### Cockpit
```
┌─────────────────────────────┐
│  Références : 412            │
│  Valeur stock : 8 340 €      │
│  🔴 Ruptures : 5             │
│  🟠 Sous seuil : 18          │
│  ── Conso du mois ──         │
│  ▁▂▄▆█▅▃  (graphe)          │
│  Top produits :             │
│  1. Gants nitrile           │
│  2. Sacs 130L               │
│  Derniers mouvements ▸       │
└─────────────────────────────┘
```

### À commander / Alertes
Liste des produits `Stock ≤ Seuil`, quantité suggérée (= Seuil cible − Stock), fournisseur, bouton **Exporter la commande (Excel)**.

### Étiquettes
Sélection produits → génération PDF planche d'étiquettes (QR + photo + nom + réf + emplacement) prête à imprimer.

## 2.10 États systèmes à ne pas oublier (retour visuel permanent)
- **Chargement** : squelette + « ⏳ Un instant… », jamais d'écran blanc.
- **Hors ligne** : bandeau discret « 📶 Hors ligne — tout est sauvegardé, ça partira tout seul ✅ » (rassurant, non bloquant).
- **Produit inconnu au scan** : « ❓ Je ne connais pas ce code » + [ Réessayer ] [ Appeler le moniteur ].
- **Erreur réseau à la validation** : le mouvement est **quand même mis en file** → afficher succès « en attente d'envoi », jamais un échec anxiogène.
