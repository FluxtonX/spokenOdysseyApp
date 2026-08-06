import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/pages/forgot_password_page.dart';
import 'features/auth/presentation/pages/onboarding_page.dart';
import 'features/auth/presentation/pages/reset_password_page.dart';
import 'features/auth/presentation/pages/sign_in_page.dart';
import 'features/auth/presentation/pages/sign_up_page.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/auth/presentation/pages/verify_otp_page.dart';
import 'core/constants/asset_constants.dart';
import 'core/services/local_notification_service.dart';
import 'features/home/presentation/pages/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initServiceLocator();
  await LocalNotificationService().initialize();
  runApp(const SpokenOdysseyApp());
}

class SpokenOdysseyApp extends StatelessWidget {
  const SpokenOdysseyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create: (context) => sl<AuthCubit>(),
      child: MaterialApp(
        title: 'Spoken Odyssey',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(AssetConstants.bgPic, fit: BoxFit.cover),
              ),
              if (child != null) child,
            ],
          );
        },
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (_) => const SplashPage());
            case '/onboarding':
              return MaterialPageRoute(builder: (_) => const OnboardingPage());
            case '/sign-in':
              return MaterialPageRoute(builder: (_) => const SignInPage());
            case '/sign-up':
              return MaterialPageRoute(builder: (_) => const SignUpPage());
            case '/forgot-password':
              return MaterialPageRoute(
                builder: (_) => const ForgotPasswordPage(),
              );
            case '/verify-otp':
              final email = settings.arguments as String? ?? '';
              return MaterialPageRoute(
                builder: (_) => VerifyOtpPage(email: email),
              );
            case '/reset-password':
              final args = settings.arguments as Map<String, dynamic>? ?? {};
              return MaterialPageRoute(
                builder: (_) => ResetPasswordPage(
                  email: args['email'] ?? '',
                  otp: args['otp'] ?? '',
                ),
              );
            case '/home':
              return MaterialPageRoute(builder: (_) => const MainScreen());
            default:
              return MaterialPageRoute(builder: (_) => const SplashPage());
          }
        },
      ),
    );
  }
}
