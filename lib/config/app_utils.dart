import 'package:flutter/widgets.dart';

class CustomScreenUtil {
  static late double screenWidth;
  static late double screenHeight;

  static const double baseWidth = 375;
  static const double baseHeight = 812;

  static void init(BuildContext context) {
    final size = MediaQuery.of(context).size;
    screenWidth = size.width;
    screenHeight = size.height;
  }

  static double width(double value) {
    return value * (screenWidth / baseWidth);
  }

  static double height(double value) {
    return value * (screenHeight / baseHeight);
  }
  static double textSize(double value) {
    return value * (screenWidth / baseWidth);
  }
}
