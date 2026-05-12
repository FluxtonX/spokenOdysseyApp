import 'package:get/get.dart';
import '../../controllers/navigation_controller.dart';
import '../../customWidgets/custom_bottom_navbar.dart';
import 'Home/home_screen.dart';
import 'albums_screen.dart';
import 'family_screen.dart';
import 'more_screen.dart';
import 'record_tab_screen.dart';
import 'package:flutter/material.dart';

class MainTabScreen extends StatefulWidget {
  final int initialIndex;

  const MainTabScreen({super.key, this.initialIndex = 0});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  final NavigationController _navController = Get.find<NavigationController>();

  final List<Widget> _screens = [
    const HomeScreen(),
    const RecordTabScreen(),
    const AlbumsScreen(),
    const FamilyScreen(),
    const MoreScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _navController.setTabIndex(widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: IndexedStack(
          index: _navController.selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _navController.selectedIndex,
          onTap: (index) {
            _navController.setTabIndex(index);
          },
        ),
      ),
    );
  }
}
