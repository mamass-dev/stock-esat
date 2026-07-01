# 1 — Vision produit, Cahier des charges, Personas

## 1.1 Vision produit

**Stock'ESAT** transforme la gestion manuelle d'une réserve Hygiène & Propreté (plusieurs centaines de références) en un geste numérique simple : **scanner → confirmer → c'est fait**.

L'application n'est pas un logiciel de gestion classique adapté « en plus » : elle est **conçue dès l'origine autour des capacités des travailleurs en situation de handicap**. La complexité métier (calcul de stock, seuils, alertes, historique, valorisation) est **entièrement déportée dans Airtable**. L'opérateur ne voit qu'une interface épurée : gros pictogrammes, gros boutons, une action par écran.

**Proposition de valeur :**
- Pour **l'opérateur** : autonomie, confiance, zéro erreur de saisie, zéro clavier.
- Pour **le responsable** : stock fiable en temps réel, alertes automatiques, cockpit de pilotage, export Excel prêt à l'emploi.
- Pour **l'ESAT** : outil inclusif valorisant, réduction des ruptures et du gaspillage, données de consommation exploitables.

**Vision à 3 ans :** socle réutilisable pour tous les ateliers de l'ESAT (cuisine, blanchisserie, espaces verts, sous-traitance), multi-sites, avec gestion EPI, prêts de matériel et commandes fournisseurs.

## 1.2 Cahier des charges

### Fonctionnel — MVP
| Réf | Exigence | Priorité |
|-----|----------|----------|
| F-01 | Authentification simple par **code PIN 4 chiffres** (pavé géant) ou badge NFC | Must |
| F-02 | Écran d'accueil = **4 gros boutons** (Entrée / Sortie / Consulter / Responsable) | Must |
| F-03 | **Scan QR/code-barres** produit avec reconnaissance automatique | Must |
| F-04 | Fiche produit : **grande photo**, nom, stock restant, pastille couleur 🟢🟠🔴 | Must |
| F-05 | Ajustement quantité par **gros boutons + / −** (pas de saisie clavier) | Must |
| F-06 | Sortie de stock ≤ **7 étapes**, avec confirmation visuelle + vibration | Must |
| F-07 | Entrée de stock (réception) sur le même modèle | Must |
| F-08 | Scan **emplacement** (A01, B15…) → liste des produits stockés à cet endroit | Must |
| F-09 | Consultation stock : liste + recherche visuelle par photo/catégorie | Must |
| F-10 | **Historique automatique** de chaque mouvement (voir table Mouvements) | Must |
| F-11 | Écran Responsable protégé par PIN renforcé (rôle) | Must |
| F-12 | **Mode Mission** : parcours guidé pas-à-pas préparé par le responsable | Should |
| F-13 | Génération/impression des **étiquettes QR + photo + réf + emplacement** | Should |
| F-14 | **Alertes** automatiques sous seuil + vue « À commander » | Must |
| F-15 | **Tableau de bord** responsable (KPIs + graphiques) | Should |
| F-16 | **Export Excel** (inventaire, historique, à commander, conso, valorisation) | Must |
| F-17 | **Synthèse vocale (TTS)** optionnelle sur les libellés clés | Should |
| F-18 | **Mode hors ligne** avec synchronisation automatique au retour réseau | Should (MVP+) |

### Non-fonctionnel
- **Accessibilité** : conformité RGAA/WCAG 2.1 AA minimum, principes Design Universel (voir doc 5).
- **Performance** : temps de réponse perçu < 400 ms sur action locale ; scan → fiche < 1,5 s.
- **Robustesse** : aucune perte de mouvement (file offline persistée + idempotence).
- **Sécurité** : clé API Airtable jamais dans l'APK (proxy), PIN hashé localement, rôles.
- **Cibles** : Android 8+ (API 26+), écrans 5"–10" (tablette recommandée en réserve).
- **Langue** : français, textes courts, niveau FALC (Facile À Lire et à Comprendre).
- **Maintenabilité** : le responsable gère produits/photos/seuils **dans Airtable**, sans toucher au code.

### Contraintes & hypothèses
- Une tablette Android partagée en réserve (ou 2-3), pas un smartphone par personne.
- Réseau Wi‑Fi parfois faible → offline indispensable en V1.1.
- Airtable plan Team minimum recommandé (automatisations + volume d'enregistrements).
- Volumétrie : ~300–600 produits, ~50–200 mouvements/jour → largement dans les limites Airtable.

## 1.3 Personas

### 👤 Karim — Opérateur atelier (utilisateur principal)
- 34 ans, déficience intellectuelle légère, lecture lente, se fatigue vite en concentration.
- **Reconnaît les produits par la photo**, pas par la référence.
- **Objectif** : sortir les produits pour sa mission de nettoyage sans se tromper.
- **Frustrations** : formulaires, claviers, écrans chargés, messages d'erreur en rouge.
- **Besoins** : gros boutons, une action à la fois, confirmation claire (« C'est bon ✅ » + vibration), pouvoir revenir en arrière sans stress.

### 👤 Sophie — Opératrice, difficultés motrices
- 41 ans, tremblements, précision de toucher réduite.
- **Besoins** : cibles tactiles ≥ 72 dp, espacement large, pas de double-tap ni de glisser précis, tolérance aux appuis multiples.

### 👤 Marc — Moniteur d'atelier / Responsable de réserve
- 48 ans, encadrant. Prépare les missions, gère les seuils, passe les commandes.
- **Objectif** : stock fiable, savoir quoi commander, sortir un Excel pour sa hiérarchie.
- **Besoins** : cockpit clair, alertes automatiques, export en 1 clic, pouvoir corriger un mouvement erroné, gérer les fiches produits/photos dans Airtable.
- **N'est pas développeur** : tout se pilote via Airtable + l'écran Responsable.

### 👤 Nadia — Direction ESAT (sponsor)
- Veut un outil **valorisant et inclusif**, réutilisable dans d'autres ateliers, avec un coût maîtrisé et des données de pilotage.

## 1.4 Améliorations proposées (au-delà de la demande)
- **Mode « photo obligatoire à la réception »** pour constituer la photothèque produits sans effort.
- **Bouton « Je ne trouve pas » / « Aide »** sur chaque écran → appelle le moniteur (notification).
- **Confirmation par récapitulatif visuel** (grande photo + quantité en chiffres énormes) avant validation.
- **Anti-double-scan** (débounce) et **idempotence** des mouvements pour éviter les doublons.
- **Journal d'audit** immuable (qui / quand / quoi) pour la traçabilité qualité.
- **Mode démo** (données fictives) pour former les opérateurs sans impacter le vrai stock.
