import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Estilos de texto (Plus Jakarta Sans) según DESIGN.md.
class AppText {
  AppText._();

  static TextStyle _base(double size, double lineHeightPx, FontWeight w,
      {Color color = AppColors.borderStrong}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      height: lineHeightPx / size,
      fontWeight: w,
      color: color,
    );
  }

  static TextStyle get headlineXlMobile => _base(26, 34, FontWeight.w800);
  static TextStyle get headlineSm => _base(18, 26, FontWeight.w600);
  static TextStyle get bodyLg => _base(18, 28, FontWeight.w500);
  static TextStyle get bodyMd =>
      _base(16, 24, FontWeight.w400, color: AppColors.onSurfaceVariant);
  static TextStyle get bodySm => _base(14, 20, FontWeight.w400);
  static TextStyle get labelLg => _base(16, 22, FontWeight.w700);
  static TextStyle get labelMd => _base(14, 20, FontWeight.w600);
  static TextStyle get labelSm => _base(12, 16, FontWeight.w600);
  static TextStyle get ticketBadge => _base(22, 28, FontWeight.w800);
    static TextStyle get headlineLg => _base(24, 32, FontWeight.w800);
  static TextStyle get headlineMd => _base(20, 28, FontWeight.w700);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.surfaceCanvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.borderStrong,
        primary: AppColors.borderStrong,
        onPrimary: Colors.white,
        secondary: AppColors.ticketYellow,
        error: AppColors.errorRed,
        surface: AppColors.surfaceCanvas,
      ),
    );
  }
}
