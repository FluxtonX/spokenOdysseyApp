import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/glasses_device.dart';
import '../cubit/glasses_cubit.dart';
import '../cubit/glasses_state.dart';
import 'glasses_visuals.dart';

/// Bottom sheet that scans for, lists and pairs smart glasses.
class SmartGlassesScanSheet extends StatefulWidget {
  const SmartGlassesScanSheet({super.key});

  /// Opens the sheet and starts scanning.
  static Future<void> show(BuildContext context) {
    final cubit = context.read<GlassesCubit>();
    if (!cubit.state.isScanning) cubit.startScan();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const SmartGlassesScanSheet(),
      ),
    );
  }

  @override
  State<SmartGlassesScanSheet> createState() => _SmartGlassesScanSheetState();
}

class _SmartGlassesScanSheetState extends State<SmartGlassesScanSheet> {
  late final GlassesCubit _cubit;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    // Capture the cubit while the widget is active. Reading it lazily (or in
    // dispose) can hit a deactivated widget and throw
    // "Looking up a deactivated widget's ancestor is unsafe".
    _cubit = context.read<GlassesCubit>();
  }

  @override
  void dispose() {
    if (_cubit.state.isScanning) _cubit.stopScan();
    super.dispose();
  }

  void _closeAfterSuccess() {
    if (_closing) return;
    _closing = true;
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.86;
    return BlocConsumer<GlassesCubit, GlassesState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.isConnected) _closeAfterSuccess();
      },
      builder: (context, state) {
        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _Header(onClose: () => Navigator.of(context).maybePop()),
                  const SizedBox(height: 4),
                  Flexible(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      child: _buildBody(context, state),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, GlassesState state) {
    if (state.isConnected) {
      return _SuccessView(
        key: const ValueKey('success'),
        name: state.connectedDevice?.name ?? 'Smart Glasses',
      );
    }
    if (state.status == GlassesConnectionStatus.permissionRequired) {
      if (Platform.isIOS) {
        // Once declined, iOS never asks again in the app: only Settings can
        // turn Bluetooth access back on. Say exactly where, then wait for it.
        return _StatusPanel(
          key: const ValueKey('permission'),
          icon: Icons.shield_outlined,
          title: 'Allow Bluetooth access',
          message:
              'Bluetooth access is turned off for Spoken Odyssey, so it can\'t find your glasses.',
          steps: const [
            'Tap "Open Settings" below',
            'Turn on the "Bluetooth" switch',
            'Come back here, pairing continues by itself',
          ],
          primaryLabel: 'Open Settings',
          onPrimary: _cubit.openAppSettingsPage,
          secondaryLabel: 'Try again',
          onSecondary: _cubit.startScan,
        );
      }
      return _StatusPanel(
        key: const ValueKey('permission'),
        icon: Icons.shield_outlined,
        title: 'Allow nearby devices',
        message:
            'Spoken Odyssey needs Bluetooth "Nearby devices" access to find and pair your smart glasses.',
        primaryLabel: 'Open Settings',
        onPrimary: _cubit.openAppSettingsPage,
        secondaryLabel: 'Try again',
        onSecondary: _cubit.startScan,
      );
    }
    if (state.status == GlassesConnectionStatus.bluetoothUnavailable) {
      return _StatusPanel(
        key: const ValueKey('bt-unavailable'),
        icon: Icons.bluetooth_disabled_rounded,
        title: 'Bluetooth not available',
        message:
            'This device has no Bluetooth (the iOS Simulator can\'t use Bluetooth). Run the app on a real iPhone to pair your glasses.',
        primaryLabel: 'Try again',
        onPrimary: _cubit.startScan,
      );
    }
    if (state.status == GlassesConnectionStatus.bluetoothOff &&
        Platform.isIOS) {
      // iOS doesn't let apps switch Bluetooth on. Guide the user to Control
      // Center (no leaving the app) and start scanning as soon as it's on.
      return _StatusPanel(
        key: const ValueKey('bt-off'),
        icon: Icons.bluetooth_disabled_rounded,
        title: 'Turn on Bluetooth',
        message:
            'Your glasses connect over Bluetooth. Turn it on and pairing starts automatically.',
        steps: const [
          'Swipe down from the top-right corner of the screen',
          'Tap the Bluetooth icon in Control Center',
        ],
        waitingLabel: 'Waiting for Bluetooth…',
        primaryLabel: 'Turn on Bluetooth',
        onPrimary: _cubit.enableBluetoothPrompt,
      );
    }
    if (state.status == GlassesConnectionStatus.bluetoothOff) {
      return _StatusPanel(
        key: const ValueKey('bt-off'),
        icon: Icons.bluetooth_disabled_rounded,
        title: 'Bluetooth is off',
        message: 'Turn on Bluetooth so your phone can find your smart glasses.',
        primaryLabel: 'Turn on Bluetooth',
        onPrimary: _cubit.enableBluetoothPrompt,
      );
    }
    if (state.status == GlassesConnectionStatus.error &&
        state.discoveredDevices.isEmpty) {
      return _StatusPanel(
        key: const ValueKey('error'),
        icon: Icons.link_off_rounded,
        title: 'Connection failed',
        message: state.errorMessage.isNotEmpty
            ? state.errorMessage
            : 'Something went wrong. Please try again.',
        primaryLabel: 'Scan again',
        onPrimary: _cubit.startScan,
      );
    }
    return _ScanView(key: const ValueKey('scan'), state: state);
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;

  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pair your glasses',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Keep them powered on and close to your phone',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Close',
          onPressed: onClose,
          style: IconButton.styleFrom(backgroundColor: AppColors.surface),
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

class _ScanView extends StatelessWidget {
  final GlassesState state;

  const _ScanView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GlassesCubit>();
    final devices = state.discoveredDevices;
    final scanning = state.isScanning;
    final hasDevices = devices.isNotEmpty;

    String headline;
    if (state.isConnecting) {
      headline = 'Connecting…';
    } else if (scanning) {
      headline = hasDevices
          ? 'Found ${devices.length} nearby ${devices.length == 1 ? 'device' : 'devices'}'
          : 'Searching for glasses…';
    } else {
      headline = hasDevices ? 'Select your glasses' : 'No glasses found';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          height: hasDevices ? 130 : 220,
          alignment: Alignment.center,
          child: GlassesScanningRadar(
            size: hasDevices ? 120 : 200,
            active: scanning || state.isConnecting,
          ),
        ),
        Text(
          headline,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        if (state.errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
              state.errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 13, color: AppColors.error),
            ),
          )
        else if (!hasDevices)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              scanning
                  ? 'Make sure your glasses are switched on and not connected to another phone.'
                  : 'Turn the glasses off and on again, keep them nearby, then scan again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        const SizedBox(height: 12),
        if (hasDevices)
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: devices.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _DeviceTile(
                device: devices[i],
                connecting:
                    state.isConnecting &&
                    state.connectingAddress == devices[i].address,
                disabled: state.isConnecting,
                onConnect: () => cubit.connectDevice(
                  devices[i].address,
                  name: devices[i].name,
                ),
              ),
            ),
          ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: scanning
              ? OutlinedButton(
                  onPressed: cubit.stopScan,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.borderLight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Stop scanning',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                )
              : FilledButton.icon(
                  onPressed: state.isConnecting ? null : cubit.startScan,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.radar_rounded),
                  label: Text(
                    'Scan again',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                ),
        ),
      ],
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final GlassesDevice device;
  final bool connecting;
  final bool disabled;
  final VoidCallback onConnect;

  const _DeviceTile({
    required this.device,
    required this.connecting,
    required this.disabled,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final highlight = device.isLikelyGlasses;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 12),
          child: child,
        ),
      ),
      child: Material(
        color: highlight ? const Color(0xFFF5F2FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: disabled ? null : onConnect,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: connecting
                    ? AppColors.primary
                    : highlight
                    ? AppColors.primary.withValues(alpha: 0.25)
                    : AppColors.borderLight,
                width: connecting ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: highlight ? AppColors.primaryGradient : null,
                    color: highlight ? null : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: highlight
                      ? const GlassesGlyph(size: 28)
                      : const Icon(
                          Icons.bluetooth_rounded,
                          color: AppColors.textSecondary,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              device.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (highlight) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Glasses',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          SignalBars(level: device.signalLevel),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              device.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppColors.textLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: connecting
                      ? const SizedBox(
                          key: ValueKey('spin'),
                          width: 72,
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        )
                      : FilledButton(
                          key: const ValueKey('btn'),
                          onPressed: disabled ? null : onConnect,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(72, 38),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Connect',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// Numbered instructions shown under the message.
  final List<String> steps;

  /// Shown with a spinner while the app waits for the user to act.
  final String? waitingLabel;

  const _StatusPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.steps = const [],
    this.waitingLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 38, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 16),
            _StepsCard(steps: steps),
          ],
          if (waitingLabel != null) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  waitingLabel!,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: onPrimary,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                primaryLabel,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (secondaryLabel != null) ...[
            const SizedBox(height: 6),
            TextButton(
              onPressed: onSecondary,
              child: Text(
                secondaryLabel!,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  final List<String> steps;

  const _StepsCard({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String name;

  const _SuccessView({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (_, s, child) => Transform.scale(scale: s, child: child),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Connected',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
