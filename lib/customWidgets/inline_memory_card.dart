import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';

import '../theme/theme.dart';

class InlineMemoryCard extends StatefulWidget {
  final Map<String, dynamic> memory;
  final VoidCallback onTap;
  final DateTime? memoryDate;

  const InlineMemoryCard({
    super.key,
    required this.memory,
    required this.onTap,
    this.memoryDate,
  });

  @override
  State<InlineMemoryCard> createState() => _InlineMemoryCardState();
}

class _InlineMemoryCardState extends State<InlineMemoryCard> {
  late String type;
  late String mediaUrl;
  late String thumbnailUrl;
  late String title;
  late String description;
  late List<String> tags;

  VideoPlayerController? _videoController;
  bool _isVideoPlaying = false;
  bool _showVideoControls = false;
  Timer? _videoControlsTimer;

  AudioPlayer? _audioPlayer;
  bool _isAudioPlaying = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initMemoryData();
  }

  void _initMemoryData() {
    mediaUrl = widget.memory['mediaUrl']?.toString() ?? '';
    thumbnailUrl = widget.memory['thumbnailUrl']?.toString() ?? '';
    type = widget.memory['type']?.toString().toLowerCase() ?? '';
    title = widget.memory['title']?.toString() ?? 'Untitled memory';
    description = widget.memory['description']?.toString() ?? '';
    tags =
        (widget.memory['tags'] as List?)?.map((e) => e.toString()).toList() ??
        [];

    if (title.isEmpty) title = 'Untitled memory';
  }

  @override
  void didUpdateWidget(InlineMemoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.memory['id'] != widget.memory['id']) {
      _disposeControllers();
      _initMemoryData();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _videoController?.dispose();
    _videoController = null;
    _videoControlsTimer?.cancel();

    _audioPlayer?.dispose();
    _audioPlayer = null;
  }

  // --- Video Logic ---
  Future<void> _initAndPlayVideo() async {
    if (mediaUrl.isEmpty) return;

    if (_videoController == null) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(mediaUrl));
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.addListener(() {
        if (!mounted) return;
        setState(() {});
      });
    }

    setState(() {
      _isVideoPlaying = true;
      _showVideoControls = true;
    });
    _videoController!.play();
    _startHideControlsTimer();
  }

  void _toggleVideoPlayPause() {
    if (_videoController == null) return;
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _showVideoControls = true;
        _videoControlsTimer?.cancel();
      } else {
        _videoController!.play();
        _startHideControlsTimer();
      }
    });
  }

  void _seekVideo(Duration offset) {
    if (_videoController == null) return;
    final newPosition = _videoController!.value.position + offset;
    _videoController!.seekTo(newPosition);
    _startHideControlsTimer();
  }

  void _startHideControlsTimer() {
    _videoControlsTimer?.cancel();
    _videoControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _videoController?.value.isPlaying == true) {
        setState(() => _showVideoControls = false);
      }
    });
  }

  // --- Audio Logic ---
  Future<void> _toggleAudioPlayPause() async {
    if (mediaUrl.isEmpty) return;

    if (_audioPlayer == null) {
      _audioPlayer = AudioPlayer();
      try {
        await _audioPlayer!.setUrl(mediaUrl);
        _audioPlayer!.positionStream.listen((pos) {
          if (mounted) setState(() => _audioPosition = pos);
        });
        _audioPlayer!.durationStream.listen((dur) {
          if (mounted && dur != null) setState(() => _audioDuration = dur);
        });
        _audioPlayer!.playerStateStream.listen((state) {
          if (mounted) {
            setState(() {
              _isAudioPlaying =
                  state.playing &&
                  state.processingState != ProcessingState.completed;
            });
            if (state.processingState == ProcessingState.completed) {
              _audioPlayer!.seek(Duration.zero);
              _audioPlayer!.pause();
            }
          }
        });
      } catch (e) {
        debugPrint("Error loading audio: \$e");
        return;
      }
    }

    if (_isAudioPlaying) {
      _audioPlayer!.pause();
    } else {
      _audioPlayer!.play();
    }
  }

  void _seekAudio(double value) {
    if (_audioPlayer != null) {
      _audioPlayer!.seek(Duration(milliseconds: value.toInt()));
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "\$minutes:\$seconds";
  }

  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return const Color(0xFFEBF5FF);
    try {
      String cleanHex = hexColor.replaceAll('#', '');
      if (cleanHex.length == 6) cleanHex = 'FF\$cleanHex';
      return Color(int.parse(cleanHex, radix: 16));
    } catch (e) {
      return const Color(0xFFEBF5FF);
    }
  }

  Widget _buildTagPill(String text, {bool isType = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isType
            ? const Color(0xFF5D5FEF).withValues(alpha: 0.1)
            : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isType ? const Color(0xFF5D5FEF) : const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    if (type == 'text') {
      final hexColor = widget.memory['color']?.toString() ?? '';
      final bgColor = _parseColor(hexColor);
      final textContent = widget.memory['description']?.toString() ?? '';

      return Container(
        color: bgColor,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            textContent,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ),
      );
    }

    IconData icon;
    String label;
    if (type == 'video') {
      icon = Icons.videocam_rounded;
      label = 'Video Memory';
    } else if (type == 'voice' || type == 'audio') {
      icon = Icons.mic_rounded;
      label = 'Voice Note';
    } else {
      icon = Icons.image_rounded;
      label = 'Photo Memory';
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFE2E8F0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: const Color(0xFF5D5FEF)),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5D5FEF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null) {
      final hasThumb = thumbnailUrl.isNotEmpty;
      final displayUrl = hasThumb ? thumbnailUrl : mediaUrl;

      return Stack(
        fit: StackFit.expand,
        children: [
          if (displayUrl.isNotEmpty)
            Image.network(
              displayUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildFallbackIcon(),
            )
          else
            _buildFallbackIcon(),
          Center(
            child: GestureDetector(
              onTap: _initAndPlayVideo,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _showVideoControls = !_showVideoControls;
        });
        if (_showVideoControls) _startHideControlsTimer();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          VideoPlayer(_videoController!),
          if (_showVideoControls)
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: Stack(
                children: [
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () =>
                              _seekVideo(const Duration(seconds: -10)),
                          icon: const Icon(
                            Icons.replay_10_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 24),
                        GestureDetector(
                          onTap: _toggleVideoPlayPause,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _videoController!.value.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          onPressed: () =>
                              _seekVideo(const Duration(seconds: 10)),
                          icon: const Icon(
                            Icons.forward_10_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: VideoProgressIndicator(
                      _videoController!,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      colors: const VideoProgressColors(
                        playedColor: Color(0xFF5D5FEF),
                        bufferedColor: Colors.white24,
                        backgroundColor: Colors.white12,
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

  Widget _buildAudioPlayer() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildFallbackIcon(),
        Center(
          child: GestureDetector(
            onTap: _toggleAudioPlayPause,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF5D5FEF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isAudioPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: const Color(0xFF5D5FEF),
                size: 48,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioControls() {
    if (_audioPlayer == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            _formatDuration(_audioPosition),
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.adaptiveTextSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: const Color(0xFF5D5FEF),
                inactiveTrackColor: AppTheme.adaptiveDivider,
                thumbColor: const Color(0xFF5D5FEF),
              ),
              child: Slider(
                min: 0,
                max: _audioDuration.inMilliseconds.toDouble() > 0
                    ? _audioDuration.inMilliseconds.toDouble()
                    : 1.0,
                value: _audioPosition.inMilliseconds.toDouble().clamp(
                  0.0,
                  _audioDuration.inMilliseconds.toDouble() > 0
                      ? _audioDuration.inMilliseconds.toDouble()
                      : 1.0,
                ),
                onChanged: _seekAudio,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(_audioDuration),
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.adaptiveTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent() {
    final displayUrl = thumbnailUrl.isNotEmpty ? thumbnailUrl : mediaUrl;
    final typeLower = type.toLowerCase();

    if (typeLower.contains('video')) {
      return _buildVideoPlayer();
    } else if (typeLower.contains('voice') || typeLower.contains('audio')) {
      return _buildAudioPlayer();
    } else if (typeLower.contains('photo')) {
      return displayUrl.isNotEmpty
          ? Image.network(
              displayUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildFallbackIcon(),
            )
          : _buildFallbackIcon();
    } else {
      return _buildFallbackIcon();
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayDate = '';
    if (widget.memoryDate != null) {
      displayDate = DateFormat(
        'MMM d, yyyy · h:mm a',
      ).format(widget.memoryDate!.toLocal());
    }

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFEDF2F9),
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildMediaContent(),
            ),
            if (_audioPlayer != null &&
                (type.toLowerCase().contains('voice') ||
                    type.toLowerCase().contains('audio')))
              _buildAudioControls(),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.adaptiveTextPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      displayDate,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppTheme.adaptiveTextSecondary,
                      ),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 14.5,
                      color: AppTheme.adaptiveTextSecondary.withValues(
                        alpha: 0.8,
                      ),
                      height: 1.4,
                    ),
                  ),
                ],
                if (tags.isNotEmpty || type.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (type.isNotEmpty)
                        _buildTagPill(
                          type.replaceFirst(type[0], type[0].toUpperCase()),
                          isType: true,
                        ),
                      ...tags.map((tag) => _buildTagPill(tag)),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
