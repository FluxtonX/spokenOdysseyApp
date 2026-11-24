import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/animated_waveform.dart';
import '../../domain/entities/glasses_media_item.dart';
import '../cubit/glasses_cubit.dart';
import '../widgets/glasses_visuals.dart';
import 'smart_glasses_media_page.dart';

/// Full-screen, swipeable viewer for media imported from the glasses.
class SmartGlassesMediaViewer extends StatefulWidget {
  final List<GlassesMediaItem> items;
  final int initialIndex;

  const SmartGlassesMediaViewer({
    super.key,
    required this.items,
    this.initialIndex = 0,
  });

  static Future<void> open(
    BuildContext context, {
    required List<GlassesMediaItem> items,
    int initialIndex = 0,
  }) {
    final cubit = context.read<GlassesCubit>();
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => BlocProvider.value(
          value: cubit,
          child: SmartGlassesMediaViewer(
            items: List.of(items),
            initialIndex: initialIndex.clamp(0, items.length - 1),
          ),
        ),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  State<SmartGlassesMediaViewer> createState() =>
      _SmartGlassesMediaViewerState();
}

class _SmartGlassesMediaViewerState extends State<SmartGlassesMediaViewer> {
  late final PageController _pageController = PageController(
    initialPage: widget.initialIndex,
  );
  late final List<GlassesMediaItem> _items = widget.items;
  late int _index = widget.initialIndex;
  bool _chromeVisible = true;

  GlassesMediaItem get _current => _items[_index];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (!await confirmGlassesMediaDelete(context)) return;
    if (!mounted) return;
    final item = _current;
    await context.read<GlassesCubit>().deleteMedia(item);
    if (!mounted) return;
    if (_items.length <= 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _items.removeAt(_index);
      if (_index >= _items.length) _index = _items.length - 1;
    });
  }

  void _showInfo() {
    final item = _current;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Details',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _infoRow(
                'Type',
                item.isVideo
                    ? 'Video'
                    : item.isAudio
                    ? 'Voice note'
                    : 'Photo',
              ),
              _infoRow('File', item.fileName),
              if (item.durationSeconds > 0)
                _infoRow(
                  'Duration',
                  formatGlassesDuration(item.durationSeconds),
                ),
              _infoRow(
                'Size',
                formatGlassesBytes(
                  item.sizeBytes > 0
                      ? item.sizeBytes
                      : (File(item.filePath).existsSync()
                            ? File(item.filePath).lengthSync()
                            : 0),
                ),
              ),
              if (item.capturedAt != null)
                _infoRow(
                  'Captured',
                  DateFormat('d MMM yyyy, h:mm a').format(item.capturedAt!),
                ),
              _infoRow(
                'Imported',
                DateFormat('d MMM yyyy, h:mm a').format(item.importedAt),
              ),
              _infoRow('Saved to', 'This phone (Glasses library)'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: GoogleFonts.outfit(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );

  /// Photos can go full screen with a tap; other media keep their bars.
  bool get _barsVisible => _chromeVisible || !_current.isImage;

  @override
  Widget build(BuildContext context) {
    final item = _current;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _viewerBackground,
        // The bars sit above and below the media instead of on top of it,
        // so the picture is never covered or dimmed.
        body: Column(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _barsVisible
                  ? _ViewerTopBar(
                      item: item,
                      onClose: () => Navigator.of(context).pop(),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final media = _items[i];
                  final active = i == _index;
                  if (media.isVideo) {
                    return _VideoPage(
                      key: ValueKey(media.filePath),
                      item: media,
                      active: active,
                    );
                  }
                  if (media.isAudio) {
                    return _AudioPage(
                      key: ValueKey(media.filePath),
                      item: media,
                      active: active,
                    );
                  }
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        setState(() => _chromeVisible = !_chromeVisible),
                    child: _PhotoPage(item: media),
                  );
                },
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.bottomCenter,
              child: _barsVisible
                  ? _ViewerBottomBar(
                      index: _index,
                      count: _items.length,
                      onInfo: _showInfo,
                      onDelete: _delete,
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

const Color _viewerBackground = Color(0xFF0B0B12);

class _ViewerTopBar extends StatelessWidget {
  final GlassesMediaItem item;
  final VoidCallback onClose;

  const _ViewerTopBar({required this.item, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final kind = item.isVideo
        ? 'Video'
        : item.isAudio
        ? 'Voice note'
        : 'Photo';
    return Container(
      width: double.infinity,
      color: _viewerBackground,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 16, 8),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Close',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                ),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: onClose,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEE, d MMM yyyy').format(item.displayDate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '$kind  ·  ${DateFormat('h:mm a').format(item.displayDate)}',
                      style: GoogleFonts.outfit(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewerBottomBar extends StatelessWidget {
  final int index;
  final int count;
  final VoidCallback onInfo;
  final VoidCallback onDelete;

  const _ViewerBottomBar({
    required this.index,
    required this.count,
    required this.onInfo,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _viewerBackground,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Row(
            children: [
              _ViewerAction(
                icon: Icons.info_outline_rounded,
                label: 'Details',
                onTap: onInfo,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${index + 1} / $count',
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              _ViewerAction(
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                color: const Color(0xFFFF8A8A),
                onTap: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewerAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ViewerAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: color.withValues(alpha: 0.85),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── Photo ─────────────────────────────

class _PhotoPage extends StatelessWidget {
  final GlassesMediaItem item;

  const _PhotoPage({required this.item});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'glasses-media-${item.filePath}',
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 5,
        child: Center(
          child: Image(
            image: GlassesFileImage.of(item.filePath),
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const _MissingFile(),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── Video ─────────────────────────────

class _VideoPage extends StatefulWidget {
  final GlassesMediaItem item;
  final bool active;

  const _VideoPage({super.key, required this.item, required this.active});

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  VideoPlayerController? _controller;
  bool _error = false;
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    final file = File(widget.item.filePath);
    if (!file.existsSync()) {
      _error = true;
      return;
    }
    _controller = VideoPlayerController.file(file)
      ..initialize()
          .then((_) {
            if (!mounted) return;
            setState(() {});
            if (widget.active) _play();
          })
          .catchError((_) {
            if (mounted) setState(() => _error = true);
          });
    _controller!.addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant _VideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active && oldWidget.active) _controller?.pause();
  }

  void _play() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.position >= c.value.duration) c.seekTo(Duration.zero);
    c.play();
    _scheduleHide();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggle() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      c.pause();
      setState(() => _showControls = true);
    } else {
      _play();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  String _fmt(Duration d) => formatGlassesDuration(d.inSeconds);

  @override
  Widget build(BuildContext context) {
    if (_error) return const _MissingFile();
    final c = _controller;
    final ready = c != null && c.value.isInitialized;
    final item = widget.item;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() => _showControls = !_showControls);
        if (_showControls) _scheduleHide();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: ready
                ? AspectRatio(
                    aspectRatio: c.value.aspectRatio,
                    child: VideoPlayer(c),
                  )
                : Hero(
                    tag: 'glasses-media-${item.filePath}',
                    child: item.hasThumbnail
                        ? Image.file(
                            File(item.thumbnailPath),
                            fit: BoxFit.contain,
                          )
                        : const SizedBox.shrink(),
                  ),
          ),
          if (!ready)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          if (ready)
            AnimatedOpacity(
              opacity: _showControls ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: Stack(
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _toggle,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Icon(
                            c.value.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0xCC000000), Colors.transparent],
                          ),
                        ),
                        child: SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                            child: Row(
                              children: [
                                Text(
                                  _fmt(c.value.position),
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: VideoProgressIndicator(
                                    c,
                                    allowScrubbing: true,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    colors: const VideoProgressColors(
                                      playedColor: AppColors.primaryLight,
                                      bufferedColor: Colors.white30,
                                      backgroundColor: Colors.white12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _fmt(c.value.duration),
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Audio ─────────────────────────────

class _AudioPage extends StatefulWidget {
  final GlassesMediaItem item;
  final bool active;

  const _AudioPage({super.key, required this.item, required this.active});

  @override
  State<_AudioPage> createState() => _AudioPageState();
}

class _AudioPageState extends State<_AudioPage> {
  final AudioPlayer _player = AudioPlayer();
  bool _error = false;
  bool _silent = false;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _load();
    _checkSilence();
  }

  /// Flags WAV voice notes whose samples are all (near) zero, so an empty
  /// recording isn't mistaken for a broken player.
  Future<void> _checkSilence() async {
    final path = widget.item.filePath;
    if (!path.toLowerCase().endsWith('.wav')) return;
    try {
      final bytes = await File(path).readAsBytes();
      if (bytes.length <= 44) return;
      final data = ByteData.sublistView(bytes, 44);
      var peak = 0;
      for (var i = 0; i + 1 < data.lengthInBytes; i += 8) {
        final v = data.getInt16(i, Endian.little).abs();
        if (v > peak) peak = v;
        if (peak > 300) break;
      }
      if (mounted && peak <= 300) setState(() => _silent = true);
    } catch (_) {}
  }

  Future<void> _load() async {
    try {
      final d = await _player.setFilePath(widget.item.filePath);
      if (mounted) {
        setState(
          () => _duration = d ?? Duration(seconds: widget.item.durationSeconds),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void didUpdateWidget(covariant _AudioPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active && oldWidget.active) _player.pause();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle(bool playing) async {
    if (playing) {
      await _player.pause();
    } else {
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return const _MissingFile(message: 'This voice note can\'t be played.');
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_viewerBackground, Color(0xFF1A1344), _viewerBackground],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snap) {
              final playing =
                  (snap.data?.playing ?? false) &&
                  snap.data?.processingState != ProcessingState.completed;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          blurRadius: 40,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      color: Colors.white,
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Voice note',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recorded on your smart glasses',
                    style: GoogleFonts.outfit(
                      color: Colors.white60,
                      fontSize: 13,
                    ),
                  ),
                  if (_silent) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.volume_off_rounded,
                            color: Colors.white70,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'No sound was recorded in this voice note.',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  AnimatedWaveform(
                    isPlaying: playing,
                    height: 48,
                    barCount: 32,
                    color: AppColors.primaryLight,
                  ),
                  const SizedBox(height: 20),
                  StreamBuilder<Duration>(
                    stream: _player.positionStream,
                    builder: (context, posSnap) {
                      final pos = posSnap.data ?? Duration.zero;
                      final max = _duration.inMilliseconds > 0
                          ? _duration.inMilliseconds.toDouble()
                          : 1.0;
                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              activeTrackColor: AppColors.primaryLight,
                              inactiveTrackColor: Colors.white12,
                              thumbColor: Colors.white,
                              overlayColor: Colors.white12,
                            ),
                            child: Slider(
                              min: 0,
                              max: max,
                              value: pos.inMilliseconds
                                  .clamp(0, max.toInt())
                                  .toDouble(),
                              onChanged: (v) => _player.seek(
                                Duration(milliseconds: v.toInt()),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatGlassesDuration(pos.inSeconds),
                                  style: GoogleFonts.outfit(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  formatGlassesDuration(
                                    (_duration.inMilliseconds + 500) ~/ 1000,
                                  ),
                                  style: GoogleFonts.outfit(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => _toggle(playing),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: AppColors.primary,
                        size: 40,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MissingFile extends StatelessWidget {
  final String message;

  const _MissingFile({this.message = 'This file is no longer on your phone.'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.broken_image_outlined,
            color: Colors.white38,
            size: 56,
          ),
          const SizedBox(height: 12),
          Text(message, style: GoogleFonts.outfit(color: Colors.white70)),
        ],
      ),
    );
  }
}
