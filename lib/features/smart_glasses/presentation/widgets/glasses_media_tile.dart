import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/glasses_media_item.dart';
import 'glasses_visuals.dart';

/// Square thumbnail for a photo, video or voice note imported from the glasses.
class GlassesMediaTile extends StatelessWidget {
  final GlassesMediaItem item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double radius;

  const GlassesMediaTile({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: item.isVideo
          ? 'Video ${formatGlassesDuration(item.durationSeconds)}'
          : item.isAudio
          ? 'Voice note ${formatGlassesDuration(item.durationSeconds)}'
          : 'Photo',
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Hero(
          tag: 'glasses-media-${item.filePath}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _thumbnail(),
                if (item.isVideo || item.isAudio)
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x99000000)],
                        stops: [0.55, 1],
                      ),
                    ),
                  ),
                if (item.isVideo)
                  Center(
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white70, width: 1.4),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                if (item.isVideo || item.isAudio)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Small tiles (e.g. the 60 px "just imported" strip) only show the duration.
                        final compact = constraints.maxWidth < 90;
                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            compact ? 4 : 8,
                            0,
                            compact ? 4 : 8,
                            compact ? 3 : 6,
                          ),
                          child: Row(
                            children: [
                              if (!compact)
                                Icon(
                                  item.isVideo
                                      ? Icons.videocam_rounded
                                      : Icons.mic_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              const Spacer(),
                              if (item.durationSeconds > 0)
                                Flexible(
                                  flex: 8,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      formatGlassesDuration(
                                        item.durationSeconds,
                                      ),
                                      maxLines: 1,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: compact ? 10 : 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumbnail() {
    if (item.isAudio) {
      return Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        alignment: Alignment.center,
        child: Icon(
          Icons.graphic_eq_rounded,
          size: 38,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      );
    }
    final path = item.isVideo ? item.thumbnailPath : item.filePath;
    if (path.isEmpty) return _videoPlaceholder();
    return Image(
      image: ResizeImage(GlassesFileImage.of(path), width: 360),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      frameBuilder: (_, child, frame, sync) => AnimatedOpacity(
        opacity: sync || frame != null ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        child: child,
      ),
      errorBuilder: (_, _, _) =>
          item.isVideo ? _videoPlaceholder() : _brokenPlaceholder(),
    );
  }

  Widget _videoPlaceholder() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E1B3A), Color(0xFF3A2A8C)],
      ),
    ),
  );

  Widget _brokenPlaceholder() => Container(
    color: const Color(0xFFF1EEFB),
    alignment: Alignment.center,
    child: const Icon(
      Icons.image_not_supported_outlined,
      color: AppColors.textLight,
    ),
  );
}
