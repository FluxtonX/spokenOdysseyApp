import 'package:flutter/material.dart';
import '../../customWidgets/custom_bottom_navbar.dart';
import '../../theme/theme.dart';
import 'home_screen.dart';
import 'discover_screen.dart';
import 'albums_screen.dart';
import 'family_screen.dart';
import 'more_screen.dart';

class MainTabScreen extends StatefulWidget {
  final int initialIndex;
  
  const MainTabScreen({super.key, this.initialIndex = 1});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    HomeScreen(),
    DiscoverScreen(),
    AlbumsScreen(),
    FamilyScreen(),
    MoreScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
