# Stock'ESAT — Squelette Flutter

Application Android accessible, branchée sur Supabase (RLS, pas de backend).

## Ce qui est implémenté (tranche verticale)
- 🔐 **Connexion PIN** (pavé géant) → RPC `login_operateur`
- 🏠 **Accueil** 4 gros boutons (Entrée / Sortie / Consulter / Responsable)
- 📷 **Scan** QR/code-barres (`mobile_scanner`) + résolution produit
- 📤/📦 **Parcours Entrée/Sortie** : fiche photo → quantité `[ − ] N [ + ]` → validation → **confirmation** (haptique) ; le stock baisse via le **trigger SQL** côté Supabase
- 📊 **Consulter les stocks** : liste + pastilles 🟢🟠🔴 (picto + mot, accessible daltoniens)
- ⚙ **Espace Responsable** + ➕ **Ajouter un produit** RÉSERVÉ ADMIN (RPC `admin_ajouter_produit`, vérif PIN+rôle côté base). PIN admin de test : **9999**. Opérateur (1234) et responsable (4321) ne voient/peuvent pas l'ajout.
- 📷 **Photos produits** : l'admin peut en ajouter une à la création ; l'**opérateur** peut prendre la photo manquante d'un produit existant depuis son téléphone (bucket Supabase Storage `produits-photos`, compression `maxWidth:1200 / quality:70` → ~150-250 Ko, RPC `definir_photo_produit`).
- Widgets accessibles réutilisables : `BigButton`, `BigTile`, `QuantityStepper`, `StatusPill`

## Démarrer
1. Installer Flutter (3.4+). Vérifier : `flutter doctor`
2. Renseigner la clé anon : `lib/config/env.dart` → `supabaseAnonKey`
   (Supabase → Settings → API → `anon` `public`). L'URL est déjà remplie.
3. `flutter pub get`
4. Brancher un téléphone/tablette Android (le scan a besoin de la caméra) puis `flutter run`

### Permission caméra (Android)
Ajouter dans `android/app/src/main/AndroidManifest.xml` :
```xml
<uses-permission android:name="android.permission.CAMERA" />
```
et `minSdkVersion 21` (mobile_scanner) dans `android/app/build.gradle`.

## Tester sans matériel
Connecte-toi avec le PIN **1234** (Karim, opérateur de test créé dans le seed).
Le scan nécessite une vraie caméra ; sur émulateur, imprime/affiche un QR contenant `P:DET-SOL-5L`.

## Arborescence
```
lib/
├── main.dart                    # init Supabase + routes (go_router)
├── config/env.dart              # URL + clé anon (à remplir)
├── app/theme.dart               # charte accessible (couleurs, tailles)
├── core/widgets.dart            # BigButton, BigTile, QuantityStepper, StatusPill, haptique
├── data/
│   ├── models.dart              # Operateur, Produit
│   └── repositories.dart        # auth, produits, mouvements (Supabase)
└── features/
    ├── auth/pin_screen.dart
    ├── home/home_screen.dart
    ├── scan/scan_screen.dart
    ├── sortie/mouvement_screen.dart   # fiche + quantité + confirmation
    └── stocks/stocks_screen.dart
```

## Prochaines étapes (non encore codées)
- File de synchronisation **offline** + rejeu idempotent (le `client_key` est déjà envoyé)
- Écran **Responsable** (cockpit, alertes, export Excel, étiquettes)
- **Mode Mission** (assistant guidé)
- Synthèse vocale (`flutter_tts`) sur les libellés clés
- Scan **emplacement** → produits du lieu (optionnel, table `emplacements`)

## Sécurité
- La clé `anon` est publique mais **bridée par RLS** (lecture référentiels + insert `mouvements` uniquement). Sûre dans l'APK.
- Jamais de clé `service_role` ni de mot de passe DB dans l'app.
