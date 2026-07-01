# Stock'ESAT — Export Excel (ordinateur)

Outil réservé à l'ordinateur du responsable. Il se connecte à la base Supabase
(en **lecture seule**, via la clé publique `anon`) et génère un classeur Excel
mis en forme. **Aucune donnée n'est stockée dans Excel** : c'est un document
d'exploitation généré à la demande.

## Contenu du fichier généré
Un fichier `Stock-ESAT_AAAA-MM-JJ.xlsx` avec 3 onglets :
1. **Inventaire** — toutes les références, stock, seuils, statut coloré 🟢🟠🔴
2. **À commander** — produits sous le seuil + quantité suggérée
3. **Historique** — les mouvements récents (date, type, produit, quantités)

## Lancer l'export
Dans un Terminal :
```bash
cd /Users/mamass/stock-esat/export
npm run export
```
Le fichier `.xlsx` apparaît dans ce dossier. Ouvre-le avec Excel / Numbers /
LibreOffice.

## Prérequis (déjà faits sur ce Mac)
- Node.js installé
- `npm install` déjà exécuté dans ce dossier (dépendances : `@supabase/supabase-js`, `exceljs`)

## Notes
- Volontairement **indisponible sur l'app mobile** (la tablette des opérateurs
  reste simple ; l'export est une tâche de gestion, faite au bureau).
- La clé utilisée est la clé **anon** (publique, lecture seule) — pas de secret.
- Pour un export planifié automatique (ex. tous les lundis) ou un envoi par
  e-mail, ça peut s'ajouter facilement.
