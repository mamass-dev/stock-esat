import 'package:flutter/material.dart';

/// Système de design accessible ESAT — chaleureux, lisible, contrasté.
class AppColors {
  // Marque
  static const primary = Color(0xFF2557D6);
  static const primaryDark = Color(0xFF16357E);

  // Fonds & surfaces
  static const bg = Color(0xFFEEF2FB);
  static const bgSoft = Color(0xFFF7F9FE);
  static const surface = Color(0xFFFFFFFF);

  // Textes
  static const textMain = Color(0xFF14202E);
  static const textSoft = Color(0xFF6B7688);

  // États stock (toujours doublés d'un picto + mot)
  static const ok = Color(0xFF1E9E5A);
  static const okBg = Color(0xFFE6F6EC);
  static const faible = Color(0xFFE8890C);
  static const faibleBg = Color(0xFFFDF0DD);
  static const rupture = Color(0xFFE23D3D);
  static const ruptureBg = Color(0xFFFCE8E8);

  // Dégradés des tuiles d'accueil
  static const gradEntree = [Color(0xFF25B673), Color(0xFF159E63)];
  static const gradSortie = [Color(0xFF3B6FF0), Color(0xFF2557D6)];
  static const gradConsulter = [Color(0xFF6C7BF2), Color(0xFF4453D8)];
  static const gradResponsable = [Color(0xFF64748B), Color(0xFF44526A)];
}

/// Espacements, rayons, tailles (Design Universel — généreux).
class Dim {
  static const double bigButtonHeight = 76;
  static const double tileMinHeight = 158;
  static const double gap = 16;
  static const double pad = 22;
  static const double radius = 24;
  static const double radiusLg = 30;
}

class Shadows {
  static List<BoxShadow> soft = [
    BoxShadow(
      color: const Color(0xFF1B2A4A).withValues(alpha: 0.10),
      blurRadius: 22,
      offset: const Offset(0, 10),
    ),
  ];
  static List<BoxShadow> colored(Color c) => [
        BoxShadow(
          color: c.withValues(alpha: 0.35),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ];
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    surface: AppColors.surface,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    fontFamily: 'Lexend',
  );

  return base.copyWith(
    textTheme: base.textTheme
        .apply(bodyColor: AppColors.textMain, displayColor: AppColors.textMain)
        .copyWith(
          headlineLarge: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              height: 1.15,
              color: AppColors.textMain),
          titleLarge: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain),
          bodyLarge: const TextStyle(
              fontSize: 19, height: 1.3, color: AppColors.textMain),
        ),
    // Couleur du texte saisi + curseur dans tous les champs
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: TextStyle(color: AppColors.textSoft),
      labelStyle: TextStyle(color: AppColors.textSoft),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.textMain,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Lexend',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textMain,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dim.radius),
      ),
    ),
  );
}
