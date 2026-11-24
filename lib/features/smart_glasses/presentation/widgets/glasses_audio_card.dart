import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/glasses_audio_status.dart';
import '../cubit/glasses_cubit.dart';
import '../cubit/glasses_state.dart';
import 'glasses_visuals.dart';

/// Shows whether sound plays through the glasses and lets the user connect it.
class GlassesAudioCard extends StatefulWidget {
  const GlassesAudioCard({super.key});

  @override
  State<GlassesAudioCard> createState() => _GlassesAudioCardState();
}

class _GlassesAudioCardState extends State<GlassesAudioCard> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<GlassesCubit>();
    if (cubit.state.audio.state == GlassesAudioState.unknown) {
      cubit.refreshAudioStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GlassesCubit, GlassesState>(
      buildWhen: (a, b) => a.audio != b.audio || a.isConnected != b.isConnected,
      builder: (context, state) {
        if (!state.isConnected) return const SizedBox.shrink();
        final audio = state.audio;
        final cubit = context.read<GlassesCubit>();

        final (icon, color, title, body) = switch (audio.state) {
          GlassesAudioState.connected => (
            Icons.headphones_rounded,
            AppColors.success,
            'Sound plays through your glasses',
            [
              if (audio.media) 'Music & media',
              if (audio.calls) 'Calls',
            ].join(' · ').ifEmpty('Audio connected'),
          ),
          GlassesAudioState.pairing => (
            Icons.bluetooth_searching_rounded,
            AppColors.primary,
            'Pairing glasses audio…',
            'Accept the "Pair" request when your phone asks.',
          ),
          GlassesAudioState.connecting => (
            Icons.bluetooth_searching_rounded,
            AppColors.primary,
            'Connecting glasses audio…',
            'This usually takes a few seconds.',
          ),
          GlassesAudioState.paired => (
            Icons.speaker_phone_rounded,
            AppColors.warning,
            'Sound is playing on your phone',
            'Your glasses are paired but their audio isn\'t connected.',
          ),
          GlassesAudioState.failed => (
            Icons.error_outline_rounded,
            AppColors.error,
            'Glasses audio not connected',
            'Keep the glasses on and close to your phone, then try again.',
          ),
          _ => (
            Icons.speaker_phone_rounded,
            AppColors.warning,
            'Sound is playing on your phone',
            'Connect the glasses\' speaker & mic once to hear audio and calls on them.',
          ),
        };

        final showConnect = audio.state != GlassesAudioState.connected;
        return GlassesCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: audio.isBusy
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: AppColors.primary,
                            ),
                          )
                        : Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          body,
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (showConnect) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: FilledButton.icon(
                          onPressed: audio.isBusy ? null : cubit.connectAudio,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor:
                                AppColors.indicatorInactive,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.headphones_rounded, size: 20),
                          label: Text(
                            audio.state == GlassesAudioState.paired
                                ? 'Reconnect audio'
                                : 'Connect audio',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (audio.state == GlassesAudioState.failed ||
                        audio.state == GlassesAudioState.paired) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: cubit.openBluetoothSettings,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(
                              color: AppColors.borderLight,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Bluetooth settings',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
