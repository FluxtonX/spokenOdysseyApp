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

  static const List<BoxShadow> floatingShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
}
