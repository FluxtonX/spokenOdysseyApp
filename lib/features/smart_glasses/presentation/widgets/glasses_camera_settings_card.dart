import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/glasses_device_settings.dart';
import '../cubit/glasses_cubit.dart';
import '../cubit/glasses_state.dart';
import 'glasses_visuals.dart';

/// Professional, easy-to-use and easy-to-lock camera & video settings card.
class GlassesCameraSettingsCard extends StatelessWidget {
  final bool showHeader;

  const GlassesCameraSettingsCard({super.key, this.showHeader = true});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GlassesCubit, GlassesState>(
      buildWhen: (a, b) =>
          a.cameraSettings != b.cameraSettings ||
          a.isConnected != b.isConnected,
      builder: (context, state) {
        final cubit = context.read<GlassesCubit>();
        final settings = state.cameraSettings;
        final isLocked = settings.isLocked;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              GlassesSectionHeader(
                title: 'Camera & Video',
                actionLabel: isLocked ? 'Unlock' : 'Lock',
                onAction: cubit.toggleCameraLock,
              ),
              const SizedBox(height: 8),
            ],
            GlassesCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Quick Lock Banner ──
                  _LockBanner(
                    isLocked: isLocked,
                    onToggle: cubit.toggleCameraLock,
                  ),
                  const SizedBox(height: 18),

                  // ── Section 1: Video Resolution (4K / 3K / 1080P) ──
                  _SectionTitle(
                    icon: Icons.videocam_rounded,
                    title: 'Video Resolution',
                    badge: settings.videoResolution.label,
                  ),
                  const SizedBox(height: 10),
                  _ResolutionSelector(
                    selected: settings.videoResolution,
                    isLocked: isLocked,
                    onSelected: cubit.setVideoResolution,
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Color(0xFFF0EEF8)),
                  const SizedBox(height: 16),

                  // ── Section 2: Clip Duration Limit ──
                  _SectionTitle(
                    icon: Icons.timer_outlined,
                    title: 'Clip Duration Limit',
                    badge: settings.durationLimit.label,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Automatically stops or splits video to ensure stable transfer.',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _DurationSelector(
                    selected: settings.durationLimit,
                    isLocked: isLocked,
                    onSelected: cubit.setVideoDurationLimit,
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Color(0xFFF0EEF8)),
                  const SizedBox(height: 12),

                  // ── Section 3: EIS Electronic Anti-shake ──
                  _SwitchRow(
                    icon: Icons.auto_fix_high_rounded,
                    title: 'EIS Anti-shake',
                    subtitle: 'Stabilize footage while walking or turning head',
                    value: settings.antiShakeEis,
                    isLocked: isLocked,
                    onChanged: (_) => cubit.toggleAntiShakeEis(),
                  ),
                  const Divider(
                    height: 1,
                    indent: 48,
                    color: Color(0xFFF0EEF8),
                  ),
                  const SizedBox(height: 12),

                  // ── Section 4: Photo Resolution ──
                  _SectionTitle(
                    icon: Icons.camera_alt_rounded,
                    title: 'Photo Quality',
                    badge: settings.photoResolution.label,
                  ),
                  const SizedBox(height: 10),
                  _PhotoResolutionSelector(
                    selected: settings.photoResolution,
                    isLocked: isLocked,
                    onSelected: cubit.setPhotoResolution,
                  ),
                  const SizedBox(height: 12),
                  const Divider(
                    height: 1,
                    indent: 48,
                    color: Color(0xFFF0EEF8),
                  ),
                  const SizedBox(height: 8),

                  // ── Section 5: Watermark ──
                  _SwitchRow(
                    icon: Icons.date_range_rounded,
                    title: 'Date & Time Stamp',
                    subtitle: 'Imprint timestamp on recorded photos and videos',
                    value: settings.watermark,
                    isLocked: isLocked,
                    onChanged: (_) => cubit.toggleWatermark(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lock banner with 1-tap lock/unlock
// ─────────────────────────────────────────────────────────────────────────────

class _LockBanner extends StatelessWidget {
  final bool isLocked;
  final VoidCallback onToggle;

  const _LockBanner({required this.isLocked, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isLocked
              ? AppColors.primary.withValues(alpha: 0.08)
              : const Color(0xFFF8F7FD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isLocked
                ? AppColors.primary.withValues(alpha: 0.35)
                : const Color(0xFFE4E0F4),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isLocked ? AppColors.primary : const Color(0xFFDDD9EE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                color: isLocked ? Colors.white : AppColors.textSecondary,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLocked
                        ? 'Settings Locked (Protected)'
                        : 'Settings Unlocked',
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isLocked
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    isLocked
                        ? 'Accidental changes are blocked while wearing glasses'
                        : 'Tap to lock settings to prevent accidental touches',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isLocked ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: isLocked
                    ? null
                    : Border.all(color: const Color(0xFFD6D1EE)),
              ),
              child: Text(
                isLocked ? 'Unlock' : 'Lock',
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isLocked ? Colors.white : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section title
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String badge;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            badge,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Video Resolution Selector (4K / 3K / 1080P)
// ─────────────────────────────────────────────────────────────────────────────

class _ResolutionSelector extends StatelessWidget {
  final VideoResolution selected;
  final bool isLocked;
  final ValueChanged<VideoResolution> onSelected;

  const _ResolutionSelector({
    required this.selected,
    required this.isLocked,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: VideoResolution.values.map((res) {
        final active = selected == res;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: isLocked ? null : () => onSelected(res),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: active ? AppColors.primary : const Color(0xFFEBE8F6),
                  width: active ? 1.8 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: active ? AppColors.primaryGradient : null,
                      color: active ? null : const Color(0xFFF1EFF9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      res.label,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: active ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              res == VideoResolution.res4K
                                  ? '4K Ultra HD'
                                  : res == VideoResolution.res3K
                                  ? '3K Cinematic'
                                  : '1080P Smooth',
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(${res.dimensions})',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          res.subtitle,
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    active
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: active ? AppColors.primary : const Color(0xFFCCC8DF),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Duration limit pills
// ─────────────────────────────────────────────────────────────────────────────

class _DurationSelector extends StatelessWidget {
  final VideoDurationLimit selected;
  final bool isLocked;
  final ValueChanged<VideoDurationLimit> onSelected;

  const _DurationSelector({
    required this.selected,
    required this.isLocked,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: VideoDurationLimit.values.map((dur) {
        final active = selected == dur;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: isLocked ? null : () => onSelected(dur),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : const Color(0xFFF3F1FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: active ? AppColors.primary : const Color(0xFFE2DFF2),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  dur.label,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Photo resolution selector
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoResolutionSelector extends StatelessWidget {
  final PhotoResolution selected;
  final bool isLocked;
  final ValueChanged<PhotoResolution> onSelected;

  const _PhotoResolutionSelector({
    required this.selected,
    required this.isLocked,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: PhotoResolution.values.map((photo) {
        final active = selected == photo;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: isLocked ? null : () => onSelected(photo),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active ? AppColors.primary : const Color(0xFFE7E4F4),
                    width: active ? 1.6 : 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      photo.label,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: active
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      photo.dimensions,
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Switch Row with Lock support
// ─────────────────────────────────────────────────────────────────────────────

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool isLocked;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isLocked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
            onChanged: isLocked ? null : onChanged,
          ),
        ],
      ),
    );
  }
}
