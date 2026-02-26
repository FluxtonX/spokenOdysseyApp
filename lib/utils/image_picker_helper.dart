import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/theme.dart';

/// Shared helper for picking images with proper runtime permission handling.
class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Request camera permission at runtime. Returns true if granted.
  static Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    final result = await Permission.camera.request();
    if (result.isPermanentlyDenied) {
      _showSettingsDialog('Camera');
      return false;
    }
    return result.isGranted;
  }

  /// Request storage/photos permission at runtime. Returns true if granted.
  static Future<bool> _requestGalleryPermission() async {
    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted || status.isLimited;
    }

    // Android
    // On Android 13+ (API 33), Permission.photos handles READ_MEDIA_IMAGES.
    // On older versions, Permission.storage handles READ_EXTERNAL_STORAGE.
    // Modern Android often uses a system picker that needs no permissions.
    
    // Try requesting photos (Android 13+)
    final photoStatus = await Permission.photos.request();
    if (photoStatus.isGranted || photoStatus.isLimited) return true;

    // Try requesting storage (Android < 13)
    final storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) return true;

    // Only block and show settings if permanently denied
    if (photoStatus.isPermanentlyDenied && storageStatus.isPermanentlyDenied) {
      _showSettingsDialog('Gallery');
      return false;
    }

    // If just denied (not permanently) or not applicable, let image_picker try.
    // System picker on Android 13+ often works without permissions.
    return true;
  }

  /// Show dialog prompting user to open app settings
  static void _showSettingsDialog(String feature) {
    Get.dialog(
      AlertDialog(
        title: Text('$feature Permission Required'),
        content: Text(
          '$feature access was permanently denied. Please open Settings and grant permission manually.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Pick image from camera with permission check
  static Future<File?> pickFromCamera({
    CameraDevice preferredCamera = CameraDevice.rear,
    int imageQuality = 85,
    double maxWidth = 1200,
  }) async {
    final hasPermission = await _requestCameraPermission();
    if (!hasPermission) return null;

    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: preferredCamera,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
      );
      if (picked != null) return File(picked.path);
    } catch (e) {
      Get.snackbar(
        'Camera Error',
        'Could not open camera. Please try again.',
        backgroundColor: AppTheme.error.withValues(alpha: 0.1),
        colorText: AppTheme.error,
        margin: const EdgeInsets.all(20),
        snackPosition: SnackPosition.TOP,
      );
    }
    return null;
  }

  /// Pick image from gallery with permission check
  static Future<File?> pickFromGallery({
    int imageQuality = 85,
    double maxWidth = 1200,
  }) async {
    final hasPermission = await _requestGalleryPermission();
    if (!hasPermission) return null;

    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
      );
      if (picked != null) return File(picked.path);
    } catch (e) {
      Get.snackbar(
        'Gallery Error',
        'Could not open gallery. Please try again.',
        backgroundColor: AppTheme.error.withValues(alpha: 0.1),
        colorText: AppTheme.error,
        margin: const EdgeInsets.all(20),
        snackPosition: SnackPosition.TOP,
      );
    }
    return null;
  }

  /// Show bottom sheet to pick source, then pick image
  static Future<File?> pickWithSourceSheet(
    BuildContext context, {
    int imageQuality = 85,
    double maxWidth = 1200,
  }) async {
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildSourceTile(
                      ctx,
                      Icons.camera_alt_outlined,
                      'Camera',
                      'camera',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSourceTile(
                      ctx,
                      Icons.photo_library_outlined,
                      'Gallery',
                      'gallery',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );

    if (source == null) return null;

    if (source == 'camera') {
      return pickFromCamera(
          imageQuality: imageQuality, maxWidth: maxWidth);
    } else {
      return pickFromGallery(
          imageQuality: imageQuality, maxWidth: maxWidth);
    }
  }

  static Widget _buildSourceTile(
    BuildContext ctx,
    IconData icon,
    String label,
    String value,
  ) {
    return GestureDetector(
      onTap: () => Navigator.pop(ctx, value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.scaffoldBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
