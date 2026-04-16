import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../services/auth_services.dart';
import '../services/biometric_service.dart';
import '../config/get_it.dart';
import '../views/authScreen/login_screen.dart';
import '../views/tabs/main_tab_screen.dart';

class AuthController extends GetxController {
  final AuthService _authService = getIt<AuthService>();
  final BiometricService _biometricService = getIt<BiometricService>();

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

      Get.offAll(() => const MainTabScreen());
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
        Get.snackbar(
          'Biometrics Disabled',
          'Please first manual login and enable the biometric in settings',
          snackPosition: SnackPosition.BOTTOM,
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
          Get.offAll(() => const MainTabScreen());
        } else {
          Get.snackbar(
            'Error',
            'No stored credentials found. Please login manually once.',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Biometric Login Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
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

      Get.offAll(() => const MainTabScreen());
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
}
