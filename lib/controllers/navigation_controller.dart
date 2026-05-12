import 'package:get/get.dart';

class NavigationController extends GetxController {
  static NavigationController get to => Get.find();

  final _selectedIndex = 0.obs;
  int get selectedIndex => _selectedIndex.value;

  void setTabIndex(int index) {
    _selectedIndex.value = index;
  }
}
