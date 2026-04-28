import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';
import '../services/auth_services.dart';
import '../services/biometric_service.dart';
import '../services/profile_service.dart';
import '../config/get_it.dart';
import '../config/server_constants.dart';
import '../views/authScreen/login_screen.dart';
import '../views/onboarding/complete_profile_screen.dart';
import '../views/tabs/main_tab_screen.dart';

class AuthController extends GetxController {
  final AuthService _authService = getIt<AuthService>();
  final BiometricService _biometricService = getIt<BiometricService>();
  final ProfileService _profileService = ProfileService();
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ServerConstants.baseUrl,
      connectTimeout: ServerConstants.connectTimeout,
      receiveTimeout: ServerConstants.receiveTimeout,
      sendTimeout: ServerConstants.sendTimeout,
    ),
  );
  final GetStorage _storage = GetStorage();

  static const String hasSeenOnboardingKey = 'has_seen_onboarding';
  static const String biometricPromptShownKey = 'biometric_prompt_shown';

  // Observables
  final RxBool isLoading = false.obs;
  final RxBool isBiometricLoading = false.obs;
  final Rx<User?> firebaseUser = Rx<User?>(null);

  // Memory cache for the current session's credentials
  // (Used to enable biometrics after manual login)
  String? _sessionEmail;
  String? _sessionPassword;

  String? get sessionEmail => _sessionEmail;
  String? get sessionPassword => _sessionPassword;

  // Get biometric type for UI display
  Future<String> getBiometricType() async {
    return await _biometricService.getBiometricType();
  }

  @override
  void onInit() {
    super.onInit();
    // Bind firebaseUser to the auth state changes stream
    firebaseUser.bindStream(_authService.authStateChanges);

    // Listen to changes and navigate accordingly
    ever(firebaseUser, _handleAuthChanged);
  }

  void _handleAuthChanged(User? user) {
    // This logic can be used for global redirection if needed
    // However, it might interfere with splash screen timing
    // so we will be careful here.
  }

  // Sign in with email and password
  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      await _authService.signIn(email, password);

      // Cache credentials for the session to allow enabling biometrics
      _sessionEmail = email;
      _sessionPassword = password;

      await routeAfterAuthentication();
      await _maybePromptToEnableBiometrics();
    } catch (e) {
      Get.snackbar(
        'Login Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Login using stored biometric credentials
  Future<void> loginWithBiometrics() async {
    try {
      if (!_biometricService.isBiometricEnabled()) {
        String biometricType = await _biometricService.getBiometricType();
        Get.snackbar(
          '$biometricType Disabled',
          'Please first manual login and enable ${biometricType.toLowerCase()} in settings',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Check if device supports biometrics
      bool deviceSupported = await _biometricService.isDeviceSupported();
      if (!deviceSupported) {
        String biometricType = await _biometricService.getBiometricType();
        Get.snackbar(
          'Not Supported',
          '$biometricType authentication is not supported on this device.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.1),
        );
        return;
      }

      bool authenticated = await _biometricService.authenticate();
      if (authenticated) {
        isBiometricLoading.value = true;
        final credentials = await _biometricService.getCredentials();

        if (credentials != null) {
          await _authService.signIn(
            credentials['email']!,
            credentials['password']!,
          );

          await routeAfterAuthentication();
        } else {
          Get.snackbar(
            'Error',
            'No stored credentials found. Please login manually once.',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } else {
        String biometricType = await _biometricService.getBiometricType();
        Get.snackbar(
          'Authentication Failed',
          '$biometricType authentication was cancelled or failed.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.1),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Biometric Login Failed',
        'An error occurred during biometric authentication. Please try manual login.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
      );
    } finally {
      isBiometricLoading.value = false;
    }
  }

  // Sign up with email and password
  Future<void> register(String email, String name, String password) async {
    try {
      isLoading.value = true;
      UserCredential userCredential = await _authService.signUp(
        email,
        password,
      );

      // Cache credentials for the session
      _sessionEmail = email;
      _sessionPassword = password;

      // Update display name if provided
      if (name.isNotEmpty) {
        await userCredential.user?.updateDisplayName(name);
      }

      await routeAfterAuthentication();
      await _maybePromptToEnableBiometrics();
    } catch (e) {
      Get.snackbar(
        'Registration Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Sign out
  Future<void> logout() async {
    try {
      await _authService.signOut();

      // Reset session cache on logout for security
      _sessionEmail = null;
      _sessionPassword = null;

      Get.offAll(() => const LoginScreen());
    } catch (e) {
      Get.snackbar(
        'Logout Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    try {
      isLoading.value = true;
      await _authService.resetPassword(email);
      Get.snackbar(
        'Success',
        'Password reset email sent to $email',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  // Sync Firebase user with MongoDB backend
  Future<void> _syncUserWithBackend() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final token = await user.getIdToken();

      final response = await _dio.post(
        '/api/auth/sync',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('Backend sync successful: ${response.data}');
      } else {
        debugPrint('Backend sync failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error syncing with backend: $e');
      // We don't block the user if sync fails, but we log it
    }
  }

  Future<Map<String, dynamic>?> fetchBackendProfile() async {
    try {
      return await _profileService.fetchMyProfile();
    } catch (error) {
      debugPrint('Error loading backend profile: $error');
      return null;
    }
  }

  Future<void> routeAfterAuthentication() async {
    try {
      await _syncUserWithBackend().timeout(
        const Duration(seconds: 14),
        onTimeout: () {
          debugPrint('Backend sync timed out during auth routing.');
        },
      );

      final profile = await fetchBackendProfile().timeout(
        const Duration(seconds: 14),
        onTimeout: () {
          debugPrint('Profile fetch timed out during auth routing.');
          return null;
        },
      );
      final isProfileComplete = profile?['profileCompleted'] == true;

      if (isProfileComplete) {
        Get.offAll(() => const MainTabScreen(initialIndex: 0));
        return;
      }

      if (profile != null) {
        _storage.write(hasSeenOnboardingKey, true);
        Get.offAll(() => CompleteProfileScreen(initialProfile: profile));
        return;
      }
    } catch (error) {
      debugPrint('routeAfterAuthentication fallback triggered: $error');
    }

    Get.offAll(() => const MainTabScreen(initialIndex: 0));
  }

  Future<void> _maybePromptToEnableBiometrics() async {
    if (_sessionEmail == null || _sessionPassword == null) {
      return;
    }

    if (_biometricService.isBiometricEnabled()) {
      return;
    }

    if (_storage.read(biometricPromptShownKey) == true) {
      return;
    }

    final deviceSupported = await _biometricService.isDeviceSupported();
    final biometricsAvailable = await _biometricService
        .areBiometricsAvailable();

    if (!deviceSupported || !biometricsAvailable) {
      return;
    }

    final biometricType = await _biometricService.getBiometricType();

    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (Get.context == null) {
      return;
    }

    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enable $biometricType?',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'You just signed in manually. Enable faster and secure access for your next visit.',
              style: Theme.of(Get.context!).textTheme.bodyMedium,
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF5544FF).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF5544FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$biometricType login uses your device security and keeps sign-in friction low.',
                  style: Theme.of(Get.context!).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5544FF),
              foregroundColor: Colors.white,
            ),
            child: Text('Enable $biometricType'),
          ),
        ],
      ),
      barrierDismissible: true,
    );

    _storage.write(biometricPromptShownKey, true);

    if (result == true) {
      await _enableBiometricsFromPrompt(biometricType);
    }
  }

  Future<void> _enableBiometricsFromPrompt(String biometricType) async {
    final authenticated = await _biometricService.authenticate();
    if (!authenticated) {
      Get.snackbar(
        'Authentication Cancelled',
        '$biometricType setup was cancelled. You can still enable it later from settings.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await _biometricService.saveCredentials(_sessionEmail!, _sessionPassword!);
    _biometricService.setBiometricEnabled(true);

    Get.snackbar(
      'Biometric Login Enabled',
      '$biometricType is now ready for faster sign-in on this device.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
