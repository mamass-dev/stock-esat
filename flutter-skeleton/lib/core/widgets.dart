import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../app/theme.dart';

/// Retour haptique centralisé. Sans effet (et sans erreur) sur les plateformes
/// sans vibreur — ex. navigateur iPhone.
Future<void> buzz([int ms = 40]) async {
  try {
    if (await Vibration.hasVibrator()) Vibration.vibrate(duration: ms);
  } catch (_) {}
}

Future<void> buzzSuccess() async {
  try {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [0, 60, 80, 120]);
    }
  } catch (_) {}
}

/// Fond dégradé doux commun aux écrans.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bgSoft, AppColors.bg],
        ),
      ),
      child: child,
    );
  }
}

/// Gros bouton d'action — dégradé, ombre colorée, arrondi, haptique.
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.gradient = AppColors.gradSortie,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Container(
        height: Dim.bigButtonHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(Dim.radius),
          boxShadow: Shadows.colored(gradient.last),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(Dim.radius),
            onTap: () {
              buzz();
              onTap();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 30, color: Colors.white),
                const SizedBox(width: 12),
                Text(label,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tuile carrée d'accueil — dégradé, picto dans un carré translucide, ombre.
class BigTile extends StatelessWidget {
  const BigTile({
    super.key,
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(Dim.radiusLg),
          boxShadow: Shadows.colored(gradient.last),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(Dim.radiusLg),
            onTap: () {
              buzz();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label,
                        maxLines: 1,
                        style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sélecteur de quantité géant [ − ] N [ + ].
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 999,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _roundBtn(Icons.remove_rounded, value > min, () {
          buzz();
          onChanged(value - 1);
        }),
        Container(
          width: 120,
          alignment: Alignment.center,
          child: Text('$value',
              style: const TextStyle(
                  fontSize: 76,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain)),
        ),
        _roundBtn(Icons.add_rounded, value < max, () {
          buzz();
          onChanged(value + 1);
        }),
      ],
    );
  }

  Widget _roundBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        gradient: enabled
            ? const LinearGradient(colors: AppColors.gradSortie)
            : null,
        color: enabled ? null : const Color(0xFFDDE3EE),
        shape: BoxShape.circle,
        boxShadow: enabled ? Shadows.colored(AppColors.primary) : null,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: Icon(icon,
              size: 46,
              color: enabled ? Colors.white : const Color(0xFF9AA6B8)),
        ),
      ),
    );
  }
}

/// Pastille statut — couleur + picto + mot (accessible daltoniens).
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.stock,
    required this.seuilMini,
    required this.seuilRupture,
    this.large = false,
  });

  final int stock;
  final int seuilMini;
  final int seuilRupture;
  final bool large;

  @override
  Widget build(BuildContext context) {
    late Color c, bg;
    late IconData icon;
    late String txt;
    if (stock <= seuilRupture) {
      c = AppColors.rupture; bg = AppColors.ruptureBg;
      icon = Icons.error_rounded; txt = 'Rupture';
    } else if (stock <= seuilMini) {
      c = AppColors.faible; bg = AppColors.faibleBg;
      icon = Icons.warning_rounded; txt = 'Faible';
    } else {
      c = AppColors.ok; bg = AppColors.okBg;
      icon = Icons.check_circle_rounded; txt = 'OK';
    }
    final fs = large ? 26.0 : 20.0;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: large ? 18 : 14, vertical: large ? 12 : 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: c, size: large ? 30 : 24),
        const SizedBox(width: 8),
        Text('$stock  $txt',
            style: TextStyle(
                color: c, fontSize: fs, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
