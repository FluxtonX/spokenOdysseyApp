import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/glasses_media_item.dart';
import '../cubit/glasses_cubit.dart';
import '../cubit/glasses_state.dart';
import '../widgets/glasses_import_banner.dart';
import '../widgets/glasses_media_tile.dart';
import '../widgets/glasses_visuals.dart';
import '../widgets/smart_glasses_permission_dialog.dart';
import '../widgets/smart_glasses_scan_sheet.dart';
import 'smart_glasses_device_settings_page.dart';
import 'smart_glasses_media_page.dart';
import 'smart_glasses_media_viewer.dart';

/// Smart Glasses Studio: pairing, capture controls, imported media and settings.
class SmartGlassesSettingsPage extends StatelessWidget {
  final bool isStandalonePage;

  const SmartGlassesSettingsPage({super.key, this.isStandalonePage = false});

  static void openPairing(BuildContext context) {
    SmartGlassesPermissionDialog.checkAndPrompt(
      context: context,
      onGranted: () {
        if (context.mounted) SmartGlassesScanSheet.show(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = BlocListener<GlassesCubit, GlassesState>(
      listenWhen: (a, b) => a.noticeId != b.noticeId && b.notice.isNotEmpty,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              content: Text(state.notice, style: GoogleFonts.outfit()),
            ),
          );
      },
      child: BlocBuilder<GlassesCubit, GlassesState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DeviceHeroCard(state: state),
              const GlassesImportBanner(margin: EdgeInsets.only(top: 16)),
              const SizedBox(height: 24),
              const GlassesSectionHeader(title: 'Capture'),
              _CaptureRow(state: state),
              const SizedBox(height: 24),
              GlassesSectionHeader(
                title: 'Glasses Library',
                actionLabel: 'See all',
                onAction: () => SmartGlassesMediaPage.open(context),
              ),
              _LibraryCard(state: state),
              if (!state.isConnected) ...[
                const SizedBox(height: 24),
                const GlassesSectionHeader(title: 'How to pair'),
                const _PairingGuide(),
              ],
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );

    if (!isStandalonePage) return content;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.surface,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Text(
          'Smart Glasses Studio',
          style: GoogleFonts.outfit(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Tooltip(
              message: 'Settings',
              child: Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFEEEBFA)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => SmartGlassesDeviceSettingsPage.open(context),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.tune_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          final cubit = context.read<GlassesCubit>();
          await cubit.loadLocalMedia();
          await cubit.refreshPendingMedia();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: content,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Device hero card
// ─────────────────────────────────────────────────────────────────────────────
class _DeviceHeroCard extends StatelessWidget {
  final GlassesState state;

  const _DeviceHeroCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final connected = state.isConnected;
    final busy = state.isScanning || state.isConnecting;
    final device = state.connectedDevice;

    final (title, statusLabel, statusColor) = switch (state.status) {
      GlassesConnectionStatus.connected => (
        device?.name ?? 'Smart Glasses',
        'Connected · ${state.activityLabel}',
        AppColors.success,
      ),
      GlassesConnectionStatus.connecting => (
        'Connecting…',
        'Pairing in progress',
        AppColors.warning,
      ),
      GlassesConnectionStatus.scanning => (
        'Looking for glasses',
        'Scanning nearby',
        AppColors.warning,
      ),
      GlassesConnectionStatus.bluetoothOff => (
        'Bluetooth is off',
        'Turn on Bluetooth',
        AppColors.error,
      ),
      GlassesConnectionStatus.bluetoothUnavailable => (
        'Bluetooth unavailable',
        'Use a real device',
        AppColors.error,
      ),
      GlassesConnectionStatus.permissionRequired => (
        'Permission needed',
        'Allow nearby devices',
        AppColors.error,
      ),
      GlassesConnectionStatus.error => (
        'Couldn\'t connect',
        'Try again',
        AppColors.error,
      ),
      GlassesConnectionStatus.disconnected => (
        'No glasses connected',
        'Disconnected',
        const Color(0xFFB4B0CC),
      ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: connected
              ? const [Color(0xFF6B4AFF), Color(0xFF4825E2), Color(0xFF2C0FBB)]
              : const [Color(0xFF1E1A3F), Color(0xFF2B2160), Color(0xFF3A2A8C)],
        ),
        boxShadow: [
          BoxShadow(
            color: (connected ? AppColors.primary : const Color(0xFF1E1A3F))
                .withValues(alpha: 0.32),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -50,
            child: _HeroOrb(size: 180, opacity: 0.07),
          ),
          Positioned(
            right: 30,
            bottom: -70,
            child: _HeroOrb(size: 140, opacity: 0.05),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 84,
                    height: 84,
                    child: busy
                        ? const GlassesScanningRadar(
                            size: 84,
                            color: Colors.white,
                          )
                        : Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const GlassesGlyph(size: 46),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            title,
                            key: ValueKey(title),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            PulseDot(
                              color: statusColor,
                              pulsing: busy || connected,
                              size: 8,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                statusLabel,
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (connected && device != null) ...[
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (device.hasBatteryInfo)
                      BatteryPill(
                        level: device.batteryLevel,
                        charging: device.isCharging,
                      ),
                    _HeroChip(
                      icon: state.audio.isConnected
                          ? Icons.headphones_rounded
                          : Icons.bluetooth_connected_rounded,
                      label: state.audio.isConnected
                          ? 'Sound on glasses'
                          : 'Bluetooth',
                    ),
                    if (device.firmwareVersion.isNotEmpty)
                      _HeroChip(
                        icon: Icons.memory_rounded,
                        label: 'v${device.firmwareVersion}',
                      ),
                  ],
                ),
              ],
              if (!connected && state.errorMessage.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.errorMessage,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (!connected) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: state.isConnecting
                        ? null
                        : () => SmartGlassesSettingsPage.openPairing(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      disabledBackgroundColor: Colors.white.withValues(
                        alpha: 0.2,
                      ),
                      disabledForegroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: state.isConnecting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.bluetooth_searching_rounded),
                    label: Text(
                      state.isConnecting
                          ? 'Connecting…'
                          : state.isScanning
                          ? 'View nearby glasses'
                          : 'Pair smart glasses',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroOrb extends StatelessWidget {
  final double size;
  final double opacity;

  const _HeroOrb({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Capture controls
// ─────────────────────────────────────────────────────────────────────────────
class _CaptureRow extends StatelessWidget {
  final GlassesState state;

  const _CaptureRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GlassesCubit>();
    final enabled = state.canCapture;
    final pending = state.pendingCommand;
    return Row(
      children: [
        Expanded(
          child: _CaptureTile(
            icon: Icons.photo_camera_rounded,
            label: 'Photo',
            caption: state.cameraSettings.photoResolution.label,
            enabled: enabled && !state.isRecording,
            busy: pending == GlassesPendingCommand.photo,
            onTap: cubit.takePhoto,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CaptureTile(
            icon: Icons.videocam_rounded,
            activeIcon: Icons.stop_rounded,
            label: 'Video',
            caption:
                '${state.cameraSettings.videoResolution.label} · ${state.cameraSettings.durationLimit.label}',
            active: state.isRecordingVideo,
            startedAt: state.isRecordingVideo ? state.recordingStartedAt : null,
            enabled: enabled && !state.isRecordingVoice,
            busy: pending == GlassesPendingCommand.video,
            onTap: cubit.toggleVideoRecording,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CaptureTile(
            icon: Icons.mic_rounded,
            activeIcon: Icons.stop_rounded,
            label: 'Voice',
            caption: 'Record',
            active: state.isRecordingVoice,
            startedAt: state.isRecordingVoice ? state.recordingStartedAt : null,
            enabled: enabled && !state.isRecordingVideo,
            busy: pending == GlassesPendingCommand.audio,
            onTap: cubit.toggleVoiceRecording,
          ),
        ),
      ],
    );
  }
}

class _CaptureTile extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final String caption;
  final bool enabled;
  final bool active;
  final DateTime? startedAt;
  final VoidCallback onTap;
  final bool busy;

  const _CaptureTile({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.caption,
    required this.enabled,
    required this.onTap,
    this.active = false,
    this.startedAt,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    // A running recording can always be stopped, unless a command is already waiting.
    final canTap =
        !busy &&
        (enabled ||
            (active &&
                context.select<GlassesCubit, bool>(
                  (c) => c.state.pendingCommand == null && c.state.isConnected,
                )));
    return Semantics(
      button: true,
      enabled: canTap,
      label: active ? 'Stop $label recording' : label,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: canTap ? 1 : 0.45,
        child: Material(
          color: active ? const Color(0xFFFFF1F1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: canTap ? onTap : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? AppColors.error.withValues(alpha: 0.4)
                      : const Color(0xFFEEEBFA),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A1B0F5C),
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (active)
                        const PulseDot(
                          color: AppColors.error,
                          pulsing: true,
                          size: 22,
                        ),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: active ? null : AppColors.primaryGradient,
                          color: active ? AppColors.error : null,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (active ? AppColors.error : AppColors.primary)
                                      .withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: busy
                            ? const Padding(
                                padding: EdgeInsets.all(15),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                active ? (activeIcon ?? icon) : icon,
                                color: Colors.white,
                                size: 24,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  busy
                      ? Text(
                          'Waiting…',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : active && startedAt != null
                      ? _ElapsedTimer(startedAt: startedAt!)
                      : Text(
                          caption,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ElapsedTimer extends StatefulWidget {
  final DateTime startedAt;

  const _ElapsedTimer({required this.startedAt});

  @override
  State<_ElapsedTimer> createState() => _ElapsedTimerState();
}

class _ElapsedTimerState extends State<_ElapsedTimer> {
  late final Timer _timer = Timer.periodic(
    const Duration(seconds: 1),
    (_) => setState(() {}),
  );

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = DateTime.now().difference(widget.startedAt).inSeconds;
    return Text(
      formatGlassesDuration(seconds),
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.error,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Library summary
// ─────────────────────────────────────────────────────────────────────────────
class _LibraryCard extends StatelessWidget {
  final GlassesState state;

  const _LibraryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final media = state.importedMedia;
    final recent = media.take(4).toList();
    final pending = state.pendingMedia;

    return GlassesCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CountChip(
                icon: Icons.photo_rounded,
                count: state.photos.length,
                label: 'Photos',
              ),
              const SizedBox(width: 8),
              _CountChip(
                icon: Icons.videocam_rounded,
                count: state.videos.length,
                label: 'Videos',
              ),
              const SizedBox(width: 8),
              _CountChip(
                icon: Icons.mic_rounded,
                count: state.audios.length,
                label: 'Audio',
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (recent.isEmpty)
            Container(
              height: 92,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F5FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEEEBFA)),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.primaryLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Imported media will appear here',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                for (int i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: i < recent.length
                          ? _RecentTile(
                              item: recent[i],
                              extra: i == 3 && media.length > 4
                                  ? media.length - 4
                                  : 0,
                              onTap: () => i == 3 && media.length > 4
                                  ? SmartGlassesMediaPage.open(context)
                                  : SmartGlassesMediaViewer.open(
                                      context,
                                      items: media,
                                      initialIndex: i,
                                    ),
                            )
                          : DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F5FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          if (state.isConnected && pending != null && pending.total > 0) ...[
            const SizedBox(height: 14),
            _PendingNotice(pending: pending),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: state.isConnected && !state.isImporting
                  ? () => SmartGlassesMediaPage.open(context, startImport: true)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.indicatorInactive,
                disabledForegroundColor: AppColors.primaryLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(
                state.isImporting
                    ? Icons.downloading_rounded
                    : Icons.download_rounded,
              ),
              label: Text(
                state.isImporting
                    ? 'Importing…'
                    : state.isConnected
                    ? 'Import from glasses'
                    : 'Connect glasses to import',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  final GlassesMediaItem item;
  final int extra;
  final VoidCallback onTap;

  const _RecentTile({
    required this.item,
    required this.extra,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GlassesMediaTile(item: item, radius: 12, onTap: onTap),
        if (extra > 0)
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                '+$extra',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;

  const _CountChip({
    required this.icon,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F5FF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingNotice extends StatelessWidget {
  final GlassesPendingMedia pending;

  const _PendingNotice({required this.pending});

  @override
  Widget build(BuildContext context) {
    final parts = [
      if (pending.images > 0)
        '${pending.images} photo${pending.images == 1 ? '' : 's'}',
      if (pending.videos > 0)
        '${pending.videos} video${pending.videos == 1 ? '' : 's'}',
      if (pending.audio > 0)
        '${pending.audio} voice note${pending.audio == 1 ? '' : 's'}',
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.fiber_new_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${parts.join(', ')} waiting on your glasses',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pairing guide
// ─────────────────────────────────────────────────────────────────────────────
class _PairingGuide extends StatelessWidget {
  const _PairingGuide();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (
        Icons.power_settings_new_rounded,
        'Turn on your glasses',
        'Charge them if the battery is low.',
      ),
      (
        Icons.bluetooth_rounded,
        'Keep Bluetooth on',
        'Stay within 1–2 metres of your phone.',
      ),
      (
        Icons.touch_app_rounded,
        'Tap "Pair smart glasses"',
        'Pick your glasses from the list.',
      ),
    ];
    return GlassesCard(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        children: [
          for (int i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      steps[i].$1,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${i + 1}. ${steps[i].$2}',
                          style: GoogleFonts.outfit(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          steps[i].$3,
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
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
