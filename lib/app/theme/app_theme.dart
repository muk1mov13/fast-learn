import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Light va Dark mavzular hamda tipografik shkala.
class AppTheme {
  AppTheme._();

  static TextTheme _text(Color ink, Color muted) {
    final display = GoogleFonts.sora(); // sarlavhalar uchun xarakterli shrift
    final body = GoogleFonts.manrope(); // matn uchun
    return TextTheme(
      displaySmall: display.copyWith(
          fontSize: 30, fontWeight: FontWeight.w800, color: ink, height: 1.1),
      headlineSmall: display.copyWith(
          fontSize: 23, fontWeight: FontWeight.w800, color: ink, height: 1.15),
      titleLarge: display.copyWith(
          fontSize: 19, fontWeight: FontWeight.w700, color: ink),
      titleMedium: body.copyWith(
          fontSize: 15.5, fontWeight: FontWeight.w700, color: ink),
      bodyLarge: body.copyWith(fontSize: 15, color: ink, height: 1.55),
      bodyMedium: body.copyWith(fontSize: 13.5, color: ink, height: 1.5),
      bodySmall: body.copyWith(fontSize: 12, color: muted, height: 1.45),
      labelLarge: body.copyWith(
          fontSize: 13.5, fontWeight: FontWeight.w700, color: ink),
    );
  }

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.danger,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.appBg,
      textTheme: _text(AppColors.ink, AppColors.muted),
      splashFactory: InkRipple.splashFactory,
      dividerColor: AppColors.line,
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surfaceDark,
      error: AppColors.danger,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.appBgDark,
      textTheme: _text(AppColors.inkDark, AppColors.mutedDark),
      splashFactory: InkRipple.splashFactory,
      dividerColor: AppColors.lineDark,
    );
  }
}

/// Mavzuga bog'liq yordamchi ranglar (light/dark farqi uchun).
extension ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get surfaceColor =>
      isDark ? AppColors.surfaceDark : AppColors.surface;
  Color get lineColor => isDark ? AppColors.lineDark : AppColors.line;
  Color get mutedColor => isDark ? AppColors.mutedDark : AppColors.muted;
  Color get inkColor => isDark ? AppColors.inkDark : AppColors.ink;
  Color get softFillColor =>
      isDark ? AppColors.softFillDark : AppColors.softFill;
  Color get appBgColor => isDark ? AppColors.appBgDark : AppColors.appBg;
}
