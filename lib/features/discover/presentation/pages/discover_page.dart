import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/media_url_formatter.dart';
import '../../../../core/widgets/app_ui.dart';
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
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF9CA3AF),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Search memories, albums, people...',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF0FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Search',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4A3AFF),
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
          _FeaturedPersonCard(
            person: people[i],
            cardIndex: i,
            onFollowToggle: () {
              context.read<DiscoverCubit>().toggleFollow(
                people[i].id,
                people[i].isFollowing,
              );
            },
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
          _StoryCard(
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
    final gradientColors = _coverGradients[cardIndex % _coverGradients.length];

    final name = person.name?.isNotEmpty == true ? person.name! : 'User';
    final profession = person.profession?.isNotEmpty == true
        ? person.profession!
        : 'Storyteller';
    final bio = person.bio?.isNotEmpty == true
        ? person.bio!
        : 'Sharing life stories and preserving memories.';

    final followersFormatted = NumberFormat.compact().format(
      person.followersCount,
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PublicProfilePage(person: person)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover Banner with Overlapping Avatar ───────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    gradient: cover == null
                        ? LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    image: cover != null
                        ? DecorationImage(
                            image: NetworkImage(cover),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: -24,
                  left: 18,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
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
                                fontSize: 22,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── Body Info ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profession,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bio,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF374151),
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),

            // ── Footer: Followers & Follow Button ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                      ),
                      children: [
                        TextSpan(
                          text: followersFormatted,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        const TextSpan(text: ' followers'),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: onFollowToggle,
                    icon: Icon(
                      person.isFollowing
                          ? Icons.person_rounded
                          : Icons.person_add_rounded,
                      size: 15,
                      color: person.isFollowing
                          ? const Color(0xFF374151)
                          : Colors.white,
                    ),
                    label: Text(
                      person.isFollowing ? 'Following' : 'Follow',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: person.isFollowing
                            ? const Color(0xFF374151)
                            : Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: person.isFollowing
                          ? const Color(0xFFF3F4F6)
                          : const Color(0xFF4A3AFF),
                      foregroundColor: person.isFollowing
                          ? const Color(0xFF374151)
                          : Colors.white,
                      elevation: 0,
                      minimumSize: const Size(92, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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
    final authorProfession = m.author?.profession ?? 'Storyteller';
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

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Author Row ───────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFEEF2FF),
                  backgroundImage: avatar != null ? NetworkImage(avatar) : null,
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
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        authorProfession,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Tags Row ─────────────────────────────────────────────────
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (int i = 0; i < tags.take(3).length; i++)
                  _buildTagBadge(tags.elementAt(i), i),
              ],
            ),

            const SizedBox(height: 10),

            // ── Story Title ──────────────────────────────────────────────
            Text(
              m.title,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
                height: 1.3,
                letterSpacing: -0.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            // ── Description / Excerpt ────────────────────────────────────
            if (m.description != null && m.description!.isNotEmpty)
              Text(
                m.description!,
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF4B5563),
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

            // ── Rich Media Display ───────────────────────────────────────
            if (_isAudio) ...[
              const SizedBox(height: 12),
              // ── Interactive Voice Player Bar ───────────────────────────
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
                                  fontSize: 13.5,
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
                          const SizedBox(height: 4),
                          // Sound wave visualizer bars
                          Row(
                            children: [
                              for (int i = 0; i < 18; i++)
                                Expanded(
                                  child: Container(
                                    height: _isPlaying
                                        ? (8.0 + (i % 5) * 3.5)
                                        : (4.0 + (i % 4) * 2.0),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isPlaying
                                          ? const Color(0xFF4A3AFF)
                                          : const Color(0xFFA78BFA),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
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
            ] else if (_isImage && mediaUrl != null && mediaUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  mediaUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ] else if (_isVideo && mediaUrl != null && mediaUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              VideoPlayerWidget(
                videoUrl: mediaUrl,
                height: 200,
                borderRadius: BorderRadius.circular(14),
              ),
            ],

            const SizedBox(height: 12),

            // ── Date ─────────────────────────────────────────────────────
            Text(
              formattedDate,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF9CA3AF),
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 10),

            // ── Bottom Interaction Stats ─────────────────────────────────
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
                      const SizedBox(width: 4),
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
                const SizedBox(width: 18),
                Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
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
          ],
        ),
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
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tag,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colorPair['text'],
        ),
      ),
    );
  }
}
