import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/glasses_device_settings.dart';
import '../cubit/glasses_cubit.dart';
import '../cubit/glasses_state.dart';
import '../widgets/glasses_audio_card.dart';
import '../widgets/glasses_camera_settings_card.dart';
import '../widgets/glasses_visuals.dart';

/// Settings that live on the glasses: features, audio, tools and device info.
class SmartGlassesDeviceSettingsPage extends StatefulWidget {
  const SmartGlassesDeviceSettingsPage({super.key});

  static Future<void> open(BuildContext context) {
    final cubit = context.read<GlassesCubit>();
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const SmartGlassesDeviceSettingsPage(),
        ),
      ),
    );
  }

  @override
  State<SmartGlassesDeviceSettingsPage> createState() =>
      _SmartGlassesDeviceSettingsPageState();
}

class _SmartGlassesDeviceSettingsPageState
    extends State<SmartGlassesDeviceSettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<GlassesCubit>().loadDeviceSettings();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
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
            'Settings',
            style: GoogleFonts.outfit(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(62),
            child: _SettingsTabs(),
          ),
        ),
        body: BlocConsumer<GlassesCubit, GlassesState>(
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
          builder: (context, state) {
            return TabBarView(
              children: [
                _TabScroll(
                  children: const [
                    GlassesCameraSettingsCard(showHeader: false),
                  ],
                ),
                _SoundTab(state: state),
                _DeviceTab(state: state),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Pill-style tab bar with an icon per category.
class _SettingsTabs extends StatelessWidget {
  const _SettingsTabs();

  @override
  Widget build(BuildContext context) {
    const tabs = [
      (Icons.videocam_rounded, 'Camera'),
      (Icons.volume_up_rounded, 'Sound'),
      (Icons.settings_suggest_rounded, 'Device'),
    ];
    return Container(
      height: 48,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A1B0F5C),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelPadding: EdgeInsets.zero,
        splashBorderRadius: BorderRadius.circular(12),
        tabs: [
          for (final (icon, label) in tabs)
            Tab(
              height: 40,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
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

class _TabScroll extends StatelessWidget {
  final List<Widget> children;

  const _TabScroll({required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: children,
    );
  }
}

// ───────────────────────────── Sound tab ─────────────────────────────

class _SoundTab extends StatelessWidget {
  final GlassesState state;

  const _SoundTab({required this.state});

  @override
  Widget build(BuildContext context) {
    if (!state.isConnected) {
      return const _NotConnected(
        message: 'Connect your glasses to manage their sound.',
      );
    }
    final settings = state.deviceSettings;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: context.read<GlassesCubit>().loadDeviceSettings,
      child: _TabScroll(
        children: [
          const GlassesSectionHeader(title: 'Play sound on glasses'),
          const GlassesAudioCard(),
          const SizedBox(height: 24),
          const GlassesSectionHeader(title: 'Volume'),
          if (settings != null && settings.hasVolume)
            _VolumeCard(settings: settings)
          else
            GlassesCard(
              child: _InfoLine(
                icon: state.isSettingsLoading
                    ? Icons.hourglass_top_rounded
                    : Icons.info_outline_rounded,
                text: state.isSettingsLoading
                    ? 'Reading volume from your glasses…'
                    : 'Volume controls aren\'t available. Pull down to try again.',
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Device tab ─────────────────────────────

class _DeviceTab extends StatelessWidget {
  final GlassesState state;

  const _DeviceTab({required this.state});

  @override
  Widget build(BuildContext context) {
    if (!state.isConnected) {
      return const _NotConnected(
        message:
            'Connect your glasses to see and change their device settings.',
      );
    }
    final settings = state.deviceSettings;
    if (settings == null) {
      return state.isSettingsLoading
          ? const _LoadingView()
          : const _LoadFailed();
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: context.read<GlassesCubit>().loadDeviceSettings,
      child: _TabScroll(
        children: [
          _DeviceHeader(state: state, settings: settings),
          const SizedBox(height: 24),
          const GlassesSectionHeader(title: 'Smart features'),
          _FeaturesCard(settings: settings),
          const SizedBox(height: 24),
          const GlassesSectionHeader(title: 'Tools'),
          _ToolsCard(state: state),
          const SizedBox(height: 24),
          const GlassesSectionHeader(title: 'About these glasses'),
          _AboutCard(state: state, settings: settings),
          const SizedBox(height: 24),
          const _DisconnectButton(),
        ],
      ),
    );
  }
}

class _DisconnectButton extends StatelessWidget {
  const _DisconnectButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => confirmGlassesDisconnect(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.35)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.link_off_rounded),
        label: Text(
          'Disconnect glasses',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}

/// Asks before disconnecting, then disconnects and closes the settings screen.
Future<void> confirmGlassesDisconnect(BuildContext context) async {
  final cubit = context.read<GlassesCubit>();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Disconnect glasses?',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
      ),
      content: Text(
        'You can pair them again at any time. Media saved on this phone stays here.',
        style: GoogleFonts.outfit(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'Cancel',
            style: GoogleFonts.outfit(color: AppColors.textSecondary),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: Text(
            'Disconnect',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
  if (ok == true) {
    await cubit.disconnectDevice();
    if (context.mounted) Navigator.of(context).maybePop();
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DeviceHeader extends StatelessWidget {
  final GlassesState state;
  final GlassesDeviceSettings settings;

  const _DeviceHeader({required this.state, required this.settings});

  @override
  Widget build(BuildContext context) {
    final device = state.connectedDevice;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const GlassesGlyph(size: 36),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device?.name ?? 'Smart Glasses',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const PulseDot(
                      color: AppColors.success,
                      pulsing: true,
                      size: 7,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      state.activityLabel,
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
          if (device != null && device.hasBatteryInfo)
            BatteryPill(
              level: device.batteryLevel,
              charging: device.isCharging,
            ),
        ],
      ),
    );
  }
}

class _FeaturesCard extends StatelessWidget {
  final GlassesDeviceSettings settings;

  const _FeaturesCard({required this.settings});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GlassesCubit>();
    final tiles = <Widget>[
      if (settings.wearSupported && settings.wearDetection != null)
        _SwitchTile(
          icon: Icons.sensors_rounded,
          title: 'Wearing detection',
          subtitle: 'Pause audio automatically when you take the glasses off',
          value: settings.wearDetection!,
          onChanged: cubit.setWearDetection,
        ),
      if (settings.voiceWakeup != null)
        _SwitchTile(
          icon: Icons.record_voice_over_rounded,
          title: 'Voice wake-up',
          subtitle: 'Say "Hey Cyan" to start the assistant hands-free',
          value: settings.voiceWakeup!,
          onChanged: cubit.setVoiceWakeup,
        ),
    ];
    if (tiles.isEmpty) {
      return const GlassesCard(
        child: _InfoLine(
          icon: Icons.info_outline_rounded,
          text: 'These glasses don\'t report any adjustable smart features.',
        ),
      );
    }
    return GlassesCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: _divided(tiles),
    );
  }
}

class _VolumeCard extends StatelessWidget {
  final GlassesDeviceSettings settings;

  const _VolumeCard({required this.settings});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      if (settings.musicVolume?.isValid ?? false)
        _VolumeRow(
          icon: Icons.music_note_rounded,
          label: 'Media',
          level: settings.musicVolume!,
          channel: GlassesVolumeChannel.music,
        ),
      if (settings.callVolume?.isValid ?? false)
        _VolumeRow(
          icon: Icons.call_rounded,
          label: 'Calls',
          level: settings.callVolume!,
          channel: GlassesVolumeChannel.call,
        ),
      if (settings.systemVolume?.isValid ?? false)
        _VolumeRow(
          icon: Icons.notifications_active_rounded,
          label: 'System sounds',
          level: settings.systemVolume!,
          channel: GlassesVolumeChannel.system,
        ),
    ];
    return GlassesCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: _divided(rows),
    );
  }
}

class _VolumeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final GlassesVolumeLevel level;
  final GlassesVolumeChannel channel;

  const _VolumeRow({
    required this.icon,
    required this.label,
    required this.level,
    required this.channel,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GlassesCubit>();
    final percent = (level.fraction * 100).round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Column(
        children: [
          Row(
            children: [
              _iconBox(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '$percent%',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 5,
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.indicatorInactive,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withValues(alpha: 0.12),
              ),
              child: Slider(
                min: level.min.toDouble(),
                max: level.max.toDouble(),
                divisions: level.max - level.min,
                value: level.value.clamp(level.min, level.max).toDouble(),
                label: '$percent%',
                onChanged: (v) => cubit.previewVolume(channel, v.round()),
                onChangeEnd: (v) => cubit.commitVolume(channel, v.round()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolsCard extends StatelessWidget {
  final GlassesState state;

  const _ToolsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GlassesCubit>();
    final finding = state.pendingCommand == GlassesPendingCommand.find;
    return GlassesCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: _divided([
        _ActionTile(
          icon: Icons.volume_up_rounded,
          title: 'Find my glasses',
          subtitle: 'Play a sound on the glasses',
          busy: finding,
          onTap: state.canCapture && !state.isRecording
              ? cubit.findGlasses
              : null,
        ),
        _ActionTile(
          icon: Icons.schedule_rounded,
          title: 'Sync time',
          subtitle: 'Set the glasses clock from your phone',
          onTap: cubit.syncTimeNow,
        ),
      ]),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final GlassesState state;
  final GlassesDeviceSettings settings;

  const _AboutCard({required this.state, required this.settings});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Name', state.connectedDevice?.name ?? '—'),
      if (settings.firmwareVersion.isNotEmpty)
        ('Firmware', settings.firmwareVersion),
      if (settings.hardwareVersion.isNotEmpty)
        ('Hardware', settings.hardwareVersion),
      if (settings.wifiFirmwareVersion.isNotEmpty)
        ('Wi‑Fi firmware', settings.wifiFirmwareVersion),
      if (settings.address.isNotEmpty) ('Bluetooth address', settings.address),
    ];
    return GlassesCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Color(0xFFF0EEF8)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Text(
                    rows[i].$1,
                    style: GoogleFonts.outfit(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SelectableText(
                      rows[i].$2,
                      textAlign: TextAlign.end,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────────── Building blocks ─────────────────────────────

Widget _divided(List<Widget> children) => Column(
  children: [
    for (int i = 0; i < children.length; i++) ...[
      if (i > 0) const Divider(height: 1, indent: 68, color: Color(0xFFF0EEF8)),
      children[i],
    ],
  ],
);

Widget _iconBox(IconData icon) => Container(
  width: 40,
  height: 40,
  decoration: BoxDecoration(
    color: AppColors.primary.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Icon(icon, color: AppColors.primary, size: 20),
);

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _iconBox(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool busy;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null && !busy ? 0.5 : 1,
      child: InkWell(
        onTap: busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _iconBox(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textLight,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _NotConnected extends StatelessWidget {
  final String message;

  const _NotConnected({
    this.message = 'Connect your smart glasses to change their settings.',
  });

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      icon: Icons.bluetooth_disabled_rounded,
      title: 'Glasses not connected',
      body: message,
      action: TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(
          'Go back',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed();

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      icon: Icons.sync_problem_rounded,
      title: 'Couldn\'t read settings',
      body:
          'The glasses didn\'t answer. Keep them close to your phone and try again.',
      action: FilledButton(
        onPressed: context.read<GlassesCubit>().loadDeviceSettings,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          'Try again',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GlassesScanningRadar(size: 140),
          const SizedBox(height: 16),
          Text(
            'Reading settings from your glasses…',
            style: GoogleFonts.outfit(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Widget action;

  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 40),
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
              body,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            action,
          ],
        ),
      ),
    );
  }
}
