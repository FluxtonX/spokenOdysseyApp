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

  const MemoryCard({
    super.key,
    required this.memory,
    required this.onTap,
    required this.onReact,
    this.onDelete,
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
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
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: formattedAvatar != null
                          ? NetworkImage(formattedAvatar)
                          : null,
                      child: formattedAvatar == null
                          ? Text(
                              widget.memory.author?.name?.isNotEmpty == true
                                  ? widget.memory.author!.name![0].toUpperCase()
                                  : 'U',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.memory.author?.name ?? 'Anonymous',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            widget.memory.createdAt != null
                                ? widget.memory.createdAt!.split('T').first
                                : 'Just now',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.memory.privacy == 'family'
                            ? Colors.purple.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        (widget.memory.privacy ?? 'public').toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: widget.memory.privacy == 'family'
                              ? Colors.purple
                              : Colors.blue,
                        ),
                      ),
                    ),
                    if (widget.onDelete != null)
                      PopupMenuButton<String>(
                        onSelected: (val) {
                          if (val == 'delete') widget.onDelete!();
                        },
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
                const SizedBox(height: 12),

                // Title & Description
                Text(
                  widget.memory.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (widget.memory.description != null &&
                    widget.memory.description!.isNotEmpty) ...[
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
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
                            size: 40,
                          ),
                          onPressed: _togglePlay,
                        ),
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
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                ],

                // Tags
                if (widget.memory.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: widget.memory.tags.map((t) {
                      return Chip(
                        label: Text(
                          '#$t',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppColors.primary,
                          ),
                        ),
                        backgroundColor: AppColors.primary.withOpacity(0.08),
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(),

                // Interaction Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$_likesCount',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _handleCommentTap,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$_commentsCount',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.share_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.memory.sharesCount}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
