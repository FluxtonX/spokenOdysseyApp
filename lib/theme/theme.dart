import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'typography.dart';

class AppTheme {
  // ── Primary Brand Colors ───────────────────────────────────────────
  static const Color primaryDark = Color(0xFF1E2532);
  static const Color primary = Color(0xFF242B3A);
  static const Color primaryLight = Color(0xFF384358);
  static const Color accent = Color(
    0xFFF6E4D1,
  ); // Peach accent for icon backgrounds

  // ── Neutrals ───────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color scaffoldBg = Color(0xFFF3EFE9); // The beige background
  static const Color cardBg = Color(0xFFF3EFE9);
  static const Color divider = Color(0xFFE8ECF0);
  static const Color border = Color(0xFFD1D9E0);

  // ── Text colors ────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF2C2C2C);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textHint = Color(0xFFB0B8C4);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Status ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color floatingActionButton = Color(0xFF5544FF);

  // ── Gradient presets ───────────────────────────────────────────────
  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF2B3A55), // Dark blueish
      Color(0xFF9B7B5D), // Brownish
    ],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF242B3A), Color(0xFF1E2532)],
  );

  // ── ThemeData ──────────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    platform: TargetPlatform
        .android, // Ensure consistent layout and typography behavior
    typography: Typography.material2021(platform: TargetPlatform.android),
    brightness: Brightness.light,
    scaffoldBackgroundColor: scaffoldBg,
    primaryColor: primary,
    colorScheme: const ColorScheme.light(
      primary: primary,
      onPrimary: white,
      secondary: accent,
      onSecondary: textPrimary,
      surface: cardBg,
      onSurface: textPrimary,
      error: error,
      onError: white,
    ),
    textTheme: TextTheme(
      displayLarge: AppTextStyles.h1,
      headlineMedium: AppTextStyles.h2,
      displaySmall: AppTextStyles.h3,
      titleLarge: AppTextStyles.h3,
      titleMedium: AppTextStyles.labelBold,
      titleSmall: AppTextStyles.labelMedium,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.button,
      labelSmall: AppTextStyles.caption,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        textStyle: AppTextStyles.button,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: AppTextStyles.button.copyWith(color: primary),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: textSecondary,
        textStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: white,
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: textHint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryLight, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: error),
      ),
    ),
    cardTheme: CardThemeData(
      color: cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: divider),
      ),
    ),
    dividerTheme: const DividerThemeData(color: divider, thickness: 1),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: scaffoldBg,
      selectedItemColor: primary,
      unselectedItemColor: textHint,
      selectedLabelStyle: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
