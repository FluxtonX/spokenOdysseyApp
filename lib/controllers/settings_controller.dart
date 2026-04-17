import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/biometric_service.dart';
import '../config/get_it.dart';
import 'auth_controller.dart';

class SettingsController extends GetxController {
  final BiometricService _biometricService = getIt<BiometricService>();

  // Tab management...
  final RxInt activeTabIndex = 0.obs;

  // Biometric state
  final RxBool isBiometricEnabled = false.obs;
  final RxString biometricType = 'Biometric'.obs;

  // Privacy Settings (matching new screenshot)
  final RxString defaultEntryPrivacy = 'Private - Only by you'.obs;
  final RxString profileVisibility = 'Follower only'.obs;

  final List<String> privacyOptions = [
    'Private - Only by you',
    'Family - Your family circle',
    'Public - Everyone',
  ];

  final List<String> visibilityOptions = [
    'Public - Anyone can view',
    'Follower only',
  ];

  // Profile fields (matching the screenshot)
  final displayNameController = TextEditingController(text: "John Anderson");
  final professionController = TextEditingController(
    text: "Technology Executive & Mentor",
  );
  final locationController = TextEditingController(text: "San Francisco, CA");
  final birthDateController = TextEditingController(text: "Feb-03-1980");
  final bioController = TextEditingController(
    text:
        "Technology executive with 25 years of experience building products that matter. Passionate about mentorship and preserving wisdom for the next...",
  );
  final lifeMottoController = TextEditingController(
    text:
        "The best time to plant a tree was 20 years ago. The second best time is...",
  );

  // Expertise chips
  final RxList<String> expertise = <String>[
    'Leadership',
    'IT',
    'Entrepreneurship',
  ].obs;
  final expertiseInputController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // Load persisted biometric setting
    isBiometricEnabled.value = _biometricService.isBiometricEnabled();
    // Load biometric type
    _loadBiometricType();
  }

  Future<void> _loadBiometricType() async {
    biometricType.value = await _biometricService.getBiometricType();
  }

  void toggleBiometrics(bool value) async {
    final AuthController authController = Get.find<AuthController>();

    if (value) {
      // Check if device supports biometrics first
      bool deviceSupported = await _biometricService.isDeviceSupported();
      if (!deviceSupported) {
        isBiometricEnabled.value = false;
        Get.snackbar(
          'Not Supported',
          'Biometric authentication is not supported on this device.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.1),
        );
        return;
      }

      // Check if we have credentials in the session to store
      if (authController.sessionEmail == null ||
          authController.sessionPassword == null) {
        isBiometricEnabled.value = false;
        Get.snackbar(
          'Manual Login Required',
          'For security, please Log Out and Log In manually once to enable biometrics.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.1),
          duration: const Duration(seconds: 5),
        );
        return;
      }

      // If turning ON, we must verify the user first
      bool authenticated = await _biometricService.authenticate();
      if (authenticated) {
        // Save the session credentials to secure storage
        await _biometricService.saveCredentials(
          authController.sessionEmail!,
          authController.sessionPassword!,
        );

        _biometricService.setBiometricEnabled(true);
        isBiometricEnabled.value = true;

        Get.snackbar(
          'Success',
          '${biometricType.value} login enabled successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.1),
        );
      } else {
        isBiometricEnabled.value = false;
        Get.snackbar(
          'Authentication Failed',
          'Biometric authentication was cancelled or failed. Please ensure Face ID/Touch ID is properly set up on your device.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.1),
        );
      }
    } else {
      // Turning OFF
      _biometricService.setBiometricEnabled(false);
      await _biometricService.clearCredentials();
      isBiometricEnabled.value = false;

      Get.snackbar(
        'Disabled',
        'Biometric login has been disabled.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void addExpertise(String value) {
    if (value.trim().isNotEmpty && !expertise.contains(value.trim())) {
      expertise.add(value.trim());
      expertiseInputController.clear();
    }
  }

  void removeExpertise(String value) {
    expertise.remove(value);
  }

  void saveChanges() {
    // Implement save logic (e.g., update Firebase profile)
    Get.snackbar(
      'Profile Updated',
      'Your changes have been saved successfully.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.1),
    );
  }

  @override
  void onClose() {
    displayNameController.dispose();
    professionController.dispose();
    locationController.dispose();
    birthDateController.dispose();
    bioController.dispose();
    lifeMottoController.dispose();
    expertiseInputController.dispose();
    super.onClose();
  }
}
