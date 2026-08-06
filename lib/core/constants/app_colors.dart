import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Theme Colors
  static const Color primary = Color(0xFF5B3EFF);
  static const Color primaryDark = Color(0xFF421FD2);
  static const Color primaryLight = Color(0xFF8672FF);
  static const Color accent = Color(0xFF7000FF);

  // Gradient Colors for Splash & Cards
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF6B4AFF), Color(0xFF4825E2), Color(0xFF2C0FBB)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF5B3EFF), Color(0xFF381AD6), Color(0xFF240DAA)],
  );

  // Neutrals
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF9FAFC);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Input & Border Colors
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderFocused = Color(0xFF5B3EFF);
  static const Color inputBackground = Color(0xFFFFFFFF);

  // Status & Feedback Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Indicator Colors
  static const Color indicatorActive = Color(0xFF5B3EFF);
  static const Color indicatorInactive = Color(0xFFE0D8FF);

  // Social Button Fill
  static const Color socialButtonBg = Color(0xFFFFFFFF);
  static const Color socialButtonBorder = Color(0xFFE5E7EB);
}
