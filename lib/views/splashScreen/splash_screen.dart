import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../theme/theme.dart';
import '../../controllers/auth_controller.dart';

import '../onboarding/onboarding_screen.dart';
import '../tabs/main_tab_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
          ),
        );

    _animationController.forward();

    // Navigate after 3 seconds
    Timer(const Duration(seconds: 3), () {
      final authController = Get.find<AuthController>();
      if (authController.firebaseUser.value != null) {
        Get.offAll(() => const MainTabScreen());
      } else {
        Get.offAll(() => const OnboardingScreen());
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo Icon
                Image.asset('assets/images/logo.png', width: 80, height: 80),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Spoken Odyssey',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: AppTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Your voice. Your life. Preserved.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
