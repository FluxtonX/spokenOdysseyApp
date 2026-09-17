import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spokenodyssey/features/smart_glasses/presentation/widgets/smart_glasses_gallery_sheet.dart';
import '../cubit/glasses_cubit.dart';
import '../cubit/glasses_state.dart';
import '../widgets/smart_glasses_permission_dialog.dart';
import '../widgets/smart_glasses_scan_sheet.dart';

class SmartGlassesSettingsPage extends StatelessWidget {
  final bool isStandalonePage;

  const SmartGlassesSettingsPage({super.key, this.isStandalonePage = false});

  @override
  Widget build(BuildContext context) {
    final content = BlocBuilder<GlassesCubit, GlassesState>(
      builder: (context, state) {
        final isConnected = state.status == GlassesConnectionStatus.connected;
        final device = state.connectedDevice;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isConnected
                        ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
                        : [const Color(0xFF1F2937), const Color(0xFF111827)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.headphones_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isConnected
                                    ? (device?.name ?? 'Smart Glasses')
                                    : 'No Glasses Connected',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isConnected
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isConnected ? 'Connected' : 'Disconnected',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isConnected && device != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  device.isCharging
                                      ? Icons.battery_charging_full_rounded
                                      : Icons.battery_5_bar_rounded,
                                  color: const Color(0xFF10B981),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${device.batteryLevel}%',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isConnected
                              ? Colors.redAccent.withValues(alpha: 0.8)
                              : const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: Icon(
                          isConnected
                              ? Icons.bluetooth_disabled_rounded
                              : Icons.bluetooth_searching_rounded,
                        ),
                        label: Text(
                          isConnected
                              ? 'Disconnect Glasses'
                              : 'Scan & Pair Smart Glasses',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        onPressed: () {
                          if (isConnected) {
                            context.read<GlassesCubit>().disconnectDevice();
                          } else {
                            SmartGlassesPermissionDialog.checkAndPrompt(
                              context: context,
                              onGranted: () {
                                context.read<GlassesCubit>().startScan();
                                SmartGlassesScanSheet.show(context);
                              },
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'Device Controls',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),

              // Remote Capture Quick Actions
              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Take Photo',
                        enabled: isConnected,
                        onTap: () {
                          context.read<GlassesCubit>().takePhoto();
                          context.read<GlassesCubit>().importAlbum();
                          SmartGlassesGallerySheet.show(context);
                        },
                      ),
                      _buildActionButton(
                        icon: state.isRecordingVideo
                            ? Icons.stop_circle_rounded
                            : Icons.videocam_rounded,
                        iconColor: state.isRecordingVideo
                            ? Colors.red
                            : const Color(0xFF4F46E5),
                        label: state.isRecordingVideo
                            ? 'Stop Video'
                            : 'Record Video',
                        enabled: isConnected,
                        onTap: () {
                          final wasRecording = state.isRecordingVideo;
                          context.read<GlassesCubit>().toggleVideoRecording();
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                wasRecording
                                    ? '⏹️ Video Recording Stopped! Tap "Import & Play Videos" to sync.'
                                    : '🔴 Video Recording Started on Glasses! Tap again when finished.',
                              ),
                              backgroundColor: wasRecording
                                  ? const Color(0xFF4F46E5)
                                  : Colors.redAccent,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                      ),
                      _buildActionButton(
                        icon: state.isRecordingVoice
                            ? Icons.stop_circle_rounded
                            : Icons.mic_rounded,
                        iconColor: state.isRecordingVoice
                            ? Colors.red
                            : const Color(0xFF4F46E5),
                        label: state.isRecordingVoice
                            ? 'Stop Voice'
                            : 'Voice Note',
                        enabled: isConnected,
                        onTap: () {
                          final wasRecording = state.isRecordingVoice;
                          context.read<GlassesCubit>().toggleVoiceRecording();
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                wasRecording
                                    ? '⏹️ Voice Note Stopped!'
                                    : '🎙️ Voice Note Recording Started on Glasses!',
                              ),
                              backgroundColor: wasRecording
                                  ? const Color(0xFF4F46E5)
                                  : Colors.redAccent,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: isConnected
                          ? const Color(0xFF4F46E5)
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(
                    Icons.download_for_offline_rounded,
                    color: isConnected
                        ? const Color(0xFF4F46E5)
                        : Colors.grey.shade400,
                  ),
                  label: Text(
                    'Import & Play Videos from Glasses',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isConnected
                          ? const Color(0xFF4F46E5)
                          : Colors.grey.shade400,
                    ),
                  ),
                  onPressed: isConnected
                      ? () {
                          SmartGlassesPermissionDialog.checkAndPrompt(
                            context: context,
                            onGranted: () {
                              context.read<GlassesCubit>().importAlbum();
                              SmartGlassesGallerySheet.show(context);
                            },
                          );
                        }
                      : null,
                ),
              ),

              const SizedBox(height: 20),
              Text(
                'Glasses Settings',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),

              // Toggles Card
              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeThumbColor: const Color(0xFF4F46E5),
                      title: Text(
                        'Wearing Detection',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Pause playback automatically when glasses are taken off',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      value: state.wearingDetection,
                      onChanged: isConnected
                          ? (val) => context
                                .read<GlassesCubit>()
                                .toggleWearingDetection(val)
                          : null,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      activeThumbColor: const Color(0xFF4F46E5),
                      title: Text(
                        'Voice Wakeup (Hands-Free)',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Activate AI assistant using "Hey Cyan / Odyssey"',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      value: state.voiceWakeup,
                      onChanged: isConnected
                          ? (val) => context
                                .read<GlassesCubit>()
                                .toggleVoiceWakeup(val)
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Text(
                'Volume & Audio',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),

              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.volume_up_rounded,
                            color: Color(0xFF4F46E5),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Glasses Audio Volume',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${state.musicVolume.toInt()}%',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        activeColor: const Color(0xFF4F46E5),
                        min: 0,
                        max: 100,
                        value: state.musicVolume,
                        onChanged: isConnected
                            ? (val) => context
                                  .read<GlassesCubit>()
                                  .updateMusicVolume(val)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (isStandalonePage) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAF9FD),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1F2937),
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Smart Glasses Studio',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1F2937),
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final activeColor = iconColor ?? const Color(0xFF4F46E5);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: activeColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
