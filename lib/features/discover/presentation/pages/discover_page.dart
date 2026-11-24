import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/media_url_formatter.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/animated_waveform.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../memories/domain/entities/memory_entity.dart';
import '../../../memories/presentation/cubits/memories_cubit.dart';
import '../../../memories/presentation/pages/memory_detail_page.dart';
import '../../../memories/presentation/widgets/video_player_widget.dart';
import '../../../profile/presentation/pages/public_profile_page.dart';
import '../../../store/presentation/pages/store_catalog_page.dart';
import '../cubits/discover_cubit.dart';
import 'search_page.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  // 0 = Featured People, 1 = Latest Stories
  int _selectedTab = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final discoverCubit = context.read<DiscoverCubit>();
    if (discoverCubit.state is! DiscoverLoaded) {
      discoverCubit.loadDiscovery();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<DiscoverCubit, DiscoverState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              await context.read<DiscoverCubit>().loadDiscovery();
            },
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // ── 1. Header Section ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Extraordinary Lives',
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111827),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Step into the archives of those who shaped our world',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF4A3AFF),
                            size: 26,
                          ),
                          tooltip: 'Search Archive',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SearchPage(),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.storefront_rounded,
                            color: Color(0xFF4A3AFF),
                            size: 26,
                          ),
                          tooltip: 'Hardware Store',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const StoreCatalogPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── 2. Search Bar ─────────────────────────────────────────────
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchPage()),
                    );
                  },
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 6,
                      top: 6,
                      bottom: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF9CA3AF),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Search memories, albums, people...',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A3AFF),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            'Search',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── 3. Tab Selector: Featured People vs Latest Stories ────────
                AppSegmentedControl(
                  selectedIndex: _selectedTab,
                  labels: const ['Featured People', 'Latest Stories'],
                  isExpanded: true,
                  onChanged: (index) => setState(() => _selectedTab = index),
                ),

                const SizedBox(height: 18),

                // ── 4. Main Tab Content ───────────────────────────────────────
                if (state is DiscoverLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4A3AFF),
                      ),
                    ),
                  )
                else if (state is DiscoverLoaded)
                  _selectedTab == 0
                      ? _buildFeaturedPeopleList(state.featuredPeople)
                      : _buildLatestStoriesList(state.memories)
                else if (state is DiscoverError)
                  SizedBox(
                    height: 280,
                    child: AsyncStateView(
                      isLoading: false,
                      errorMessage: state.message,
                      isEmpty: false,
                      emptyTitle: '',
                      emptyMessage: '',
                      onRetry: () =>
                          context.read<DiscoverCubit>().loadDiscovery(),
                      child: const SizedBox.shrink(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Tab 1: Featured People List ────────────────────────────────────────────
  Widget _buildFeaturedPeopleList(List<User> people) {
    if (people.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No featured people found.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < people.length; i++) ...[
          _DiscoverFadeSlideIn(
            index: i,
            child: _FeaturedPersonCard(
              person: people[i],
              cardIndex: i,
              onFollowToggle: () {
                context.read<DiscoverCubit>().toggleFollow(
                  people[i].id,
                  people[i].isFollowing,
                );
              },
            ),
          ),
          if (i < people.length - 1) const SizedBox(height: 18),
        ],
      ],
    );
  }

  // ── Tab 2: Latest Stories List ─────────────────────────────────────────────
  Widget _buildLatestStoriesList(List<MemoryEntity> memories) {
    if (memories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No stories found.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < memories.length; i++) ...[
          _DiscoverFadeSlideIn(
            index: i,
            child: _StoryCard(
              memory: memories[i],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MemoryDetailPage(memoryId: memories[i].id),
                  ),
                );
              },
              onReact: () {
                sl<MemoriesCubit>().reactToMemory(memories[i].id, 'LIKE');
              },
            ),
          ),
          if (i < memories.length - 1) const SizedBox(height: 18),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Featured Person Card (Matches Screen 1 & Screen 3)
// ─────────────────────────────────────────────────────────────────────────────
class _FeaturedPersonCard extends StatelessWidget {
  final User person;
  final int cardIndex;
  final VoidCallback onFollowToggle;

  const _FeaturedPersonCard({
    required this.person,
    required this.cardIndex,
    required this.onFollowToggle,
  });

  static const List<List<Color>> _coverGradients = [
    [
      Color(0xFFEA580C),
      Color(0xFFF97316),
      Color(0xFF1E293B),
    ], // Orange cosmic swirl
    [
      Color(0xFF0F766E),
      Color(0xFF0D9488),
      Color(0xFF064E3B),
    ], // Deep teal nature
    [Color(0xFF4338CA), Color(0xFF6366F1), Color(0xFF1E1B4B)], // Indigo violet
    [Color(0xFFBE185D), Color(0xFFDB2777), Color(0xFF500724)], // Rose wine
  ];

  @override
  Widget build(BuildContext context) {
    final avatar = MediaUrlFormatter.format(person.avatarUrl);
    final cover = MediaUrlFormatter.format(person.coverUrl);
    final displayImage = cover ?? avatar;
    final gradientColors = _coverGradients[cardIndex % _coverGradients.length];

    final name = person.name?.isNotEmpty == true ? person.name! : 'User';
    final profession = person.profession?.isNotEmpty == true
        ? person.profession!
        : 'Storyteller';
    final location = person.location?.isNotEmpty == true
        ? person.location!
        : 'Unknown Location';
    final followersFormatted = NumberFormat.compact().format(
      person.followersCount,
    );
    final memoriesFormatted = NumberFormat.compact().format(
      person.memoriesCount,
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PublicProfilePage(person: person)),
        );
      },
      child: Container(
        height: 380,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: displayImage == null
              ? LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          image: displayImage != null
              ? DecorationImage(
                  image: NetworkImage(displayImage),
                  fit: BoxFit.cover,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Dark gradient overlay for text readability
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                      Colors.black.withValues(alpha: 0.9),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              ),
            ),
            // Top Row: Avatar and Follow Button
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFF4A3AFF),
                      backgroundImage: avatar != null
                          ? NetworkImage(avatar)
                          : null,
                      child: avatar == null
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),

                  // Follow Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: onFollowToggle,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: person.isFollowing
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.black.withValues(
                                  alpha: 0.2,
                                ), // Added dark translucent background for better contrast if not following
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              person.isFollowing
                                  ? Icons.check_rounded
                                  : Icons.add_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              person.isFollowing ? 'Following' : 'Follow',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Info Area
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profession,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats Row
                  Row(
                    children: [
                      // Location
                      Icon(
                        Icons.language_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        location,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Memories
                      Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$memoriesFormatted Memories',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '|',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Followers
                      Icon(
                        Icons.favorite_border_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$followersFormatted Followers',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Explore Archive Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PublicProfilePage(person: person),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A3AFF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Explore Archive',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Story Card (Matches Screen 2 with full Media Handling: Image / Audio / Video)
// ─────────────────────────────────────────────────────────────────────────────
class _StoryCard extends StatefulWidget {
  final MemoryEntity memory;
  final VoidCallback onTap;
  final VoidCallback onReact;

  const _StoryCard({
    required this.memory,
    required this.onTap,
    required this.onReact,
  });

  @override
  State<_StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<_StoryCard> {
  AudioPlayer? _player;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  bool get _isAudio {
    final m = widget.memory;
    if (m.mediaType == 'audio' || m.mediaType == 'voice') return true;
    final url = (m.mediaUrl ?? '').toLowerCase();
    if (url.contains('.mp3') ||
        url.contains('.m4a') ||
        url.contains('.wav') ||
        url.contains('.aac') ||
        url.contains('audio')) {
      return true;
    }
    final title = m.title.toLowerCase();
    final desc = (m.description ?? '').toLowerCase();
    return title.contains('voice') ||
        title.contains('audio') ||
        title.contains('recording') ||
        desc.contains('audio story') ||
        desc.contains('voice');
  }

  bool get _isVideo {
    final m = widget.memory;
    if (m.mediaType == 'video') return true;
    final url = (m.mediaUrl ?? '').toLowerCase();
    return url.contains('.mp4') ||
        url.contains('.mov') ||
        url.contains('.webm') ||
        url.contains('video');
  }

  bool get _isImage {
    final m = widget.memory;
    if (m.mediaType == 'image' || m.mediaType == 'photo') return true;
    final url = (m.mediaUrl ?? '').toLowerCase();
    return url.contains('.jpg') ||
        url.contains('.jpeg') ||
        url.contains('.png') ||
        url.contains('.webp') ||
        url.contains('.gif') ||
        (m.mediaUrl != null &&
            m.mediaUrl!.isNotEmpty &&
            !_isAudio &&
            !_isVideo);
  }

  @override
  void initState() {
    super.initState();
    if (_isAudio &&
        widget.memory.mediaUrl != null &&
        widget.memory.mediaUrl!.isNotEmpty) {
      _initAudio();
    }
  }

  void _initAudio() {
    final formatted = MediaUrlFormatter.format(widget.memory.mediaUrl);
    if (formatted != null && formatted.isNotEmpty) {
      _player = AudioPlayer();
      _player!
          .setUrl(formatted)
          .then((d) {
            if (mounted && d != null) setState(() => _duration = d);
          })
          .catchError((_) => null);

      _player!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });
          if (state.processingState == ProcessingState.completed) {
            _player?.seek(Duration.zero);
            _player?.pause();
          }
        }
      });

      _player!.positionStream.listen((pos) {
        if (mounted) setState(() => _position = pos);
      });
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_player == null) {
      final formatted = MediaUrlFormatter.format(widget.memory.mediaUrl);
      if (formatted != null && formatted.isNotEmpty) {
        _initAudio();
      }
    }
    if (_player != null) {
      if (_isPlaying) {
        _player!.pause();
      } else {
        _player!.play();
      }
    } else {
      // If no direct URL, open details
      widget.onTap();
    }
  }

  String _formatTime(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.memory;
    final authorName = m.author?.name ?? 'Author';
    final avatar = MediaUrlFormatter.format(m.author?.avatarUrl);
    final mediaUrl = MediaUrlFormatter.format(m.mediaUrl);

    final tags = m.tags.isNotEmpty
        ? m.tags
        : (m.privacy != null ? [m.privacy!] : ['Story']);

    String formattedDate = 'Recent';
    if (m.createdAt != null) {
      try {
        final dt = DateTime.parse(m.createdAt!);
        formattedDate = DateFormat('MMMM d, yyyy').format(dt);
      } catch (_) {}
    }

    String typeLabel = 'Story';
    if (_isAudio) {
      typeLabel = 'Voice';
    } else if (_isVideo) {
      typeLabel = 'Video';
    } else if (_isImage) {
      typeLabel = 'Photo';
    }

    final bool isMediaCard =
        (_isImage || _isVideo) && mediaUrl != null && mediaUrl.isNotEmpty;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: isMediaCard
              ? _buildMediaLayout(
                  m,
                  authorName,
                  avatar,
                  mediaUrl,
                  formattedDate,
                  tags,
                  typeLabel,
                )
              : _buildTextVoiceLayout(
                  m,
                  authorName,
                  avatar,
                  mediaUrl,
                  formattedDate,
                  tags,
                  typeLabel,
                ),
        ),
      ),
    );
  }

  // ── Full-bleed image/video layout ─────────────────────────────────────────
  Widget _buildMediaLayout(
    MemoryEntity m,
    String authorName,
    String? avatar,
    String mediaUrl,
    String formattedDate,
    List<String> tags,
    String typeLabel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header + title
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFEEF2FF),
                    backgroundImage: avatar != null
                        ? NetworkImage(avatar)
                        : null,
                    child: avatar == null
                        ? Text(
                            authorName.isNotEmpty
                                ? authorName[0].toUpperCase()
                                : 'A',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4A3AFF),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authorName,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          formattedDate,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildPrivacyChip(m.privacy),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                m.title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                  letterSpacing: -0.3,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Full-width media with overlaid footer
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            if (_isImage)
              Image.network(
                mediaUrl,
                height: 270,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(height: 140),
              )
            else
              VideoPlayerWidget(videoUrl: mediaUrl, height: 270),

            // Gradient scrim
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0.0, 0.5],
                    colors: [
                      Colors.black.withValues(alpha: 0.72),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Overlaid footer
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: widget.onReact,
                          child: Row(
                            children: [
                              Icon(
                                m.userReaction != null
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 20,
                                color: m.userReaction != null
                                    ? Colors.red.shade300
                                    : Colors.white,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${m.likesCount}',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        Row(
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${m.commentsCount}',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B3EFF), Color(0xFF8672FF)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      typeLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_isVideo)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_circle_outline_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Video',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        // Tags below image
        if (tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (int i = 0; i < tags.take(3).length; i++)
                  _buildTagBadge(tags.elementAt(i), i),
              ],
            ),
          ),
      ],
    );
  }

  // ── Text / Voice layout ───────────────────────────────────────────────────
  Widget _buildTextVoiceLayout(
    MemoryEntity m,
    String authorName,
    String? avatar,
    String? mediaUrl,
    String formattedDate,
    List<String> tags,
    String typeLabel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFEEF2FF),
                    backgroundImage: avatar != null
                        ? NetworkImage(avatar)
                        : null,
                    child: avatar == null
                        ? Text(
                            authorName.isNotEmpty
                                ? authorName[0].toUpperCase()
                                : 'A',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4A3AFF),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authorName,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          formattedDate,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildPrivacyChip(m.privacy),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                m.title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                  letterSpacing: -0.3,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              if (_isAudio) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _togglePlay,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A3AFF),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF4A3AFF,
                                ).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Voice Recording',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF4A3AFF),
                                  ),
                                ),
                                Text(
                                  _position > Duration.zero
                                      ? '${_formatTime(_position)} / ${_formatTime(_duration)}'
                                      : (_duration > Duration.zero
                                            ? _formatTime(_duration)
                                            : 'Audio'),
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            AnimatedWaveform(
                              isPlaying: _isPlaying,
                              barCount: 22,
                              height: 22,
                              color: const Color(0xFF4A3AFF),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (m.description != null &&
                  m.description!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    m.description!,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF374151),
                      height: 1.55,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              if (tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (int i = 0; i < tags.take(3).length; i++)
                      _buildTagBadge(tags.elementAt(i), i),
                  ],
                ),
              ],
            ],
          ),
        ),

        Container(height: 1, color: const Color(0xFFE5E7EB)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: widget.onReact,
                    child: Row(
                      children: [
                        Icon(
                          m.userReaction != null
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 18,
                          color: m.userReaction != null
                              ? const Color(0xFFE11D48)
                              : const Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${m.likesCount}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 16,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${m.commentsCount}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B3EFF), Color(0xFF8672FF)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  typeLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyChip(String? privacy) {
    final p = privacy?.toLowerCase() ?? 'public';
    Color bg;
    IconData icon;
    String label;
    switch (p) {
      case 'family':
        bg = const Color(0xFF10B981);
        icon = Icons.people_alt_rounded;
        label = 'Family';
        break;
      case 'private':
        bg = const Color(0xFFEF4444);
        icon = Icons.lock_rounded;
        label = 'Private';
        break;
      default:
        bg = const Color(0xFF5B3EFF);
        icon = Icons.public_rounded;
        label = 'Public';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: bg),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: bg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagBadge(String tag, int index) {
    final colors = [
      {'bg': const Color(0xFFEEF2FF), 'text': const Color(0xFF4F46E5)},
      {'bg': const Color(0xFFF1F5F9), 'text': const Color(0xFF475569)},
      {'bg': const Color(0xFFEFF6FF), 'text': const Color(0xFF2563EB)},
      {'bg': const Color(0xFFFDF2F8), 'text': const Color(0xFFDB2777)},
    ];
    final colorPair = colors[index % colors.length];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: colorPair['bg'],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '#$tag',
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colorPair['text'],
        ),
      ),
    );
  }
}

class _DiscoverFadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;

  const _DiscoverFadeSlideIn({required this.child, required this.index});

  @override
  State<_DiscoverFadeSlideIn> createState() => _DiscoverFadeSlideInState();
}

class _DiscoverFadeSlideInState extends State<_DiscoverFadeSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    final delayMs = (widget.index.clamp(0, 6)) * 40;
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}
