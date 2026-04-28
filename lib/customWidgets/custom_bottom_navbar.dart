import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final barColor = isDark ? const Color(0xFF17304D) : const Color(0xFF5544FF);
    final buttonColor = isDark
        ? const Color(0xFF6EA8FF)
        : const Color(0xFF5544FF);
    final inactiveColor = isDark
        ? const Color(0xFFB8D3FF)
        : const Color(0xFFDCE8FF);

    return SafeArea(
      top: false,
      child: CurvedNavigationBar(
        index: currentIndex,
        height: 66,
        backgroundColor: Colors.transparent,
        color: barColor,
        buttonBackgroundColor: buttonColor,
        animationDuration: const Duration(milliseconds: 320),
        animationCurve: Curves.easeOutCubic,
        items: [
          _buildNavIcon(
            icon: Icons.home_outlined,
            isActive: currentIndex == 0,
            activeColor: Colors.white,
            inactiveColor: inactiveColor,
          ),
          _buildNavIcon(
            icon: Icons.fiber_manual_record_rounded,
            isActive: currentIndex == 1,
            activeColor: Colors.white,
            inactiveColor: inactiveColor,
          ),
          _buildNavIcon(
            icon: Icons.folder_outlined,
            isActive: currentIndex == 2,
            activeColor: Colors.white,
            inactiveColor: inactiveColor,
          ),
          _buildNavIcon(
            icon: Icons.people_outline_rounded,
            isActive: currentIndex == 3,
            activeColor: Colors.white,
            inactiveColor: inactiveColor,
          ),
          _buildNavIcon(
            icon: Icons.settings_outlined,
            isActive: currentIndex == 4,
            activeColor: Colors.white,
            inactiveColor: inactiveColor,
          ),
        ],
        onTap: onTap,
      ),
    );
  }

  Widget _buildNavIcon({
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    return Icon(icon, size: 26, color: isActive ? activeColor : inactiveColor);
  }
}
