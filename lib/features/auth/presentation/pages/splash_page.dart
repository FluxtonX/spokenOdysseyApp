import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/asset_constants.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.read<AuthCubit>().checkAuthStatus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          Navigator.pushReplacementNamed(context, '/home');
        } else if (state is Unauthenticated) {
          Navigator.pushReplacementNamed(context, '/onboarding');
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.splashGradient,
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  width: 120,
                  height: 120,
                  padding: const EdgeInsets.all(12),
                  child: SvgPicture.asset(
                    AssetConstants.logo,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Spoken Odyssey',
                  style: GoogleFonts.outfit(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your voice. Your life. Preserved',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
