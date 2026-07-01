# Stock'ESAT

Système de gestion de stock accessible pour un atelier Hygiène & Propreté en ESAT.

## Composants
- **`flutter-skeleton/`** — application mobile Android (Flutter) pour les opérateurs : connexion PIN, scan QR, entrées/sorties, cockpit, gestion admin.
- **`web/`** — dashboard responsable (Next.js 16, déployé sur Vercel) : pilotage, inventaire, mouvements, journal, opérateurs, réglages, export Excel, étiquettes QR. Protégé par login.
- **`sql/`** — schéma Supabase (PostgreSQL) : tables, triggers (stock, alertes, journal), fonctions RPC.
- **`export/`** — outil Node d'export Excel (alternatif au dashboard).
- **`docs/`** — dossier de conception (vision, cahier des charges, personas, archi, accessibilité, roadmap).

## Stack
Flutter · Next.js 16 / React 19 / Tailwind v4 · Supabase (Postgres, RLS, Storage) · Vercel.

## Sécurité
- Les secrets ne sont pas versionnés (voir `.gitignore` : `.env.local`).
- L'app mobile et le dashboard utilisent la clé `anon` (bridée par RLS).
- Les écritures sensibles côté web passent par des routes serveur (service_role) après vérification de session.
