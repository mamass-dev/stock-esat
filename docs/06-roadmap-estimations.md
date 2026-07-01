# 6 — Plan de développement, MVP, V2, Roadmap, Estimations

## 6.1 Plan de développement (phases)

**Phase 0 — Cadrage & données (préalable indispensable)**
- Récupérer le catalogue réel (Réf, Nom, Catégorie, Unité, Prix, Seuils, Fournisseur, Emplacement).
- **Photographier** les produits (photothèque). Définir le plan d'emplacements (A01…).
- Construire la base Airtable + saisie initiale + automations A1/A2/A3.
- Imprimer un premier jeu d'étiquettes QR (produits + emplacements).

**Phase 1 — Fondations app**
- Setup Flutter, thème accessible (tokens), proxy backend + endpoints auth/produits/mouvement.
- Auth PIN, écran Accueil, cache local Isar.

**Phase 2 — Cœur métier (MVP)**
- Scan (produit + emplacement), fiche produit, parcours **Sortie** puis **Entrée**, confirmation haptique.
- Consultation stocks (filtres 🟢🟠🔴), historique (via Mouvements).
- Offline queue + sync idempotente.

**Phase 3 — Responsable**
- Cockpit (KPIs), Alertes / À commander, Export Excel, génération étiquettes PDF.

**Phase 4 — Mode Mission**
- Assistant guidé pas-à-pas, scan de confirmation, suivi de progression.

**Phase 5 — Durcissement & terrain**
- Tests utilisateurs avec opérateurs, TTS, ajustements accessibilité, stabilisation offline, sauvegardes.

## 6.2 MVP (périmètre minimal livrable)
- Auth PIN + Accueil 4 boutons.
- **Sortie** et **Entrée** par scan (le cœur : supprimer les erreurs de saisie).
- Fiche produit (photo, stock, couleur), quantité + / −, récap, confirmation haptique.
- Consultation stocks + statut couleur.
- Historique automatique (Airtable) + maj stock par automation A1.
- Alertes sous seuil (A2) + vue « À commander ».
- Export Excel « Inventaire » + « À commander ».
- Offline basique (file de sync).

## 6.3 Version 2
- **Mode Mission** complet (assistant guidé).
- Cockpit graphique riche + conso mensuelle + top produits + valorisation.
- Génération/impression d'étiquettes en masse.
- TTS généralisé + réglages accessibilité (fort contraste, taille).
- Badge NFC, inventaire tournant.
- Exports Excel complets (5 classeurs) + envoi automatique planifié.

## 6.4 Roadmap d'évolution (V3+)
Architecture déjà prête (champ `Réserve`, proxy, modèles) pour :
- Multi-réserves / **multi-sites**.
- **Table `Stocks`** (produit × emplacement) pour stockage multi-localisations.
- Bons de commande + **commandes fournisseurs** (email auto depuis Alertes) + réception liée.
- **Signature des sorties** (émargement tactile), gestion **EPI**, gestion **matériels** & **prêts** (sortie/retour).
- Statistiques annuelles, prévision de conso.
- **Douchette Bluetooth** (HID) en complément de la caméra.
- **Notifications push** au responsable (rupture) via service push.
- Mode hors ligne avancé (sync bidirectionnelle robuste).

## 6.5 Estimations de temps

> Fourchettes pour **1 développeur Flutter expérimenté + config Airtable**, hors saisie catalogue/photos (Phase 0, à la charge de l'ESAT, ~1–2 semaines selon volume). Un binôme réduit le calendaire ~35 %.

| Lot | Charge estimée |
|-----|----------------|
| Phase 0 — Airtable + automations + données | 4–7 j (dev) + saisie/photos côté ESAT |
| Phase 1 — Fondations app + proxy + auth | 6–9 j |
| Phase 2 — MVP cœur (scan, entrée/sortie, stocks, offline) | 12–18 j |
| Phase 3 — Responsable (cockpit, export, étiquettes) | 8–12 j |
| Phase 4 — Mode Mission | 6–9 j |
| Phase 5 — A11y, tests terrain, durcissement | 6–10 j |
| **Total indicatif** | **~42–65 j·h ≈ 9–13 semaines** |

- **MVP seul (Phases 0→3 réduites)** : **~6–8 semaines**.
- Produit complet V2 : **~12–15 semaines**.

## 6.6 Complexité (par domaine)

| Domaine | Complexité | Points d'attention |
|---------|-----------|--------------------|
| UI accessible | Moyenne | Le soin, pas la technique : itérations avec vrais utilisateurs |
| Scan QR | Faible | Package mature (`mobile_scanner`) |
| Airtable + automations | Moyenne | Idempotence, limites d'API (5 req/s/base), snapshots stock |
| Proxy backend + sécurité | Moyenne | Secret, rôles, idempotence, génération Excel |
| Offline & sync | **Élevée** | Le vrai risque technique : file persistée, rejeu, dédoublonnage |
| Export Excel mis en forme | Moyenne | Génération serveur (exceljs/openpyxl) |
| Étiquettes PDF | Faible-Moyenne | qr_flutter + pdf/printing |
| Mode Mission | Moyenne | Machine à états, scan de confirmation |

**Complexité globale : Moyenne.** Le point dur est l'**offline robuste** ; tout le reste est du bien-fait plus que du difficile.

## 6.7 Risques & parades

| Risque | Impact | Parade |
|--------|--------|--------|
| Clé Airtable extraite de l'APK | Critique | Proxy backend obligatoire, secret serveur |
| Doublons de mouvements (offline) | Élevé | `Client key` + idempotence côté Airtable/proxy |
| Limites d'API Airtable (débit/volume) | Moyen | Batching, cache lectures, plan Team, archivage mouvements |
| Photothèque incomplète | Moyen (UX) | Photo obligatoire à la réception, campagne photo Phase 0 |
| Réseau réserve faible | Élevé | Offline-first dès V1.1 |
| Rejet utilisateurs (trop complexe) | Critique projet | Tests terrain précoces, FALC, une action/écran |
| Airtable = coût/lock-in à l'échelle | Moyen (long terme) | Schéma propre → migration possible vers Postgres/Supabase si volumétrie explose |

## 6.8 Recommandations UX/UI finales
- Prototyper d'abord le **parcours Sortie** et le tester avec 3–4 opérateurs **avant** d'écrire le reste.
- Personnaliser l'accueil (prénom + avatar) : appropriation et repères.
- **Photothèque = priorité n°1** : sans bonnes photos, tout le bénéfice s'effondre.
- Prévoir une **tablette murale/chariot** avec support, plutôt qu'un smartphone tenu à la main.
- Bouton **« Appeler le moniteur »** partout : filet de sécurité qui rassure et débloque.
- Former via le **mode démo** (données fictives) avant le vrai stock.
- Mesurer le succès : % de sorties réussies **sans aide**, temps moyen, nombre d'erreurs corrigées → c'est l'indicateur produit clé.
