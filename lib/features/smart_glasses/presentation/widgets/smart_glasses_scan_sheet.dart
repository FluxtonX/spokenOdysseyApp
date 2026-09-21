import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/app_ui.dart';
import '../cubit/glasses_cubit.dart';
import '../cubit/glasses_state.dart';

class SmartGlassesScanSheet extends StatelessWidget {
  const SmartGlassesScanSheet({super.key});

  static void show(BuildContext context) {
    context.read<GlassesCubit>().startScan();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<GlassesCubit>(),
        child: const SmartGlassesScanSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bluetooth_searching_rounded,
                  color: Color(0xFF4F46E5),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pair Smart Glasses',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    BlocBuilder<GlassesCubit, GlassesState>(
                      builder: (context, state) {
                        String subtitle = 'Searching for nearby glasses...';
                        if (state.status ==
                            GlassesConnectionStatus.permissionRequired) {
                          subtitle = 'Bluetooth permission required';
                        } else if (state.status ==
                            GlassesConnectionStatus.bluetoothOff) {
                          subtitle = 'Bluetooth is turned off';
                        }
                        return Text(
                          subtitle,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: const Color(0xFF6B7280),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              AppIconButton(
                icon: Icons.close_rounded,
                label: 'Close pairing',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          BlocBuilder<GlassesCubit, GlassesState>(
            builder: (context, state) {
              if (state.status == GlassesConnectionStatus.permissionRequired) {
                return _buildStatusBanner(
                  context,
                  icon: Icons.security_rounded,
                  title: 'Bluetooth & Location Permission Required',
                  description:
                      'Spoken Odyssey needs Bluetooth access to discover and pair with your Smart Glasses.',
                  buttonLabel: 'Allow Permission in Settings',
                  onTap: () {
                    context.read<GlassesCubit>().openAppSettingsPage();
                  },
                );
              }

              if (state.status == GlassesConnectionStatus.bluetoothOff) {
                return _buildStatusBanner(
                  context,
                  icon: Icons.bluetooth_disabled_rounded,
                  title: 'Bluetooth is Turned Off',
                  description:
                      'Please turn on Bluetooth to discover and connect with your Smart Glasses.',
                  buttonLabel: 'Turn On Bluetooth',
                  onTap: () {
                    context.read<GlassesCubit>().enableBluetoothPrompt();
                  },
                );
              }

              if (state.discoveredDevices.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF4F46E5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ensure your glasses are turned on and nearby',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                itemCount: state.discoveredDevices.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final device = state.discoveredDevices[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.headphones_rounded,
                        color: Color(0xFF374151),
                      ),
                    ),
                    title: Text(
                      device.name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      device.address,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                    trailing: AppButton(
                      expand: false,
                      label: 'Connect',
                      variant: AppButtonVariant.primary,
                      onPressed: () {
                        context.read<GlassesCubit>().connectDevice(
                          device.address,
                        );
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF4F46E5), size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: onTap,
                child: Text(
                  buttonLabel,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
