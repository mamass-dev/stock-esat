# 5 — Accessibilité (Design Universel) & Charte graphique ESAT

## 5.1 Principes fondateurs
> « L'utilisateur ne doit jamais avoir besoin de réfléchir. Chaque écran est évident. »

1. **Une action principale par écran.** Jamais deux décisions en même temps.
2. **Reconnaître plutôt que se souvenir.** Photos + pictos > texte + références.
3. **Aucune fonction cachée.** Pas de menu burger, pas de swipe secret, pas de long-press requis pour une action essentielle.
4. **Retour permanent.** Chaque appui produit un effet visible immédiat (couleur, animation), + haptique, + son/TTS optionnel.
5. **Réversibilité douce.** « Retour » et « Annuler » toujours présents, sans conséquence anxiogène.
6. **Erreurs impossibles > erreurs bien gérées.** Récap avant validation, scan de confirmation, boutons + / − (pas de frappe).

## 5.2 Règles concrètes (checklist dev)

**Cibles & espacement**
- Cible tactile **≥ 64 dp** (idéal 72 dp), boutons pleine largeur, **≥ 16 dp** entre deux cibles.
- Maximum **~4 éléments interactifs** par écran.

**Texte**
- Corps **≥ 20 sp**, boutons **≥ 24 sp**, chiffres clés (stock, quantité) **très gros** (≥ 48 sp).
- Vocabulaire **FALC** : phrases courtes, verbes d'action à l'infinitif, pas de jargon.
- Police lisible sans empattement, interlettrage normal (ex. **Atkinson Hyperlegible**, Lexend, ou Roboto).
- Jamais de texte en capitales sur de longues chaînes ; pas de justification.

**Couleur & contraste**
- Contraste texte/fond **≥ 4.5:1** (AA), idéalement 7:1 (AAA) pour l'essentiel.
- **Jamais l'information par la couleur seule** : 🟢🟠🔴 toujours accompagnés d'un **picto + mot** (OK / Faible / Rupture) → daltoniens.
- Fond clair, éléments actifs très contrastés, pas de fond photo derrière du texte.

**Interaction**
- **Pas de clavier** sauf pavé PIN. Quantités via + / −. Recherche via catégories/pictos ou voix.
- Pas de double-tap, pas de geste de précision, tolérance aux appuis répétés (débounce).
- Zones de « retour accueil » et « aide » constantes, toujours au même endroit.

**Retour multisensoriel**
- **Haptique** : vibration courte à chaque appui, motif « succès » à la validation, motif « attention » sur alerte.
- **Sonore/TTS** : lecture optionnelle des libellés et confirmations (activable par utilisateur/réserve).
- **Visuel** : overlay ✅ plein écran à la validation, jamais un simple toast discret.

**Compatibilité**
- Respect de **TalkBack**, `Semantics(label:)` sur chaque widget interactif.
- Respect du **facteur de zoom système** (textScaleFactor) sans casser la mise en page.
- Mode **fort contraste** et **très gros texte** proposés dans Réglages.

## 5.3 Charte graphique adaptée à un ESAT

**Ton :** rassurant, chaleureux, professionnel, non-infantilisant. Couleurs franches mais pas criardes.

**Palette (exemple, à ajuster à la marque ESAT) :**
| Rôle | Couleur | Hex |
|------|---------|-----|
| Primaire (actions) | Bleu profond | `#1D5FA8` |
| Primaire foncé (texte sur clair) | | `#0E3A6B` |
| Fond | Blanc cassé | `#F7F8FA` |
| Surface / cartes | Blanc | `#FFFFFF` |
| Succès / Stock OK | Vert | `#2E7D32` |
| Alerte / Stock faible | Orange | `#E58A00` |
| Danger / Rupture | Rouge | `#C62828` |
| Texte principal | Gris très foncé | `#1A1A1A` |

> Les 3 couleurs d'état sont **toujours** doublées d'un picto : ● OK / ▲ Faible / ■ Rupture.

**Typographie :** Atkinson Hyperlegible (ou Lexend). Titres 28–34 sp, boutons 24 sp, chiffres clés 48–64 sp.

**Iconographie :** pictogrammes pleins, simples, universels (style Material Symbols « filled »). Un concept = un picto stable dans toute l'app. Idéalement s'appuyer sur des pictos de type **Arasaac** (référence FALC/handicap) pour les produits/catégories.

**Photos produits :** cadrées serré, fond neutre, format carré, haute résolution. La photo est le principal moyen de reconnaissance.

**Motion :** animations lentes et douces (200–300 ms), aucune animation clignotante/rapide (risque cognitif). Respecter « réduire les animations » du système.

## 5.4 Conformité visée
- **RGAA 4 / WCAG 2.1 niveau AA** comme socle, avec dépassements AAA sur contraste et taille de texte.
- Tests utilisateurs **avec de vrais opérateurs** dès le MVP (indispensable en ESAT) : mesurer taux de réussite d'une sortie sans aide, points de blocage, fatigue.
