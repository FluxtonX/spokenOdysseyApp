import 'package:flutter/material.dart';

class DesignTokens {
  DesignTokens._();

  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 24;
  static const double spaceXxl = 32;
  static const double spaceXxxl = 40;
  static const double spaceSection = 48;

  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusPill = 999;

  static const double controlHeight = 48;
  static const double iconButtonSize = 48;

  /// Legacy floating shadow — kept for backwards compat.
  static const List<BoxShadow> floatingShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  /// Premium card shadow: soft, deep elevation feel.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  /// FAB glow: violet halo beneath the centre action button.
  static const List<BoxShadow> fabGlow = [
    BoxShadow(
      color: Color(0x595B3EFF), // ~35% primary violet
      blurRadius: 20,
      offset: Offset(0, 6),
      spreadRadius: 0,
    ),
  ];

  /// Privacy badge colours (background).
  static const Color privacyPublicBg = Color(0xFF10B981);
  static const Color privacyFamilyBg = Color(0xFF3B82F6);
  static const Color privacyPrivateBg = Color(0xFF6B7280);

  /// Primary gradient (left → right variant used on buttons / icon containers).
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF5B3EFF), Color(0xFF7000FF)],
  );

  /// Light tinted surface used for audio player container.
  static const Color audioSurface = Color(0xFFF3F0FF);
}
