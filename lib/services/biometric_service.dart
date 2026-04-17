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
    try {
      // On iOS, check both canCheckBiometrics and isDeviceSupported
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool deviceSupported = await _auth.isDeviceSupported();
      
      return canCheck || deviceSupported;
    } catch (e) {
      return false;
    }
  }

  // Check if biometrics are available and enrolled
  Future<bool> areBiometricsAvailable() async {
    try {
      List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
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

  // Get the primary biometric type available on the device
  Future<String> getBiometricType() async {
    try {
      List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();
      
      if (availableBiometrics.contains(BiometricType.face)) {
        return 'Face ID';
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        return 'Touch ID';
      } else if (availableBiometrics.contains(BiometricType.strong)) {
        return 'Biometric';
      } else {
        return 'Biometric';
      }
    } catch (e) {
      return 'Biometric';
    }
  }

  // Authenticate user with biometrics
  Future<bool> authenticate() async {
    try {
      // Check if device supports any form of authentication
      final bool deviceSupported = await isDeviceSupported();
      if (!deviceSupported) return false;

      // On iOS, even if no biometrics are enrolled, we can still authenticate with passcode
      // The local_auth package handles this automatically
      return await _auth.authenticate(
        localizedReason: 'Please authenticate to access your account',
        biometricOnly: false, // Allow fallback to passcode on iOS
        sensitiveTransaction: true,
      );
    } catch (e) {
      // Handle specific iOS errors
      print('Biometric authentication error: $e');
      return false;
    }
  }
}
