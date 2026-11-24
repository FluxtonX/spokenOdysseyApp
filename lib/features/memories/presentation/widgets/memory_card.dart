import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/utils/media_url_formatter.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/animated_waveform.dart';
import '../../domain/entities/memory_entity.dart';
import 'comments_bottom_sheet.dart';
import 'reaction_bar.dart';
import 'video_player_widget.dart';

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
  bool _pressed = false;

  String? _userReaction;
  int _likesCount = 0;
  int _commentsCount = 0;

  // ── Theme constants ────────────────────────────────────────────────────────
  static const _primary = Color(0xFF5B3EFF);

  static const _primaryLight = Color(0xFF8672FF);
  static const _textDark = Color(0xFF111827);
  static const _textMuted = Color(0xFF6B7280);
  static const _surface = Color(0xFFF9FAFC);
  static const _border = Color(0xFFE5E7EB);
  static const _cardRadius = 20.0;

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

  // ── Reaction logic (unchanged) ───────────────────────────────────────────
  void _handleLikeTap() {
    final isUnreacting = _userReaction != null;
    final nextReaction = isUnreacting ? null : 'heart';
    final targetType = _userReaction ?? 'heart';
    setState(() {
      if (!isUnreacting) {
        _likesCount += 1;
      } else {
        _likesCount = (_likesCount - 1).clamp(0, 999999);
      }
      _userReaction = nextReaction;
      _showReactions = false;
    });
    widget.onReact(targetType);
  }

  void _handleSelectReaction(String type) {
    final isUnreacting = _userReaction == type;
    final nextReaction = isUnreacting ? null : type;
    setState(() {
      if (_userReaction == null && nextReaction != null) {
        _likesCount += 1;
      } else if (_userReaction != null && nextReaction == null) {
        _likesCount = (_likesCount - 1).clamp(0, 999999);
      }
      _userReaction = nextReaction;
      _showReactions = false;
    });
    widget.onReact(type);
  }

  Widget _buildReactionIcon({bool light = false}) {
    final Color defaultColor = light ? Colors.white : _textMuted;
    if (_userReaction == null) {
      return Icon(Icons.favorite_border_rounded, color: defaultColor, size: 20);
    }
    switch (_userReaction) {
      case 'like':
        return const Text('👍', style: TextStyle(fontSize: 18));
      case 'care':
        return const Text('🤗', style: TextStyle(fontSize: 18));
      case 'haha':
        return const Text('😂', style: TextStyle(fontSize: 18));
      case 'wow':
        return const Text('😮', style: TextStyle(fontSize: 18));
      case 'angry':
        return const Text('😡', style: TextStyle(fontSize: 18));
      case 'heart':
      default:
        return Icon(
          Icons.favorite_rounded,
          color: light ? Colors.red.shade300 : Colors.red,
          size: 20,
        );
    }
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

  // ─────────────────────────────────────────────────────────────────────────
  // SHARED COMPONENTS
  // ─────────────────────────────────────────────────────────────────────────

  /// Privacy chip — compact, elegant
  Widget _privacyChip() {
    final privacy = widget.memory.privacy?.toLowerCase() ?? 'public';
    Color chipColor;
    IconData icon;
    String label;

    switch (privacy) {
      case 'family':
        chipColor = DesignTokens.privacyFamilyBg;
        icon = Icons.people_alt_rounded;
        label = 'Family';
        break;
      case 'private':
        chipColor = DesignTokens.privacyPrivateBg;
        icon = Icons.lock_rounded;
        label = 'Private';
        break;
      default:
        chipColor = DesignTokens.privacyPublicBg;
        icon = Icons.public_rounded;
        label = 'Public';
    }

    if (widget.isGridMode) {
      return Container(
        padding: const EdgeInsets.all(4.5),
        decoration: BoxDecoration(
          color: chipColor.withValues(alpha: 0.10),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 10, color: chipColor),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.5, color: chipColor),
          const SizedBox(width: 3.5),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Author header — avatar · name+date · privacy chip · ⋮ menu
  Widget _authorHeader({bool onDark = false}) {
    final author = widget.memory.author;
    final avatarUrl = MediaUrlFormatter.format(author?.avatarUrl);
    final name = author?.name?.isNotEmpty == true ? author!.name! : 'Unknown';
    final date = widget.memory.createdAt != null
        ? _formatDatePretty(widget.memory.createdAt!)
        : 'Recently';

    final nameColor = onDark ? Colors.white : _textDark;
    final dateColor = onDark ? Colors.white.withValues(alpha: 0.7) : _textMuted;

    return Row(
      children: [
        // Avatar with gradient ring
        Container(
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                _primary.withValues(alpha: onDark ? 0.6 : 0.3),
                _primaryLight.withValues(alpha: onDark ? 0.6 : 0.3),
              ],
            ),
          ),
          child: CircleAvatar(
            radius: widget.isGridMode ? 14 : 17,
            backgroundColor: onDark
                ? Colors.white.withValues(alpha: 0.15)
                : _surface,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            onBackgroundImageError: avatarUrl != null ? (_, __) {} : null,
            child: avatarUrl == null
                ? Text(
                    name[0].toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: widget.isGridMode ? 12 : 13.5,
                      fontWeight: FontWeight.bold,
                      color: onDark ? Colors.white : _primary,
                    ),
                  )
                : null,
          ),
        ),
        SizedBox(width: widget.isGridMode ? 6 : 8),
        // Name + date stacked
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: GoogleFonts.outfit(
                  fontSize: widget.isGridMode ? 12.5 : 13.5,
                  fontWeight: FontWeight.w700,
                  color: nameColor,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1.5),
              Text(
                date,
                style: GoogleFonts.outfit(
                  fontSize: widget.isGridMode ? 10.5 : 11,
                  color: dateColor,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        // Privacy chip
        if (!onDark) ...[_privacyChip()],
        // Overflow menu
        if (widget.onDelete != null) ...[
          const SizedBox(width: 2),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'delete') widget.onDelete!();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.more_horiz_rounded,
                size: widget.isGridMode ? 16 : 18,
                color: onDark
                    ? Colors.white.withValues(alpha: 0.8)
                    : _textMuted,
              ),
            ),
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
      ],
    );
  }

  /// Type badge — small gradient pill for media type labelling
  Widget _typeBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_primary, _primaryLight]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// Tags row
  Widget _tagsRow() {
    if (widget.memory.tags.isEmpty || widget.isGridMode) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: widget.memory.tags.map((t) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '#$t',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _primary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Footer engagement bar for non-media cards
  Widget _engagementFooter(String typeLabel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _border, width: 0.5)),
      ),
      child: Row(
        children: [
          // Like
          _footerActionButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: KeyedSubtree(
                key: ValueKey<String?>(_userReaction),
                child: _buildReactionIcon(),
              ),
            ),
            label: '$_likesCount',
            isActive: _userReaction != null,
            onTap: _handleLikeTap,
            onLongPress: () => setState(() => _showReactions = !_showReactions),
          ),
          const SizedBox(width: 6),
          // Comment
          _footerActionButton(
            icon: const Icon(
              Icons.mode_comment_outlined,
              color: _textMuted,
              size: 19,
            ),
            label: '$_commentsCount',
            onTap: _handleCommentTap,
          ),
          const Spacer(),
          _typeBadge(typeLabel),
        ],
      ),
    );
  }

  /// Individual footer action button
  Widget _footerActionButton({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? (_userReaction == 'heart' ? Colors.red : _primary)
                      : _textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Premium audio player
  Widget _audioPlayer2() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primary.withValues(alpha: 0.05),
            _primaryLight.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Play/Pause
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: DesignTokens.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Waveform + time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedWaveform(
                      isPlaying: _isPlaying,
                      height: 30,
                      barCount: widget.isGridMode ? 16 : 28,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: _primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: _textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Seek slider
          if (!widget.isGridMode) ...[
            const SizedBox(height: 4),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                activeTrackColor: _primary,
                inactiveTrackColor: _primary.withValues(alpha: 0.12),
                thumbColor: _primary,
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
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
                  _audioPlayer?.seek(Duration(seconds: val.toInt()));
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final formattedMedia = MediaUrlFormatter.format(widget.memory.mediaUrl);

    // Determine media type
    final bool isAudio = _audioPlayer != null;
    bool isVideo = false;
    bool isImage = false;
    String typeLabel = 'Story';

    if (isAudio) {
      typeLabel = 'Voice';
    } else if (formattedMedia != null) {
      if (widget.memory.mediaType == 'video' ||
          formattedMedia.endsWith('.mp4') ||
          formattedMedia.endsWith('.mov') ||
          formattedMedia.endsWith('.webm')) {
        isVideo = true;
        typeLabel = 'Video';
      } else if (widget.memory.mediaType == 'image' ||
          formattedMedia.endsWith('.png') ||
          formattedMedia.endsWith('.jpg') ||
          formattedMedia.endsWith('.jpeg') ||
          formattedMedia.endsWith('.webp') ||
          formattedMedia.endsWith('.gif')) {
        isImage = true;
        typeLabel = 'Photo';
      }
    }

    final bool isMediaCard = isImage || isVideo;

    return Stack(
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: Container(
              margin: EdgeInsets.only(bottom: widget.isGridMode ? 0 : 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_cardRadius),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_cardRadius),
                child: Semantics(
                  button: true,
                  label: 'Open memory: ${widget.memory.title}',
                  child: InkWell(
                    onTap: widget.onTap,
                    child: isMediaCard
                        ? _buildMediaLayout(
                            formattedMedia!,
                            isImage,
                            isVideo,
                            typeLabel,
                          )
                        : _buildTextVoiceLayout(isAudio, typeLabel),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Reactions popup
        if (_showReactions)
          Positioned(
            left: 20,
            bottom: 60,
            child: ReactionBar(
              currentReaction: _userReaction,
              onReact: _handleSelectReaction,
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LAYOUT A: Image / Video  — full-bleed media with glass-overlay footer
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMediaLayout(
    String mediaUrl,
    bool isImage,
    bool isVideo,
    String typeLabel,
  ) {
    // Calculate media height based on mode
    final double mediaHeight = widget.isGridMode ? 140 : 260;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header + Title ──
        Padding(
          padding: widget.isGridMode
              ? const EdgeInsets.fromLTRB(10, 8, 8, 6)
              : const EdgeInsets.fromLTRB(16, 14, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _authorHeader(),
              SizedBox(height: widget.isGridMode ? 4 : 12),
              Text(
                widget.memory.title,
                maxLines: widget.isGridMode ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: widget.isGridMode ? 13.5 : 17,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                  letterSpacing: -0.3,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),

        // ── Full-bleed media + overlaid glass footer ──
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Media — edge-to-edge
            if (isImage)
              Image.network(
                mediaUrl,
                height: mediaHeight,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: widget.isGridMode ? 100 : 180,
                  color: _surface,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: _textMuted,
                      size: 32,
                    ),
                  ),
                ),
              )
            else
              VideoPlayerWidget(videoUrl: mediaUrl, height: mediaHeight),

            // Gradient scrim
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Glass-effect overlaid footer
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // Like
                    Semantics(
                      button: true,
                      label: _userReaction == null
                          ? 'React to memory'
                          : 'Remove reaction',
                      child: _overlayAction(
                        icon: _buildReactionIcon(light: true),
                        label: '$_likesCount',
                        onTap: _handleLikeTap,
                        onLongPress: () =>
                            setState(() => _showReactions = !_showReactions),
                      ),
                    ),
                    const SizedBox(width: 18),
                    // Comment
                    Semantics(
                      button: true,
                      label: 'Open memory comments',
                      child: _overlayAction(
                        icon: const Icon(
                          Icons.mode_comment_outlined,
                          color: Colors.white,
                          size: 19,
                        ),
                        label: '$_commentsCount',
                        onTap: _handleCommentTap,
                      ),
                    ),
                    const Spacer(),
                    _typeBadge(typeLabel),
                  ],
                ),
              ),
            ),

            // Video play badge top-right
            if (isVideo)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Video',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        // ── Tags (if any) ──
        if (widget.memory.tags.isNotEmpty && !widget.isGridMode)
          Padding(padding: const EdgeInsets.only(top: 10), child: _tagsRow()),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LAYOUT B: Text / Voice — refined padded card with polished footer
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTextVoiceLayout(bool isAudio, String typeLabel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _authorHeader(),
              const SizedBox(height: 14),

              // Title
              Text(
                widget.memory.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                  letterSpacing: -0.3,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),

              // Content body
              if (isAudio)
                _audioPlayer2()
              else ...[
                // Elegant quote-style text block
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border(
                      left: BorderSide(
                        color: _primary.withValues(alpha: 0.4),
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    widget.memory.description ?? widget.memory.title,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 14.5,
                      color: _textDark.withValues(alpha: 0.85),
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],

              // Tags
              if (widget.memory.tags.isNotEmpty && !widget.isGridMode) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.memory.tags.map((t) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '#$t',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),

        // Engagement footer
        _engagementFooter(typeLabel),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Overlay action for media footer
  // ─────────────────────────────────────────────────────────────────────────
  Widget _overlayAction({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Row(
        children: [
          icon,
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────
  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatDatePretty(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return isoDate.split('T').first;
    }
  }
}
