import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/get_it.dart';
import '../services/biometric_service.dart';
import '../services/profile_service.dart';
import 'auth_controller.dart';

class SettingsController extends GetxController {
  final BiometricService _biometricService = getIt<BiometricService>();
  final ProfileService _profileService = ProfileService();

  final RxInt activeTabIndex = 0.obs;
  final RxInt insightsSubTabIndex = 0.obs;
  final RxInt activeSubPage = (-1).obs;

  final RxBool isBiometricEnabled = false.obs;
  final RxString biometricType = 'Biometric'.obs;
  final RxBool isSavingProfile = false.obs;
  final RxInt profileRevision = 0.obs;

  final RxString defaultEntryPrivacy = 'Private - Only by you'.obs;
  final RxString profileVisibility = 'Follower only'.obs;

  final Rxn<File> profileImageFile = Rxn<File>();
  final Rxn<File> coverImageFile = Rxn<File>();

  final List<String> privacyOptions = [
    'Private - Only by you',
    'Family - Your family circle',
    'Public - Everyone',
  ];

  final List<String> visibilityOptions = [
    'Public - Anyone can view',
    'Follower only',
  ];

  final displayNameController = TextEditingController(text: 'John Anderson');
  final professionController = TextEditingController(
    text: 'Technology Executive & Mentor',
  );
  final locationController = TextEditingController(text: 'San Francisco, CA');
  final birthDateController = TextEditingController(text: 'Feb-03-1980');
  final bioController = TextEditingController(
    text:
        'Technology executive with 25 years of experience building products that matter. Passionate about mentorship and preserving wisdom for the next generation.',
  );
  final lifeMottoController = TextEditingController(
    text:
        'The best time to plant a tree was 20 years ago. The second best time is now.',
  );

  final RxList<String> expertise = <String>[
    'Leadership',
    'IT',
    'Entrepreneurship',
  ].obs;
  final expertiseInputController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    isBiometricEnabled.value = _biometricService.isBiometricEnabled();
    _loadBiometricType();
    _hydrateFromCurrentUser();
    _loadProfileFromBackend();
    _bindProfileListeners();
  }

  Future<void> _loadBiometricType() async {
    biometricType.value = await _biometricService.getBiometricType();
  }

  void _hydrateFromCurrentUser() {
    if (!Get.isRegistered<AuthController>()) {
      return;
    }

    final authController = Get.find<AuthController>();
    final user = authController.firebaseUser.value;

    if (user != null && (user.displayName?.trim().isNotEmpty ?? false)) {
      displayNameController.text = user.displayName!.trim();
    }
  }

  Future<void> _loadProfileFromBackend() async {
    try {
      final profile = await _profileService.fetchMyProfile();
      if (profile == null) {
        return;
      }

      displayNameController.text =
          profile['displayName']?.toString() ?? displayNameController.text;
      professionController.text =
          profile['profession']?.toString() ?? professionController.text;
      locationController.text =
          profile['location']?.toString() ?? locationController.text;
      birthDateController.text =
          profile['birthDate']?.toString() ?? birthDateController.text;
      bioController.text = profile['bio']?.toString() ?? bioController.text;
      lifeMottoController.text =
          profile['lifeMotto']?.toString() ?? lifeMottoController.text;

      final expertiseList = profile['expertise'];
      if (expertiseList is List) {
        expertise.assignAll(
          expertiseList
              .map((item) => item?.toString() ?? '')
              .where((item) => item.isNotEmpty)
              .toList(),
        );
      }

      final privacy = profile['defaultEntryPrivacy']?.toString();
      if (privacy != null && privacy.isNotEmpty) {
        defaultEntryPrivacy.value = privacy;
      }

      final visibility = profile['profileVisibility']?.toString();
      if (visibility != null && visibility.isNotEmpty) {
        profileVisibility.value = visibility;
      }
    } catch (_) {
      // Settings can still render from local/auth state if backend profile load fails.
    }
  }

  void _bindProfileListeners() {
    final controllers = [
      displayNameController,
      professionController,
      locationController,
      birthDateController,
      bioController,
      lifeMottoController,
    ];

    for (final controller in controllers) {
      controller.addListener(_notifyProfileChanged);
    }
  }

  void _notifyProfileChanged() {
    profileRevision.value++;
  }

  String get profileInitials {
    final name = displayNameController.text.trim();
    if (name.isEmpty) {
      return 'SO';
    }

    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  double get profileCompletion {
    final fields = [
      displayNameController.text.trim(),
      professionController.text.trim(),
      locationController.text.trim(),
      birthDateController.text.trim(),
      bioController.text.trim(),
      lifeMottoController.text.trim(),
    ];

    var completed = fields.where((value) => value.isNotEmpty).length;
    if (expertise.isNotEmpty) {
      completed++;
    }
    if (profileImageFile.value != null) {
      completed++;
    }
    if (coverImageFile.value != null) {
      completed++;
    }

    return completed / 8;
  }

  void setProfileImage(File file) {
    profileImageFile.value = file;
    _notifyProfileChanged();
  }

  void setCoverImage(File file) {
    coverImageFile.value = file;
    _notifyProfileChanged();
  }

  void setDefaultEntryPrivacy(String value) {
    defaultEntryPrivacy.value = value;
  }

  void setProfileVisibility(String value) {
    profileVisibility.value = value;
  }

  Future<void> toggleBiometrics(bool value) async {
    final AuthController authController = Get.find<AuthController>();

    if (value) {
      final deviceSupported = await _biometricService.isDeviceSupported();
      if (!deviceSupported) {
        isBiometricEnabled.value = false;
        Get.snackbar(
          'Not Supported',
          'Biometric authentication is not supported on this device.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.1),
        );
        return;
      }

      if (authController.sessionEmail == null ||
          authController.sessionPassword == null) {
        isBiometricEnabled.value = false;
        Get.snackbar(
          'Manual Login Required',
          'For security, please log out and log in manually once to enable biometrics.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
          duration: const Duration(seconds: 5),
        );
        return;
      }

      final authenticated = await _biometricService.authenticate();
      if (authenticated) {
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
          backgroundColor: Colors.green.withValues(alpha: 0.1),
        );
      } else {
        isBiometricEnabled.value = false;
        Get.snackbar(
          'Authentication Failed',
          'Biometric authentication was cancelled or failed. Please ensure Face ID/Touch ID is properly set up on your device.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.1),
        );
      }
    } else {
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
    final normalized = value.trim();
    if (normalized.isNotEmpty && !expertise.contains(normalized)) {
      expertise.add(normalized);
      expertiseInputController.clear();
      _notifyProfileChanged();
    }
  }

  void removeExpertise(String value) {
    expertise.remove(value);
    _notifyProfileChanged();
  }

  Future<void> saveChanges() async {
    try {
      isSavingProfile.value = true;

      final user = FirebaseAuth.instance.currentUser;
      final updatedName = displayNameController.text.trim();

      if (user != null &&
          updatedName.isNotEmpty &&
          user.displayName != updatedName) {
        await user.updateDisplayName(updatedName);
        await user.reload();
      }

      if (Get.isRegistered<AuthController>()) {
        final authController = Get.find<AuthController>();
        authController.firebaseUser.value = FirebaseAuth.instance.currentUser;
      }

      await _profileService.updateProfile({
        'displayName': updatedName,
        'profession': professionController.text.trim(),
        'location': locationController.text.trim(),
        'birthDate': birthDateController.text.trim(),
        'bio': bioController.text.trim(),
        'lifeMotto': lifeMottoController.text.trim(),
        'expertise': expertise.toList(),
        'defaultEntryPrivacy': defaultEntryPrivacy.value,
        'profileVisibility': profileVisibility.value,
        'profileCompleted': true,
        'onboardingCompleted': true,
      });

      Get.snackbar(
        'Profile Updated',
        'Your profile details have been saved successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.1),
      );
    } catch (error) {
      Get.snackbar(
        'Save Failed',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
      );
    } finally {
      isSavingProfile.value = false;
    }
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
