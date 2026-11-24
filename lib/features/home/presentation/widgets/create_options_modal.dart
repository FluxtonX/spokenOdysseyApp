import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/di/service_locator.dart';
import '../../../albums/presentation/cubits/albums_cubit.dart';
import '../../../albums/presentation/widgets/create_album_modal.dart';
import '../../../memories/presentation/cubits/memories_cubit.dart';
import '../../../memories/presentation/widgets/publish_wizard_modal.dart';

class CreateOptionsModal extends StatelessWidget {
  final BuildContext parentContext;
  final VoidCallback onRecordVoiceStory;

  const CreateOptionsModal({
    super.key,
    required this.parentContext,
    required this.onRecordVoiceStory,
  });

  static void show(
    BuildContext parentContext, {
    required VoidCallback onRecordVoiceStory,
  }) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return CreateOptionsModal(
          parentContext: parentContext,
          onRecordVoiceStory: onRecordVoiceStory,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create & Record',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'What would you like to add?',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: AppColors.textSecondary,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                children: [
                  // Option 1: Record Voice Story
                  _OptionCard(
                    gradient: DesignTokens.primaryGradient,
                    icon: Icons.mic_rounded,
                    title: 'Record Voice Story',
                    subtitle: 'Capture your voice with live waveform visualizer',
                    onTap: () {
                      Navigator.pop(context);
                      onRecordVoiceStory();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Option 2: Create Memory Story
                  _OptionCard(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF059669)],
                    ),
                    icon: Icons.post_add_rounded,
                    title: 'Create Memory',
                    subtitle: 'Add title, story, media, tags & privacy settings',
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: parentContext,
                        isScrollControlled: true,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        builder: (_) => BlocProvider(
                          create: (_) => sl<MemoriesCubit>(),
                          child: const PublishWizardModal(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Option 3: Create Album
                  _OptionCard(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                    ),
                    icon: Icons.folder_special_rounded,
                    title: 'Create Memory Album',
                    subtitle: 'Organise memories into custom themed albums',
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: parentContext,
                        isScrollControlled: true,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        builder: (_) => BlocProvider(
                          create: (_) => sl<AlbumsCubit>(),
                          child: const CreateAlbumModal(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Safe area bottom padding
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium Option Card
// ─────────────────────────────────────────────────────────────────────────────
class _OptionCard extends StatefulWidget {
  final LinearGradient gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
            boxShadow: DesignTokens.cardShadow,
            border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              // Gradient icon container
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.gradient.colors.first).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
