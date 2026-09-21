import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../memories/presentation/widgets/video_player_widget.dart';
import '../cubit/glasses_cubit.dart';
import '../cubit/glasses_state.dart';
import '../../domain/entities/glasses_media_item.dart';

class SmartGlassesGallerySheet extends StatelessWidget {
  const SmartGlassesGallerySheet({super.key});

  static void show(BuildContext context) {
    context.read<GlassesCubit>().loadLocalMedia();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<GlassesCubit>(),
        child: const SmartGlassesGallerySheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.video_library_rounded,
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
                      'Smart Glasses Gallery',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'Play imported MP4 videos & photos',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              AppIconButton(
                icon: Icons.close_rounded,
                label: 'Close Smart Glasses gallery',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Import Status Progress Indicator
          BlocBuilder<GlassesCubit, GlassesState>(
            builder: (context, state) {
              if (state.isImporting) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              state.importStatusText.isNotEmpty
                                  ? state.importStatusText
                                  : 'Downloading media from Smart Glasses...',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF374151),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Import Action Button
          BlocBuilder<GlassesCubit, GlassesState>(
            builder: (context, state) {
              return AppButton(
                icon: Icons.sync_rounded,
                label: state.isImporting
                    ? 'Syncing...'
                    : 'Sync and import new media',
                isLoading: state.isImporting,
                onPressed: state.isImporting
                    ? null
                    : () => context.read<GlassesCubit>().importAlbum(),
              );
            },
          ),
          const SizedBox(height: 16),

          // Media List View
          Expanded(
            child: BlocBuilder<GlassesCubit, GlassesState>(
              builder: (context, state) {
                if (state.importedMedia.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.videocam_outlined,
                          size: 56,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No Glasses Videos Imported Yet',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap "Sync & Import New Media" above to transfer videos recorded by your glasses via Wi-Fi.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: state.importedMedia.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = state.importedMedia[index];
                    return _buildMediaCard(context, item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaCard(BuildContext context, GlassesMediaItem item) {
    final fileExists = File(item.filePath).existsSync();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Media Type Icon / Thumbnail
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: item.isVideo
                  ? const Color(0xFF4F46E5).withValues(alpha: 0.1)
                  : item.isImage
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.isVideo
                  ? Icons.play_circle_fill_rounded
                  : item.isImage
                  ? Icons.image_rounded
                  : Icons.mic_rounded,
              color: item.isVideo
                  ? const Color(0xFF4F46E5)
                  : item.isImage
                  ? const Color(0xFF10B981)
                  : Colors.orange,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),

          // File Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.isVideo
                            ? 'MP4 Video'
                            : item.isImage
                            ? 'JPG Image'
                            : 'Audio Note',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                    if (item.durationSeconds > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${item.durationSeconds}s',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Play / View Action Button
          if (item.isVideo)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(
                'Play',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => _playVideoModal(context, item.filePath),
            )
          else if (item.isImage && fileExists)
            IconButton(
              icon: const Icon(
                Icons.visibility_rounded,
                color: AppColors.primary,
              ),
              onPressed: () => _showImageDialog(context, item.filePath),
            ),
        ],
      ),
    );
  }

  void _playVideoModal(BuildContext context, String filePath) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.black,
              elevation: 0,
              title: Text(
                'Playing Glasses Video',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
              ),
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Container(
              height: 320,
              color: Colors.black,
              child: VideoPlayerWidget(
                videoUrl: Uri.file(filePath).toString(),
                autoPlay: true,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(BuildContext context, String filePath) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Image.file(File(filePath), fit: BoxFit.contain)],
        ),
      ),
    );
  }
}
