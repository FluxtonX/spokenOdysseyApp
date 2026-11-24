import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

class SmartGlassesPermissionDialog extends StatelessWidget {
  final VoidCallback onPermissionsGranted;

  const SmartGlassesPermissionDialog({super.key, required onPermissionsGranted})
    : onPermissionsGranted = onPermissionsGranted;

  /// Permissions that gate pairing. iOS only has a single Bluetooth
  /// permission (CoreBluetooth needs no location); the Android 12+
  /// `bluetoothScan`/`bluetoothConnect` permissions don't exist there and
  /// always report "permanently denied", so they must never be asked on iOS.
  static List<Permission> get _requiredPermissions => Platform.isIOS
      ? [Permission.bluetooth]
      : [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.locationWhenInUse,
        ];

  static Future<bool> checkAndPrompt({
    required BuildContext context,
    required VoidCallback onGranted,
  }) async {
    final needed = _requiredPermissions;
    final current = await Future.wait(needed.map((p) => p.status));
    if (current.every((s) => s.isGranted)) {
      onGranted();
      return true;
    }

    // Show custom explanation dialog first before opening system prompt
    if (!context.mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => SmartGlassesPermissionDialog(
        onPermissionsGranted: () async {
          Navigator.pop(dialogCtx, true);
          if (await _requestRequired()) onGranted();
        },
      ),
    );

    return result ?? false;
  }

  static Future<bool> _requestRequired() async {
    if (Platform.isIOS) {
      final status = await Permission.bluetooth.request();
      if (status.isGranted) return true;
      // Once denied, iOS never shows the system prompt again.
      if (status.isPermanentlyDenied || status.isRestricted) {
        await openAppSettings();
      }
      return false;
    }

    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
      Permission.nearbyWifiDevices,
    ].request();

    if (statuses[Permission.bluetoothScan]?.isPermanentlyDenied == true ||
        statuses[Permission.bluetoothConnect]?.isPermanentlyDenied == true ||
        statuses[Permission.locationWhenInUse]?.isPermanentlyDenied == true) {
      await openAppSettings();
      return false;
    }
    return statuses[Permission.bluetoothScan]?.isGranted == true &&
        statuses[Permission.bluetoothConnect]?.isGranted == true;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bluetooth_audio_rounded,
                  color: Color(0xFF4F46E5),
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Smart Glasses Permissions',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              Platform.isIOS
                  ? 'Spoken Odyssey needs Bluetooth access to discover, connect, and import videos from your Smart Glasses.'
                  : 'Spoken Odyssey needs Bluetooth & Location access to discover, connect, and import videos from your Smart Glasses.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            _buildPermissionItem(
              icon: Icons.bluetooth_searching_rounded,
              title: 'Bluetooth & Nearby Devices',
              subtitle: 'To scan, pair, and communicate with glasses.',
            ),
            if (!Platform.isIOS) ...[
              const SizedBox(height: 12),
              _buildPermissionItem(
                icon: Icons.wifi_protected_setup_rounded,
                title: 'Location & Wi-Fi Direct',
                subtitle: 'To transfer high-definition videos from glasses.',
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF4F46E5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onPermissionsGranted,
                    child: Text(
                      'Allow Access',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF4F46E5), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: const Color(0xFF1F2937),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
