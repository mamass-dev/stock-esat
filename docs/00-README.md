# STOCK'ESAT — Dossier projet

Application Android (Flutter) de gestion de stock **accessible**, connectée à **Airtable**, pour un atelier Hygiène & Propreté en ESAT.

> Principe directeur : **« L'utilisateur ne doit jamais avoir besoin de réfléchir. »**
> Chaque écran est évident, rassurant, sans clavier, avec retour visuel + haptique permanent.

## Sommaire des documents

| # | Fichier | Contenu |
|---|---------|---------|
| 1 | `01-vision-cdc-personas.md` | Vision produit, cahier des charges, personas, exigences |
| 2 | `02-parcours-ux-maquettes.md` | Parcours utilisateurs + maquettes ASCII de tous les écrans |
| 3 | `03-airtable.md` | 11 tables détaillées, diagramme relationnel, automatisations, export Excel |
| 4 | `04-flutter-architecture.md` | Architecture Flutter, arborescence, packages, sécurité, offline |
| 5 | `05-accessibilite-charte.md` | Design Universel, charte graphique ESAT, règles d'accessibilité |
| 6 | `06-roadmap-estimations.md` | MVP / V2, roadmap, estimations temps & complexité, risques |

## Décisions d'architecture clés

> **DÉCISION 2026-07-01 : la base est Supabase (Postgres), pas Airtable.** Motif : Axel maîtrise déjà Supabase ; la RLS + Auth **supprime le proxy backend** (l'app parle direct à la base en sécurité) ; pas de limite d'API ; coût maîtrisé ; données possédées. Voir `03-supabase.md`. Les docs `03-airtable.md` / `07-guide-demarrage-airtable.md` sont **conservés en archive** (comparatif / plan B).

1. **Supabase = source de vérité unique du stock.** Excel n'est qu'un export d'exploitation, jamais une base.
2. **La décrémentation du stock se fait par un trigger SQL, pas côté app** → une seule logique métier, pas de désynchronisation.
3. **Pas de proxy** : l'app embarque la clé `anon` (publique), **bridée par RLS** (lecture référentiels + insert `mouvements` uniquement). Les actions responsable passent par Studio / compte authentifié / Edge Function. La clé `service_role` ne quitte jamais le serveur.
4. **Offline-first** avec file de synchronisation + `client_key unique` (idempotence native en base).
5. **Mono-réserve au MVP**, schéma déjà multi-sites/multi-réserves (champ `reserve` prêt).

**Documents à suivre pour le dev : `03-supabase.md` (base) + `07-guide-demarrage-supabase.md` (démarrage) + `04-flutter-architecture.md` (app, en ignorant la couche proxy).**
