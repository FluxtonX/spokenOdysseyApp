import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

import '../theme/theme.dart';
import '../views/memories/memory_detail_screen.dart';

class RecentMemoryMediaCarousel extends StatefulWidget {
  const RecentMemoryMediaCarousel({super.key, required this.memories});

  final List<Map<String, dynamic>> memories;

  @override
  State<RecentMemoryMediaCarousel> createState() =>
      _RecentMemoryMediaCarouselState();
}

class _RecentMemoryMediaCarouselState extends State<RecentMemoryMediaCarousel>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _audioBarsController;
  Timer? _autoSlideTimer;
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  int _currentIndex = 0;

  List<Map<String, dynamic>> get _mediaMemories =>
      widget.memories.where((memory) {
        final mediaUrl = memory['mediaUrl']?.toString();
        final type = memory['type']?.toString().toLowerCase() ?? '';
        return (mediaUrl != null && mediaUrl.isNotEmpty) ||
            type.contains('photo') ||
            type.contains('video') ||
            type.contains('voice') ||
            type.contains('audio');
      }).toList();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _audioBarsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _startAutoSlide();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _activateCurrentMedia();
    });
  }

  @override
  void didUpdateWidget(covariant RecentMemoryMediaCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.memories != widget.memories) {
      final maxIndex = math.max(0, _mediaMemories.length - 1);
      if (_currentIndex > maxIndex) {
        _currentIndex = 0;
      }
      _activateCurrentMedia();
      _restartAutoSlide();
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _audioBarsController.dispose();
    _pageController.dispose();
    _disposeMediaControllers();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || _mediaMemories.length <= 1) return;

      final nextPage = (_currentIndex + 1) % _mediaMemories.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 720),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _restartAutoSlide() {
    _startAutoSlide();
  }

  Future<void> _disposeMediaControllers() async {
    final videoController = _videoController;
    final audioPlayer = _audioPlayer;
    _videoController = null;
    _audioPlayer = null;

    if (videoController != null) {
      await videoController.pause();
      await videoController.dispose();
    }

    if (audioPlayer != null) {
      await audioPlayer.stop();
      await audioPlayer.dispose();
    }
  }

  Future<void> _activateCurrentMedia() async {
    await _disposeMediaControllers();
    if (!mounted || _mediaMemories.isEmpty) return;

    final memory = _mediaMemories[_currentIndex];
    final mediaUrl = memory['mediaUrl']?.toString();
    final mimeType = memory['mediaMimeType']?.toString().toLowerCase() ?? '';
    final type = memory['type']?.toString().toLowerCase() ?? '';

    if (mediaUrl == null || mediaUrl.isEmpty) {
      return;
    }

    if (mimeType.startsWith('video/') || type.contains('video')) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(mediaUrl));
      _videoController = controller;

      try {
        await controller.initialize();
        await controller.setLooping(true);
        await controller.setVolume(0.0);
        await controller.play();
        if (mounted) {
          setState(() {});
        }
      } catch (_) {
        if (_videoController == controller) {
          await controller.dispose();
          _videoController = null;
        }
      }
      return;
    }

    if (mimeType.startsWith('audio/') ||
        type.contains('voice') ||
        type.contains('audio')) {
      final player = AudioPlayer();
      _audioPlayer = player;

      try {
        await player.setUrl(mediaUrl);
        await player.setLoopMode(LoopMode.one);
        await player.setVolume(0.9);
        await player.play();
      } catch (_) {
        if (_audioPlayer == player) {
          await player.dispose();
          _audioPlayer = null;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mediaMemories.isEmpty) {
      return Container(
        height: 260,
        decoration: BoxDecoration(
          color: AppTheme.adaptiveCardBg,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppTheme.adaptiveBorder),
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Your visual and voice stories will begin appearing here as a living media carousel.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.6,
              color: AppTheme.adaptiveTextSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _mediaMemories.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              _restartAutoSlide();
              _activateCurrentMedia();
            },
            itemBuilder: (context, index) {
              final memory = _mediaMemories[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double pageDelta = 0;
                  if (_pageController.hasClients &&
                      _pageController.position.hasContentDimensions) {
                    pageDelta =
                        (_pageController.page ?? _currentIndex.toDouble()) -
                        index.toDouble();
                  } else {
                    pageDelta = (_currentIndex - index).toDouble();
                  }

                  final scale = 1 - (pageDelta.abs() * 0.08).clamp(0.0, 0.08);
                  final translate = pageDelta * 18;

                  return Transform.translate(
                    offset: Offset(translate, 0),
                    child: Transform.scale(scale: scale, child: child),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildMemorySlide(
                    memory,
                    isActive: index == _currentIndex,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _mediaMemories.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              width: index == _currentIndex ? 28 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: index == _currentIndex
                    ? const Color(0xFF5544FF)
                    : AppTheme.adaptiveDivider,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemorySlide(
    Map<String, dynamic> memory, {
    required bool isActive,
  }) {
    final mediaUrl = memory['mediaUrl']?.toString();
    final thumbnailUrl = memory['thumbnailUrl']?.toString();
    final mimeType = memory['mediaMimeType']?.toString().toLowerCase() ?? '';
    final type = memory['type']?.toString().toLowerCase() ?? '';

    return GestureDetector(
      onTap: () => Get.to(() => MemoryDetailScreen(memory: memory)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if ((mimeType.startsWith('video/') || type.contains('video')) &&
                isActive &&
                _videoController != null &&
                _videoController!.value.isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              )
            else if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
              Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _buildFallbackSurface(type: type, isActive: isActive),
              )
            else if (mediaUrl != null &&
                mediaUrl.isNotEmpty &&
                mimeType.startsWith('image/'))
              Image.network(
                mediaUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _buildFallbackSurface(type: type, isActive: isActive),
              )
            else
              _buildFallbackSurface(type: type, isActive: isActive),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.02),
                    Colors.black.withValues(alpha: 0.14),
                    Colors.black.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
            Positioned(top: 18, right: 18, child: _buildTypeChip(type)),
            if (mimeType.startsWith('video/') || type.contains('video'))
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 320),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: isActive ? 0.2 : 0.4),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            if ((mimeType.startsWith('audio/') ||
                    type.contains('voice') ||
                    type.contains('audio')) &&
                isActive)
              Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment.center,
                    child: _AudioBars(animation: _audioBarsController),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackSurface({required String type, required bool isActive}) {
    if (type.contains('voice') || type.contains('audio')) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5544FF), Color(0xFF283252), Color(0xFF131B2E)],
          ),
        ),
        child: Center(child: _AudioBars(animation: _audioBarsController)),
      );
    }

    if (type.contains('video')) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE85D75), Color(0xFF8A3B56), Color(0xFF201923)],
          ),
        ),
        child: Center(
          child: Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE2923A), Color(0xFF6A4A30), Color(0xFF1D2028)],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }

  Widget _buildTypeChip(String type) {
    final normalized = type.toLowerCase();
    final icon = normalized.contains('video')
        ? Icons.videocam_rounded
        : normalized.contains('voice') || normalized.contains('audio')
        ? Icons.graphic_eq_rounded
        : Icons.image_rounded;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class _AudioBars extends StatelessWidget {
  const _AudioBars({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final phase = animation.value * math.pi * 2;

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (index) {
            final wave = (math.sin(phase + (index * 0.55)) + 1) / 2;
            final height = 24 + (wave * 42);

            return Container(
              width: 8,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.12),
                    blurRadius: 12,
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}
