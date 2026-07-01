# 4 — Architecture Flutter, code, sécurité, offline

## 4.1 Vue d'ensemble

```
┌──────────────────────────────────────────┐
│  APP FLUTTER (Android APK)                │
│  UI accessible ── State (Riverpod) ──     │
│  Repositories ── Cache local (Isar/Drift) │
│  File de sync offline (queue persistée)   │
└───────────────┬──────────────────────────┘
                │ HTTPS (jamais la clé Airtable)
┌───────────────▼──────────────────────────┐
│  PROXY BACKEND (Cloud Function / Vercel)  │
│  - Détient la clé/PAT Airtable (secret)   │
│  - Auth PIN (vérif hash), rôles           │
│  - Idempotence (Client key)               │
│  - Génération Excel (.xlsx)               │
└───────────────┬──────────────────────────┘
                │ Airtable API (REST)
┌───────────────▼──────────────────────────┐
│  AIRTABLE  (base + automations)           │
└──────────────────────────────────────────┘
```

> **Pourquoi un proxy et pas d'appel direct Airtable depuis l'app ?** La clé/PAT Airtable dans un APK est extractible → accès total en écriture à la base. Le proxy garde le secret côté serveur, applique les rôles, l'idempotence et sert de point d'export Excel. C'est la seule architecture acceptable en production.

## 4.2 Choix techniques

| Sujet | Choix | Raison |
|-------|-------|--------|
| State management | **Riverpod** | Testable, découplé, bon pour offline/async |
| Navigation | **go_router** | Routes déclaratives, deep-links mission |
| Base locale / cache | **Isar** (ou Drift) | Rapide, offline-first, requêtes simples |
| Scan QR/code-barres | **mobile_scanner** | Maintenu, perf, torche, formats multiples |
| HTTP | **dio** | Intercepteurs (retry, auth, offline) |
| Modèles immuables | **freezed + json_serializable** | Sûreté, moins de bugs |
| TTS | **flutter_tts** | Synthèse vocale fr |
| Haptique | **Vibration / HapticFeedback** | Retour à chaque validation |
| NFC (badge) | **nfc_manager** | Auth badge (optionnel) |
| Secure storage | **flutter_secure_storage** | Token de session, jamais la clé Airtable |
| i18n | **flutter_localizations / intl** | fr (base), évolutif |
| Génération QR (côté responsable) | **qr_flutter** + PDF (**pdf**/**printing**) | Planches d'étiquettes |

## 4.3 Arborescence du projet (Flutter)

```
lib/
├── main.dart
├── app/
│   ├── app.dart                 # MaterialApp.router + thème accessible
│   ├── router.dart              # go_router (routes + guards rôle)
│   └── theme/
│       ├── app_theme.dart       # gros textes, contrastes AA, tailles cibles
│       ├── colors.dart          # palette + 🟢🟠🔴
│       └── dimensions.dart      # tailles boutons/espacements (tokens)
├── core/
│   ├── accessibility/
│   │   ├── tts_service.dart
│   │   ├── haptics.dart
│   │   └── a11y_widgets.dart    # BigButton, BigTile, StatusPill…
│   ├── network/
│   │   ├── api_client.dart      # dio -> proxy
│   │   └── connectivity.dart
│   ├── offline/
│   │   ├── sync_queue.dart      # file persistée de Mouvements
│   │   └── sync_worker.dart     # rejeu au retour réseau (idempotent)
│   ├── error/
│   └── utils/ (uuid, formatters…)
├── data/
│   ├── models/                  # freezed: Produit, Mouvement, Mission…
│   ├── dto/                     # mapping API <-> modèles
│   └── repositories/
│       ├── produit_repository.dart
│       ├── mouvement_repository.dart
│       ├── mission_repository.dart
│       ├── emplacement_repository.dart
│       └── auth_repository.dart
├── features/
│   ├── auth/            (pin_screen, badge_screen, providers)
│   ├── home/           (home_screen — 4 tuiles)
│   ├── scan/           (scan_screen, résolution QR produit/emplacement)
│   ├── entree/         (flux entrée)
│   ├── sortie/         (flux sortie: fiche, quantité, récap, confirmation)
│   ├── stocks/         (liste, filtres couleur, recherche visuelle)
│   ├── emplacement/    (contenu d'un emplacement)
│   ├── mission/        (assistant guidé pas-à-pas)
│   └── responsable/    (cockpit, alertes, export, étiquettes, inventaire)
├── l10n/               (arb fr)
└── config/
    └── env.dart        # URL du proxy (pas de secret)
```

## 4.4 Widgets d'accessibilité (réutilisables)
- `BigButton` : hauteur ≥ 72 dp, texte ≥ 24 sp, picto ≥ 40 dp, `Semantics(label)`, feedback haptique + TTS optionnel au tap.
- `BigTile` : tuile carrée accueil (picto + un mot).
- `QuantityStepper` : `[ − ]  N  [ + ]`, chiffre géant, appui long accéléré borné, recalcul « il restera » en direct.
- `StatusPill` : pastille 🟢🟠🔴 + libellé (jamais couleur seule → aussi picto/texte, pour daltoniens).
- `ConfirmationOverlay` : ✅ plein écran + vibration succès + TTS.
- `HelpButton` : « Appeler le moniteur » présent partout.

## 4.5 Sécurité
- **Clé/PAT Airtable** : uniquement côté proxy (variable d'environnement serveur). Jamais dans l'APK, jamais dans le repo.
- **Auth** : PIN saisi → envoyé au proxy → comparaison au **hash** stocké dans `Opérateurs` → le proxy renvoie un **token de session court** (JWT) stocké en `flutter_secure_storage`. L'espace Responsable exige un rôle `Responsable`/`Admin`.
- **Transport** : HTTPS/TLS obligatoire, certificate pinning optionnel.
- **Idempotence** : chaque Mouvement porte un `Client key` (UUID) → pas de double décrément.
- **Moindre privilège** : le token borne les actions (un opérateur ne peut pas exporter ni éditer les seuils).
- **RGPD** : données personnelles minimales (prénom, éventuel badge). Registre + finalité (traçabilité qualité). Pas de données sensibles handicap dans la base.
- **Verrouillage** : auto-logout après inactivité ; PIN requis pour revenir sur l'espace Responsable.

## 4.6 Offline-first & synchronisation
1. Toute **écriture** (Mouvement, ligne de mission servie) est d'abord **persistée localement** avec un `Client key` et un statut `pending`.
2. L'UI affiche **succès immédiat** (« enregistré ✅ », bandeau « sera envoyé »).
3. `sync_worker` rejoue la file dès que le réseau revient, dans l'ordre, avec retry exponentiel.
4. Le proxy/Airtable **dédoublonne** via `Client key` (idempotent) → rejouer 2× est sans effet.
5. **Lectures** : cache local (Produits/Emplacements) rafraîchi périodiquement → l'app reste utilisable hors ligne pour consulter et scanner.
6. Conflits : le stock étant recalculé par accumulation de mouvements (et non écrasé), l'ordre d'arrivée n'altère pas le résultat final.

## 4.7 API à utiliser (contrat proxy)
Endpoints exposés par le proxy (le proxy traduit vers l'API Airtable) :
- `POST /auth/pin` → `{ operatorId, token, role }`
- `GET /produits?since=…` → liste (cache)
- `GET /produit/:refOuId`
- `GET /emplacement/:code` → produits de l'emplacement
- `POST /mouvement` (body inclut `clientKey`) → crée + déclenche A1
- `GET /missions?operator=…` / `GET /mission/:id`
- `POST /mission/:id/ligne/:lid/servir`
- `GET /responsable/dashboard` (agrégats)
- `GET /responsable/a-commander`
- `POST /export` `{ type, periode }` → `.xlsx`
- `POST /etiquettes` `{ produitIds }` → PDF

Côté Airtable : **REST API** standard (list/create/update records, `?view=`, `filterByFormula`), **Automations** pour la logique, **Webhooks** (optionnel) pour notifier le proxy.
