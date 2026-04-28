import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StoryMediaBanner extends StatelessWidget {
  const StoryMediaBanner({
    super.key,
    required this.memory,
    this.height = 176,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
  });

  final Map<String, dynamic> memory;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final type = memory['type']?.toString() ?? 'Story';
    final mediaUrl = memory['mediaUrl']?.toString();
    final mediaMimeType =
        memory['mediaMimeType']?.toString().toLowerCase() ?? '';
    final title = memory['title']?.toString() ?? 'Story';
    final accent = _accentForType(type);
    final icon = _iconForType(type);
    final mood = memory['mood']?.toString().trim();
    final privacy = memory['privacy']?.toString().trim();
    final topLabel = mood != null && mood.isNotEmpty ? mood : type;
    final footerLabel = privacy != null && privacy.isNotEmpty
        ? privacy
        : 'Private';

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final ultraCompact =
                constraints.maxHeight <= 136 || constraints.maxWidth <= 220;
            final compact =
                ultraCompact ||
                constraints.maxHeight <= 156 ||
                constraints.maxWidth <= 260;
            final horizontalPadding = ultraCompact
                ? 10.0
                : (compact ? 12.0 : 18.0);
            final verticalPadding = ultraCompact
                ? 10.0
                : (compact ? 12.0 : 18.0);
            final iconBoxSize = ultraCompact ? 28.0 : (compact ? 34.0 : 42.0);
            final iconSize = ultraCompact ? 15.0 : (compact ? 18.0 : 21.0);
            final titleFontSize = ultraCompact ? 16.0 : (compact ? 18.0 : 24.0);
            final titleLines = ultraCompact ? 1 : (compact ? 1 : 2);

            final thumbnailUrl = memory['thumbnailUrl']?.toString();
            final displayUrl = (mediaMimeType.startsWith('video/') && thumbnailUrl != null && thumbnailUrl.isNotEmpty)
                ? thumbnailUrl
                : mediaUrl;

            return Stack(
              fit: StackFit.expand,
              children: [
                if (displayUrl != null &&
                    displayUrl.isNotEmpty &&
                    (mediaMimeType.startsWith('image/') || mediaMimeType.startsWith('video/')))
                  Image.network(
                    displayUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildIllustratedFallback(
                      accent: accent,
                      icon: icon,
                      type: type,
                    ),
                  )
                else
                  _buildIllustratedFallback(
                    accent: accent,
                    icon: icon,
                    type: type,
                  ),
                if (mediaMimeType.startsWith('video/'))
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.08),
                        Colors.black.withValues(alpha: 0.18),
                        Colors.black.withValues(alpha: 0.58),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: ultraCompact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                width: iconBoxSize,
                                height: iconBoxSize,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.14),
                                  ),
                                ),
                                child: Icon(
                                  icon,
                                  color: Colors.white,
                                  size: iconSize,
                                ),
                              ),
                            ),
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: _buildMetaPill(
                                    label: topLabel,
                                    foreground: accent,
                                    background: Colors.white.withValues(
                                      alpha: 0.9,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  width: iconBoxSize,
                                  height: iconBoxSize,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(
                                      compact ? 10 : 14,
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.14,
                                      ),
                                    ),
                                  ),
                                  child: Icon(
                                    icon,
                                    color: Colors.white,
                                    size: iconSize,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!compact &&
                                    mediaMimeType.startsWith('video/'))
                                  _buildCallout(
                                    'Video keeps movement, voice, and atmosphere',
                                  ),
                                if (!compact &&
                                    mediaMimeType.startsWith('audio/'))
                                  _buildCallout(
                                    'Voice keeps the emotion before it fades',
                                  ),
                                if (!compact &&
                                    mediaMimeType.isEmpty &&
                                    type.toLowerCase().contains('text'))
                                  _buildCallout(
                                    'Written memory shaped carefully in words',
                                  ),
                                SizedBox(height: compact ? 6 : 10),
                                Text(
                                  title,
                                  maxLines: titleLines,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.05,
                                  ),
                                ),
                                SizedBox(height: compact ? 6 : 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    _buildMetaPill(
                                      label: footerLabel,
                                      foreground: Colors.white,
                                      background: Colors.white.withValues(
                                        alpha: 0.16,
                                      ),
                                    ),
                                    if (!compact &&
                                        (memory['albumTitle']
                                                ?.toString()
                                                .trim()
                                                .isNotEmpty ??
                                            false))
                                      _buildMetaPill(
                                        label: memory['albumTitle'].toString(),
                                        foreground: Colors.white,
                                        background: Colors.white.withValues(
                                          alpha: 0.12,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildIllustratedFallback({
    required Color accent,
    required IconData icon,
    required String type,
  }) {
    final normalized = type.toLowerCase();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.92),
            _darken(accent, 0.28),
            const Color(0xFF171A23),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -20,
            child: Container(
              width: 138,
              height: 138,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.09),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -10,
            bottom: -34,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          if (normalized.contains('voice'))
            _buildWaveformOverlay()
          else if (normalized.contains('video'))
            _buildVideoOverlay()
          else if (normalized.contains('photo'))
            _buildPhotoOverlay()
          else
            _buildTextOverlay(icon),
        ],
      ),
    );
  }

  Widget _buildWaveformOverlay() {
    return Align(
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(10, (index) {
          final heights = [
            16.0,
            24.0,
            30.0,
            22.0,
            34.0,
            18.0,
            28.0,
            20.0,
            32.0,
            16.0,
          ];
          return Container(
            width: 6,
            height: heights[index],
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(999),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildVideoOverlay() {
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: 38,
        ),
      ),
    );
  }

  Widget _buildPhotoOverlay() {
    return Align(
      alignment: Alignment.center,
      child: Icon(
        Icons.photo_camera_back_outlined,
        color: Colors.white.withValues(alpha: 0.38),
        size: 66,
      ),
    );
  }

  Widget _buildTextOverlay(IconData icon) {
    return Align(
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white.withValues(alpha: 0.34), size: 66),
    );
  }

  Widget _buildCallout(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.outfit(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMetaPill({
    required String label,
    required Color foreground,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.outfit(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }

  Color _accentForType(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('voice')) return const Color(0xFF5544FF);
    if (normalized.contains('photo')) return const Color(0xFFE2923A);
    if (normalized.contains('video')) return const Color(0xFFE85D75);
    return const Color(0xFF5ABA82);
  }

  IconData _iconForType(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('voice')) return Icons.mic_none_rounded;
    if (normalized.contains('photo')) return Icons.collections_outlined;
    if (normalized.contains('video')) return Icons.videocam_outlined;
    return Icons.edit_note_rounded;
  }

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final darkened = hsl.withLightness(
      (hsl.lightness - amount).clamp(0.0, 1.0),
    );
    return darkened.toColor();
  }
}
