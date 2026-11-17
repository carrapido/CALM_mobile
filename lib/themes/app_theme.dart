import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Text styles of the design (odd/design), all in Plus Jakarta Sans.
class AppText {
  AppText._();

  static TextStyle _base(
    double size,
    double lineHeightPx,
    FontWeight w, {
    required Color color,
    double? letterSpacing,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      height: lineHeightPx / size,
      fontWeight: w,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  // Letter spacing turns the design's em into logical pixels.
  static TextStyle get largeTitle =>
      _base(34, 40, FontWeight.w800, color: AppColors.ink, letterSpacing: -0.68);
  static TextStyle get sheetTitle =>
      _base(22, 28, FontWeight.w800, color: AppColors.ink, letterSpacing: -0.22);
  static TextStyle get statusHeadline =>
      _base(28, 34, FontWeight.w800, color: AppColors.ink, letterSpacing: -0.42);
  static TextStyle get actionSheetButton => _base(19, 24, FontWeight.w600, color: AppColors.ink);
  static TextStyle get lead => _base(17, 24, FontWeight.w500, color: AppColors.onSurfaceVariant);
  static TextStyle get body => _base(17, 22, FontWeight.w600, color: AppColors.ink);
  static TextStyle get button => _base(17, 22, FontWeight.w700, color: AppColors.ink);
  static TextStyle get subhead => _base(15, 20, FontWeight.w600, color: AppColors.ink);
  static TextStyle get callout => _base(15, 20, FontWeight.w500, color: AppColors.onSurfaceVariant);
  static TextStyle get caption => _base(12, 16, FontWeight.w600, color: AppColors.onSurfaceVariant);
  static TextStyle get footnote => _base(13, 18, FontWeight.w400, color: AppColors.onSurfaceVariant);
  static TextStyle get footnoteStrong => _base(13, 18, FontWeight.w600, color: AppColors.onSurfaceVariant);
  static TextStyle get footnoteError => _base(13, 18, FontWeight.w700, color: AppColors.errorText);
  static TextStyle get brand =>
      _base(12, 16, FontWeight.w700, color: AppColors.onSurfaceVariant, letterSpacing: 0.96);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.surfaceCanvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.ink,
        primary: AppColors.ink,
        onPrimary: Colors.white,
        error: AppColors.errorRed,
        surface: AppColors.surfaceCanvas,
      ),
    );
  }
}

/// Soft lift of the status and ticket cards: ink at 5 % and 6 %.
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0D0F172A), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x0F0F172A), offset: Offset(0, 8), blurRadius: 24),
  ];
}
