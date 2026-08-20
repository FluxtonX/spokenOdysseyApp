import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:readmore/readmore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_url_formatter.dart';
import '../../domain/entities/memory_entity.dart';
import 'comments_bottom_sheet.dart';
import 'reaction_bar.dart';

class MemoryCard extends StatefulWidget {
  final MemoryEntity memory;
  final VoidCallback onTap;
  final Function(String type) onReact;
  final VoidCallback? onDelete;
  final bool isGridMode;

  const MemoryCard({
    super.key,
    required this.memory,
    required this.onTap,
    required this.onReact,
    this.onDelete,
    this.isGridMode = false,
  });

  @override
  State<MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<MemoryCard> {
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _showReactions = false;

  String? _userReaction;
  int _likesCount = 0;
  int _commentsCount = 0;

  @override
  void initState() {
    super.initState();
    _userReaction = widget.memory.userReaction;
    _likesCount = widget.memory.likesCount;
    _commentsCount = widget.memory.commentsCount;

    if (widget.memory.mediaUrl != null &&
        (widget.memory.mediaType == 'audio' ||
            widget.memory.mediaUrl!.contains('.mp3') ||
            widget.memory.mediaUrl!.contains('.m4a'))) {
      _initAudio();
    }
  }

  @override
  void didUpdateWidget(covariant MemoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.memory != widget.memory) {
      setState(() {
        _userReaction = widget.memory.userReaction;
        _likesCount = widget.memory.likesCount;
        _commentsCount = widget.memory.commentsCount;
      });
    }
  }

  void _handleLikeTap() {
    final nextReaction = _userReaction != null ? null : 'heart';
    setState(() {
      if (_userReaction == null && nextReaction != null) {
        _likesCount += 1;
      } else if (_userReaction != null && nextReaction == null) {
        _likesCount = (_likesCount - 1).clamp(0, 999999);
      }
      _userReaction = nextReaction;
    });
    widget.onReact(nextReaction ?? 'heart');
  }

  void _handleCommentTap() {
    CommentsBottomSheet.show(
      context,
      widget.memory.id,
      onCommentsUpdated: (count) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _commentsCount = count);
        });
      },
    );
  }

  void _initAudio() {
    final formattedUrl = MediaUrlFormatter.format(widget.memory.mediaUrl);
    if (formattedUrl != null) {
      _audioPlayer = AudioPlayer();
      _audioPlayer!.setUrl(formattedUrl).catchError((_) => null);
      _audioPlayer!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying =
                state.playing &&
                state.processingState != ProcessingState.completed;
          });
        }
      });
      _audioPlayer!.durationStream.listen((d) {
        if (mounted && d != null) setState(() => _duration = d);
      });
      _audioPlayer!.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_audioPlayer == null) return;
    if (_isPlaying) {
      _audioPlayer!.pause();
    } else {
      _audioPlayer!.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedAvatar = MediaUrlFormatter.format(
      widget.memory.author?.avatarUrl,
    );
    final formattedMedia = MediaUrlFormatter.format(widget.memory.mediaUrl);

    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(widget.isGridMode ? 12 : 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE9EA), // Match pinkish color from screenshot
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2C9E4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Category Tag & Date)
                if (widget.isGridMode)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.memory.tags.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5E4EE8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.memory.tags.first,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                widget.memory.createdAt != null
                                    ? widget.memory.createdAt!.split('T').first
                                    : 'Just now',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          if (widget.onDelete != null)
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: PopupMenuButton<String>(
                                onSelected: (val) {
                                  if (val == 'delete') widget.onDelete!();
                                },
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.more_vert, size: 16, color: AppColors.textSecondary),
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      'Delete Memory',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (widget.memory.tags.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5E4EE8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.memory.tags.first,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else
                        const SizedBox(),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            widget.memory.createdAt != null
                                ? widget.memory.createdAt!.split('T').first
                                : 'Just now',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (widget.onDelete != null)
                            PopupMenuButton<String>(
                              onSelected: (val) {
                                if (val == 'delete') widget.onDelete!();
                              },
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    'Delete Memory',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 10),

                // Title & Description
                Text(
                  widget.memory.title,
                  maxLines: widget.isGridMode ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: widget.isGridMode ? 15 : 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (widget.memory.description != null &&
                    widget.memory.description!.isNotEmpty &&
                    !widget.isGridMode) ...[
                  const SizedBox(height: 6),
                  ReadMoreText(
                    widget.memory.description!,
                    trimLines: 3,
                    colorClickableText: AppColors.primary,
                    trimMode: TrimMode.Line,
                    trimCollapsedText: ' Read more',
                    trimExpandedText: ' Show less',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    moreStyle: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    lessStyle: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Audio Player / Image Preview
                if (_audioPlayer != null) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.isGridMode ? 8 : 12,
                      vertical: widget.isGridMode ? 4 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                            color: AppColors.primary,
                            size: widget.isGridMode ? 32 : 40,
                          ),
                          onPressed: _togglePlay,
                        ),
                        if (!widget.isGridMode)
                          Expanded(
                            child: Column(
                              children: [
                                SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 4,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6,
                                    ),
                                    activeTrackColor: AppColors.primary,
                                    inactiveTrackColor: AppColors.primary
                                        .withOpacity(0.2),
                                    thumbColor: AppColors.primary,
                                  ),
                                  child: Slider(
                                    value: _position.inSeconds.toDouble().clamp(
                                      0,
                                      _duration.inSeconds.toDouble() > 0
                                          ? _duration.inSeconds.toDouble()
                                          : 1.0,
                                    ),
                                    max: _duration.inSeconds.toDouble() > 0
                                        ? _duration.inSeconds.toDouble()
                                        : 1.0,
                                    onChanged: (val) {
                                      _audioPlayer?.seek(
                                        Duration(seconds: val.toInt()),
                                      );
                                    },
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(_position),
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(_duration),
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        else
                          Expanded(
                            child: Text(
                              _formatDuration(_duration),
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ] else if (formattedMedia != null &&
                    (widget.memory.mediaType == 'image' ||
                        formattedMedia.endsWith('.png') ||
                        formattedMedia.endsWith('.jpg') ||
                        formattedMedia.endsWith('.jpeg'))) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      formattedMedia,
                      height: widget.isGridMode ? 80 : 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                ],

                // Tags
                if (widget.memory.tags.length > 1 && !widget.isGridMode) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: widget.memory.tags.skip(1).map((t) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9DEF6), // Light purple tag background
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          t,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF5E4EE8),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(color: Color(0xFFE2C9E4)),

                // Interaction Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onLongPress: () {
                            setState(() => _showReactions = !_showReactions);
                          },
                          onTap: _handleLikeTap,
                          child: Row(
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                child: Icon(
                                  _userReaction != null
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  key: ValueKey<bool>(_userReaction != null),
                                  color: _userReaction != null
                                      ? Colors.red
                                      : AppColors.textSecondary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$_likesCount',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: widget.isGridMode ? 8 : 16),
                        GestureDetector(
                          onTap: _handleCommentTap,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: AppColors.textSecondary,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$_commentsCount',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      widget.memory.privacy == 'family' ? Icons.people_alt_outlined : Icons.public,
                      color: const Color(0xFF5E4EE8),
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_showReactions)
          Positioned(
            left: 20,
            bottom: 60,
            child: ReactionBar(
              currentReaction: widget.memory.userReaction,
              onReact: (type) {
                widget.onReact(type);
                setState(() => _showReactions = false);
              },
            ),
          ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
