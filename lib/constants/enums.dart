import '../config/app_utils.dart';

extension SizeExtension on num {
  double get h => CustomScreenUtil.height(toDouble());
  double get w => CustomScreenUtil.width(toDouble());
}