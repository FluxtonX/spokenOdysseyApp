import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:get_storage/get_storage.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final GetStorage _storage = GetStorage();

  static const String _keyEmail = 'biometric_email';
  static const String _keyPassword = 'biometric_password';
  static const String _keyEnabled = 'biometric_enabled';

  // Check if device supports biometrics
  Future<bool> isDeviceSupported() async {
    return await _auth.isDeviceSupported();
  }

  // Check if user has enabled biometrics in settings
  bool isBiometricEnabled() {
    return _storage.read(_keyEnabled) ?? false;
  }

  // Enable/Disable biometric login
  void setBiometricEnabled(bool enabled) {
    _storage.write(_keyEnabled, enabled);
  }

  // Store credentials securely
  Future<void> saveCredentials(String email, String password) async {
    await _secureStorage.write(key: _keyEmail, value: email);
    await _secureStorage.write(key: _keyPassword, value: password);
  }

  // Retrieve credentials securely
  Future<Map<String, String>?> getCredentials() async {
    String? email = await _secureStorage.read(key: _keyEmail);
    String? password = await _secureStorage.read(key: _keyPassword);
    
    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  // Clear stored credentials
  Future<void> clearCredentials() async {
    await _secureStorage.delete(key: _keyEmail);
    await _secureStorage.delete(key: _keyPassword);
  }

  // Authenticate user with biometrics
  Future<bool> authenticate() async {
    try {
      bool canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;

      return await _auth.authenticate(
        localizedReason: 'Please authenticate to log in',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }
}
