# 3 — Structure Airtable détaillée

> **Règle d'or :** le **stock courant est calculé/maintenu par Airtable**, pas par l'app. L'app envoie un **Mouvement** ; une automation met à jour le stock. Une seule vérité, aucune désynchro.

Base : `Stock'ESAT` — 11 tables.

## 3.1 Diagramme des relations

```
                         ┌──────────────┐
                         │ Catégories   │
                         └──────┬───────┘
                                │ 1─N
                    ┌───────────▼────────────┐        ┌──────────────┐
        N─1         │        PRODUITS         │  N─1   │ Fournisseurs │
   ┌────────────────┤ (fiche + stock courant) ├───────►│              │
   │                └───┬─────────┬──────┬────┘        └──────────────┘
   │ 1─N                │1─N      │1─N   │1─N
┌──▼─────────┐   ┌──────▼───┐ ┌───▼────┐ │
│ Emplacements│  │Mouvements│ │Alertes │ │
└─────────────┘   └────┬─────┘ └────────┘ │
                       │N─1               │1─N
                  ┌────▼─────┐        ┌────▼──────────┐
                  │Opérateurs│        │ Lignes mission│
                  └────┬─────┘        └───────┬───────┘
                       │                       │N─1
                       │                  ┌────▼────┐
                       └──────────────────┤ Missions│
                                          └─────────┘
   ┌────────────┐
   │ Inventaires│──N─1──► Produits   (comptages physiques)
   └────────────┘

   « Stocks » = vue/rollup dérivé de Produits (voir 3.4), pas une table de saisie.
```

Conventions : chaque table a un champ technique `Créé le` (Created time), `Modifié le` (Last modified time), et un identifiant lisible (`ID auto` ou formule).

---

## 3.2 Table `Produits`
Fiche de référence + **stock courant maintenu par automation**.

| Champ | Type | Notes / relation |
|-------|------|------------------|
| `Réf` | Single line text (unique) | Référence interne (ex. `DET-SOL-5L`) — sert de payload QR |
| `Nom` | Single line text | Libellé court FALC (ex. « Détergent sol 5L ») |
| `Photo` | Attachment | **Grande photo** affichée dans l'app |
| `Catégorie` | Link → `Catégories` | 1 catégorie |
| `Emplacement` | Link → `Emplacements` | Emplacement principal |
| `Fournisseur` | Link → `Fournisseurs` | Fournisseur par défaut |
| `Unité` | Single select | bidon, sac, carton, boîte, pièce, rouleau… |
| `Conditionnement` | Number | Qté par unité d'achat (info commande) |
| `Prix unitaire HT` | Currency | Pour valorisation |
| `Stock courant` | Number | **Écrit par automation** (jamais à la main dans l'app) |
| `Seuil mini` | Number | Déclenche alerte 🟠 |
| `Seuil rupture` | Number | Défaut 0 → 🔴 |
| `Seuil cible` | Number | Stock à reconstituer (calcul qté à commander) |
| `Statut stock` | Formula | 🟢🟠🔴 (voir formule ci-dessous) |
| `Valeur stock` | Formula | `{Stock courant} * {Prix unitaire HT}` |
| `Actif` | Checkbox | Masquer produits obsolètes |
| `Réserve` | Single select / Link | Pré-câblage multi-réserves (défaut : `Réserve principale`) |
| `Mouvements` | Link → `Mouvements` | Rollup possible : conso 30j |
| `Conso 30j` | Rollup (Mouvements) | Somme sorties sur 30 jours |
| `QR payload` | Formula | `"P:" & {Réf}` — contenu encodé dans le QR |

**Formule `Statut stock` :**
```
IF({Stock courant} <= {Seuil rupture}, "🔴 Rupture",
  IF({Stock courant} <= {Seuil mini}, "🟠 Faible", "🟢 OK"))
```

## 3.3 Table `Catégories`
| Champ | Type | Notes |
|-------|------|-------|
| `Nom` | Single line text | Détergents, Désinfectants, Sacs poubelle, Papier, Lavettes, Microfibres, Éponges, Gants, Sanitaires, Consommables, Petit matériel |
| `Picto` | Single select / Attachment | Icône affichée dans l'app |
| `Couleur` | Single select | Couleur de la catégorie (UI) |
| `Ordre` | Number | Ordre d'affichage |
| `Produits` | Link → `Produits` | 1─N |

## 3.4 « Stocks » — vue dérivée (pas une table de saisie)
Le besoin « connaître les stocks disponibles » est couvert par **Produits** + une **vue** filtrée/triée. On **ne stocke pas** une valeur redondante ailleurs (source d'incohérence).
- Vue `Stock temps réel` : trié par `Statut stock` (rouges/oranges en haut).
- Vue `Par emplacement` : groupé par `Emplacement`.
- L'app lit ces vues via l'API (`?view=...`).

> Si l'on veut vraiment une table `Stocks` (multi-réserves un même produit stocké à plusieurs endroits), on la crée en V2 : `Stock` = (Produit × Réserve × Emplacement → Quantité). Au MVP mono-réserve, `Stock courant` sur Produits suffit.

## 3.5 Table `Emplacements`
| Champ | Type | Notes |
|-------|------|-------|
| `Code` | Single line text (unique) | A01, A02, B15, C03… |
| `Libellé` | Single line text | « Étagère A – bas gauche » |
| `Zone` | Single select | A, B, C… |
| `Réserve` | Single select / Link | Multi-réserves |
| `QR payload` | Formula | `"L:" & {Code}` |
| `Produits` | Link → `Produits` | Produits stockés ici |

## 3.6 Table `Opérateurs`
| Champ | Type | Notes |
|-------|------|-------|
| `Nom` | Single line text | Prénom affiché |
| `PIN (hash)` | Single line text | **Jamais le PIN en clair** — hash (bcrypt/SHA-256+sel) vérifié côté proxy |
| `Badge UID` | Single line text | UID NFC (optionnel) |
| `Rôle` | Single select | `Opérateur`, `Responsable`, `Admin` |
| `Photo` | Attachment | Avatar (accueil personnalisé) |
| `Actif` | Checkbox | Désactiver un compte |
| `Mouvements` | Link → `Mouvements` | Traçabilité |
| `Réserve` | Single select / Link | Rattachement |

## 3.7 Table `Mouvements` (journal — cœur de la traçabilité)
**L'app crée une ligne ici ; une automation met à jour `Produits.Stock courant`.**

| Champ | Type | Notes |
|-------|------|-------|
| `ID mouvement` | Autonumber / Formula | Identifiant lisible |
| `Type` | Single select | `Entrée`, `Sortie`, `Correction`, `Inventaire` |
| `Produit` | Link → `Produits` | 1 |
| `Quantité` | Number | Toujours positive ; le `Type` porte le signe |
| `Stock avant` | Number | **Rempli par l'automation** (snapshot) |
| `Stock après` | Number | Rempli par l'automation |
| `Opérateur` | Link → `Opérateurs` | Qui |
| `Emplacement` | Link → `Emplacements` | Où |
| `Mission` | Link → `Missions` | Si issu d'une mission |
| `Date/Heure` | Created time | Quand (auto) |
| `Client key` | Single line text (unique) | **Idempotence** : UUID généré par l'app, empêche les doublons si renvoi offline |
| `Source` | Single select | `Scan`, `Mission`, `Manuel`, `Inventaire` |
| `Commentaire` | Long text | Optionnel (ex. « produit abîmé ») |

## 3.8 Table `Missions`
| Champ | Type | Notes |
|-------|------|-------|
| `Nom` | Single line text | « Chariot sanitaire » |
| `Description` | Long text | Consigne |
| `Assignée à` | Link → `Opérateurs` | Opérateur cible |
| `Statut` | Single select | `À faire`, `En cours`, `Terminée`, `Annulée` |
| `Type mouvement` | Single select | `Sortie` (défaut) / `Entrée` / `Inventaire` |
| `Lignes` | Link → `Lignes de missions` | Étapes |
| `Progression` | Rollup/Formula | % de lignes servies |
| `Date prévue` | Date | Optionnel |
| `Créée par` | Link → `Opérateurs` | Responsable |

## 3.9 Table `Lignes de missions`
| Champ | Type | Notes |
|-------|------|-------|
| `Mission` | Link → `Missions` | Parent |
| `Ordre` | Number | Séquence guidée |
| `Produit` | Link → `Produits` | Produit à prélever |
| `Emplacement` | Lookup (Produit) | Où aller |
| `Quantité prévue` | Number | À prendre |
| `Quantité servie` | Number | Rempli à la validation |
| `Statut` | Single select | `En attente`, `Servie`, `Passée (indispo)` |

## 3.10 Table `Fournisseurs`
| Champ | Type | Notes |
|-------|------|-------|
| `Nom` | Single line text | |
| `Contact` | Single line text | |
| `Email` | Email | Pour futur envoi de bon de commande |
| `Téléphone` | Phone | |
| `Délai livraison (j)` | Number | Info réappro |
| `Produits` | Link → `Produits` | Catalogue |

## 3.11 Table `Alertes`
Créée **automatiquement** quand un stock passe sous le seuil (voir automations).
| Champ | Type | Notes |
|-------|------|-------|
| `Produit` | Link → `Produits` | |
| `Type` | Single select | `Sous seuil`, `Rupture` |
| `Stock au déclenchement` | Number | |
| `Qté à commander suggérée` | Formula | `MAX({Produit.Seuil cible} - {Produit.Stock courant}, 0)` |
| `Statut` | Single select | `Ouverte`, `Commandée`, `Résolue` |
| `Créée le` | Created time | |
| `Fournisseur` | Lookup (Produit) | |

Vue **« À commander »** = Alertes `Statut = Ouverte`, groupé par Fournisseur.

## 3.12 Table `Inventaires`
Comptages physiques (inventaire tournant / annuel).
| Champ | Type | Notes |
|-------|------|-------|
| `Produit` | Link → `Produits` | |
| `Quantité comptée` | Number | Saisie terrain |
| `Stock théorique` | Lookup (Produit → Stock courant) | Au moment du comptage |
| `Écart` | Formula | `{Quantité comptée} - {Stock théorique}` |
| `Opérateur` | Link → `Opérateurs` | |
| `Date` | Created time | |
| `Ajusté` | Checkbox | True → automation crée un `Mouvement` type `Inventaire` pour corriger |

---

## 3.13 Automatisations Airtable

| # | Déclencheur | Action | But |
|---|-------------|--------|-----|
| A1 | **Nouveau `Mouvement`** créé | Lire `Produit.Stock courant` → écrire `Stock avant`; calculer nouveau stock (`+Quantité` si Entrée, `−` si Sortie/Correction); écrire `Produit.Stock courant` et `Stock après` | **Maj stock (unique source)** |
| A2 | `Produit.Stock courant` modifié **et** `≤ Seuil` | Si aucune Alerte `Ouverte` pour ce produit → créer `Alerte` | Alertes auto |
| A3 | `Produit.Stock courant` repasse `> Seuil` | Passer les Alertes ouvertes du produit à `Résolue` | Nettoyage alertes |
| A4 | `Inventaire.Ajusté` coché | Créer `Mouvement` type `Inventaire` avec `Quantité = Écart` (signé) | Réconciliation physique |
| A5 | Toutes les lignes d'une `Mission` `Servie/Passée` | Passer `Mission.Statut = Terminée` + notifier le responsable | Suivi mission |
| A6 | Création d'`Alerte` `Rupture` | **Notification** (email/Slack) au responsable | Réactivité |
| A7 | **Planifié** (hebdo/mensuel) | Générer les snapshots de consommation + déclencher l'export (voir 3.14) | Reporting |
| A8 | Nouveau `Produit` sans QR imprimé | Marquer `À étiqueter` (vue) | Suivi étiquetage |
| A9 | Planifié (nuit) | **Sauvegarde** : copier les tables clés vers une base d'archive / déclencher backup externe | Résilience |

> **Idempotence (important) :** avant A1, l'automation (ou le proxy) vérifie qu'aucun Mouvement avec le même `Client key` n'existe déjà. Empêche les doublons quand l'app renvoie un mouvement resté en file offline.

## 3.14 Export Excel (.xlsx)

**Principe :** le stock **n'est jamais dans Excel** ; Excel est un **livrable d'exploitation généré à la demande / planifié**. Le stock reste dans Airtable.

Cinq classeurs / onglets :
1. **Inventaire complet** — Réf, Nom, Catégorie, Emplacement, Stock courant, Seuils, Statut, Prix, Valeur.
2. **Historique des mouvements** — période paramétrable, tous les champs de `Mouvements`.
3. **Produits à commander** — depuis vue Alertes ouvertes : Produit, Fournisseur, Stock, Seuil cible, Qté suggérée.
4. **Consommation mensuelle** — pivot Produit × mois (somme des sorties).
5. **Valorisation du stock** — Stock × Prix, sous-totaux par catégorie, total général.

**Options de mise en œuvre (par ordre de simplicité) :**
- **A. Bouton dans l'app → proxy backend** qui lit l'API Airtable et génère le `.xlsx` (lib `exceljs`/`openpyxl`) avec mise en forme (en-têtes, couleurs 🟢🟠🔴, largeurs, totaux). L'app propose « Partager / Enregistrer » le fichier. *(Recommandé pour un rendu Excel soigné.)*
- **B. Airtable Automation planifiée** (A7) → script qui pousse un CSV/XLSX vers un stockage (Drive/email). Rendu plus basique.
- **C. Airtable Interface + extension CSV** pour un export manuel de secours.

Le responsable déclenche l'export depuis l'écran **Responsable → Export**, choisit le type + la période, reçoit le fichier (partage Android natif / email).
