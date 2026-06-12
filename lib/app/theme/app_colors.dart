import 'package:flutter/material.dart';

/// Markazlashtirilgan dizayn tokenlari — hech qayerda "sehrli raqam" bo'lmasin.
class AppColors {
  AppColors._();

  // Brend
  static const primary = Color(0xFF1463FF);
  static const primaryDark = Color(0xFF0B46C0);
  static const accent = Color(0xFFFF7A1A);

  // Bosqich ranglari (didaktik oqim)
  static const stageMotivation = Color(0xFFFF7A1A); // Motivatsiya
  static const stageLearn = Color(0xFF1463FF); // O'zlashtirish
  static const stageReinforce = Color(0xFF1DAA6B); // Mustahkamlash
  static const stageAssess = Color(0xFF6C4CE0); // Baholash

  static const ok = Color(0xFF1DAA6B);
  static const danger = Color(0xFFE5484D);

  // Light neytral
  static const ink = Color(0xFF14161C);
  static const muted = Color(0xFF5A6173);
  static const surface = Color(0xFFFFFFFF);
  static const appBg = Color(0xFFF4F6FB);
  static const line = Color(0xFFE6E9F0);
  static const softFill = Color(0xFFEEF1F7);

  // Dark neytral
  static const inkDark = Color(0xFFF2F4FA);
  static const mutedDark = Color(0xFF98A0B3);
  static const surfaceDark = Color(0xFF161A24);
  static const appBgDark = Color(0xFF0C0F16);
  static const lineDark = Color(0xFF262C3A);
  static const softFillDark = Color(0xFF1F2533);

  // Gradientlar
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1463FF), Color(0xFF1B51D6), Color(0xFF143FB0)],
  );
  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF7A1A), Color(0xFFFF9234)],
  );
  static const progressGradient = LinearGradient(
    colors: [Color(0xFFFF7A1A), Color(0xFFFF9D52)],
  );
}

class AppRadius {
  AppRadius._();
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 26.0;
  static const pill = 100.0;
}

class AppSpace {
  AppSpace._();
  static const xs = 6.0;
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 22.0;
  static const xl = 30.0;
}

class AppShadow {
  AppShadow._();
  static List<BoxShadow> card(bool dark) => [
        BoxShadow(
          color: dark
              ? Colors.black.withValues(alpha: 0.35)
              : const Color(0xFF101830).withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];
  static List<BoxShadow> soft(bool dark) => [
        BoxShadow(
          color: dark
              ? Colors.black.withValues(alpha: 0.30)
              : const Color(0xFF101830).withValues(alpha: 0.04),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ];
}
