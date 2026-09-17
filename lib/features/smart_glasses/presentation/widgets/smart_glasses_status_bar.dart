import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/glasses_cubit.dart';
import '../cubit/glasses_state.dart';
import '../pages/smart_glasses_settings_page.dart';

class SmartGlassesStatusBar extends StatelessWidget {
  const SmartGlassesStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GlassesCubit, GlassesState>(
      builder: (context, state) {
        final isConnected = state.status == GlassesConnectionStatus.connected;
        final isConnecting = state.status == GlassesConnectionStatus.connecting ||
            state.status == GlassesConnectionStatus.scanning;

        Color iconColor;
        IconData statusIcon;
        String tooltip;

        if (isConnected) {
          iconColor = const Color(0xFF10B981); // Emerald Green
          statusIcon = Icons.bluetooth_connected_rounded;
          tooltip = '${state.connectedDevice?.name ?? "Glasses"} (Connected ${state.connectedDevice?.batteryLevel ?? 88}%)';
        } else if (isConnecting) {
          iconColor = const Color(0xFFF59E0B); // Amber Pulse
          statusIcon = Icons.bluetooth_searching_rounded;
          tooltip = 'Connecting Smart Glasses...';
        } else {
          iconColor = AppColors.textSecondary;
          statusIcon = Icons.bluetooth_disabled_rounded;
          tooltip = 'Smart Glasses Disconnected';
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(
                statusIcon,
                color: iconColor,
                size: 24,
              ),
              tooltip: tooltip,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<GlassesCubit>(),
                      child: const SmartGlassesSettingsPage(isStandalonePage: true),
                    ),
                  ),
                );
              },
            ),
            if (isConnected)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
