import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

class SmartGlassesPermissionDialog extends StatelessWidget {
  final VoidCallback onPermissionsGranted;

  const SmartGlassesPermissionDialog({
    super.key,
    required onPermissionsGranted,
  }) : onPermissionsGranted = onPermissionsGranted;

  static Future<bool> checkAndPrompt({
    required BuildContext context,
    required VoidCallback onGranted,
  }) async {
    // Check if permissions are already granted
    final btScan = await Permission.bluetoothScan.status;
    final btConnect = await Permission.bluetoothConnect.status;
    final location = await Permission.locationWhenInUse.status;

    if (btScan.isGranted && btConnect.isGranted && location.isGranted) {
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

          // Request permissions via system prompt
          Map<Permission, PermissionStatus> statuses = await [
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
            Permission.locationWhenInUse,
            Permission.nearbyWifiDevices,
          ].request();

          bool allGranted = true;
          if (statuses[Permission.bluetoothScan]?.isPermanentlyDenied == true ||
              statuses[Permission.bluetoothConnect]?.isPermanentlyDenied == true ||
              statuses[Permission.locationWhenInUse]?.isPermanentlyDenied == true) {
            allGranted = false;
            openAppSettings();
          } else if (statuses[Permission.bluetoothScan]?.isGranted != true ||
              statuses[Permission.bluetoothConnect]?.isGranted != true) {
            allGranted = false;
          }

          if (allGranted) {
            onGranted();
          }
        },
      ),
    );

    return result ?? false;
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
              'Spoken Odyssey needs Bluetooth & Location access to discover, connect, and import videos from your Smart Glasses.',
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
            const SizedBox(height: 12),
            _buildPermissionItem(
              icon: Icons.wifi_protected_setup_rounded,
              title: 'Location & Wi-Fi Direct',
              subtitle: 'To transfer high-definition videos from glasses.',
            ),
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
