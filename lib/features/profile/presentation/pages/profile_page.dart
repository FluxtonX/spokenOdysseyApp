import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/asset_constants.dart';
import '../../../../core/utils/media_url_formatter.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../albums/presentation/cubits/albums_cubit.dart';
import '../../../albums/presentation/pages/album_detail_page.dart';
import '../../../albums/presentation/widgets/create_album_modal.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../memories/domain/entities/memory_entity.dart';
import '../../../memories/presentation/cubits/memories_cubit.dart';
import '../../../memories/presentation/pages/memory_detail_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../settings/presentation/pages/insights_page.dart';
import '../cubits/followers_cubit.dart';
import '../cubits/followers_state.dart';
import '../cubits/profile_cubit.dart';
import '../widgets/share_profile_modal.dart';
import 'followers_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin {
  static const String _defaultCover =
      'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1200&q=80';

  static const List<String> _sampleCovers = [
    'https://images.unsplash.com/photo-1513836279014-a89f7a76ae86?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1516280440614-37939bbacd81?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1556910103-1c02745aae4d?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1499209974431-9dddcece7f88?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&w=600&q=80',
  ];

  int _selectedTab = 0; // 0: My Memories, 1: Albums, 2: Liked

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FD),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ProfileLoaded) {
            final user = state.user;
            final avatar = MediaUrlFormatter.format(user.avatarUrl);
            final cover =
                MediaUrlFormatter.format(user.coverUrl) ?? _defaultCover;

            final profession = user.profession?.isNotEmpty == true
                ? user.profession!
                : 'Software Engineer & Storyteller';
            final location = user.location?.isNotEmpty == true
                ? user.location!
                : 'Lahore, Pakistan';
            final birthDate = user.birthDate?.isNotEmpty == true
                ? 'Born ${user.birthDate!}'
                : (user.dateOfBirth?.isNotEmpty == true
                      ? 'Born ${user.dateOfBirth!}'
                      : 'Born March 15, 1990');
            final bio = user.bio?.isNotEmpty == true
                ? user.bio!
                : 'Collecting the stories that shaped my family\'s journey across generations — one voice, one memory at a time.';
            final lifeMotto = user.lifeMotto?.isNotEmpty == true
                ? user.lifeMotto!
                : 'Every story told is a life immortalized';

            final expertiseList =
                (user.expertise != null && user.expertise!.isNotEmpty)
                ? user.expertise!
                : const <String>[
                    'Photography',
                    'Engineering',
                    'Music',
                    'Family History',
                  ];

            return Stack(
              children: [
                // Organic background wave graphic preserved
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.45,
                    child: Image.asset(AssetConstants.bgPic, fit: BoxFit.cover),
                  ),
                ),

                RefreshIndicator(
                  onRefresh: () async {
                    context.read<ProfileCubit>().loadProfile();
                    context.read<MemoriesCubit>().loadMemories();
                    context.read<AlbumsCubit>().loadAlbums();
                    context.read<FollowersCubit>().loadFollowers();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 50),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Cover Banner + Circular Overlapping Avatar + Top Actions
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Cover Banner Image
                            SizedBox(
                              height: 230,
                              width: double.infinity,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    cover,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Image.network(
                                      _defaultCover,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: const Color(0xFF312E81),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.45),
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.15),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Top Left: Circular Logout Button
                            Positioned(
                              top: topPadding + 8,
                              left: 16,
                              child: _buildTopCircleButton(
                                icon: Icons.logout_rounded,
                                iconColor: const Color(0xFFEF4444),
                                tooltip: 'Sign out',
                                onTap: () =>
                                    _showLogoutConfirmationDialog(context),
                              ),
                            ),

                            // Top Right: 3 Circular Action Buttons (AI, Share, Edit)
                            Positioned(
                              top: topPadding + 8,
                              right: 16,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 1. AI Archive Insights
                                  _buildTopCircleButton(
                                    icon: Icons.auto_awesome_rounded,
                                    iconColor: const Color(0xFF6366F1),
                                    tooltip: 'AI Insights',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const InsightsPage(),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),

                                  // 2. Share Profile
                                  _buildTopCircleButton(
                                    icon: Icons.reply_rounded,
                                    iconColor: const Color(0xFF6366F1),
                                    tooltip: 'Share Profile',
                                    onTap: () {
                                      ShareProfileModal.show(context, user);
                                    },
                                  ),
                                  const SizedBox(width: 8),

                                  // 3. Edit Profile (Settings)
                                  _buildTopCircleButton(
                                    icon: Icons.edit_outlined,
                                    iconColor: const Color(0xFF6366F1),
                                    tooltip: 'Edit Profile',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BlocProvider.value(
                                            value: context.read<ProfileCubit>(),
                                            child: const SettingsPage(
                                              initialTab: 0,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // Overlapping Circular Avatar (Left-aligned as in reference)
                            Positioned(
                              bottom: -50,
                              left: 20,
                              child: Container(
                                width: 104,
                                height: 104,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.14,
                                      ),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: avatar != null
                                      ? Image.network(
                                          avatar,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _buildAvatarFallback(user.name),
                                        )
                                      : _buildAvatarFallback(user.name),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Space below avatar overlap
                        const SizedBox(height: 58),

                        // Profile Info Section (Name, Title, Meta info, Bio)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name
                              Text(
                                user.name?.isNotEmpty == true
                                    ? user.name!
                                    : 'Muhammad Ali',
                                style: GoogleFonts.outfit(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF111827),
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Subtitle / Profession
                              Text(
                                profession,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Location Meta Row
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 19,
                                    color: Color(0xFF6366F1),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      location,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF4B5563),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Birthday Meta Row
                              Row(
                                children: [
                                  const Icon(
                                    Icons.cake_outlined,
                                    size: 19,
                                    color: Color(0xFF6366F1),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      birthDate,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF4B5563),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Bio Paragraph
                              Text(
                                bio,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF4B5563),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Stats Card (Memories | Followers | Following)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildStatsCard(context, user),
                        ),

                        const SizedBox(height: 18),

                        // Quote / Life Motto Card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3FF),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(
                                  0xFF6366F1,
                                ).withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '“',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF6366F1),
                                    height: 0.7,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  lifeMotto,
                                  style: GoogleFonts.outfit(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF3730A3),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Tag Pills Row (#Photography, #Engineering, etc.)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: expertiseList.map((tag) {
                              final label = tag.startsWith('#') ? tag : '#$tag';
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  label,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0369A1),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Tab Pill Selector (My Memories | Albums | Liked)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                _buildTabPill(index: 0, label: 'My Memories'),
                                _buildTabPill(index: 1, label: 'Albums'),
                                _buildTabPill(index: 2, label: 'Liked'),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Content for Active Tab
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildActiveTabContent(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else if (state is ProfileError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Retry',
                      expand: false,
                      onPressed: () =>
                          context.read<ProfileCubit>().loadProfile(),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  // Top floating circular button helper
  Widget _buildTopCircleButton({
    required IconData icon,
    required Color iconColor,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ),
      ),
    );
  }

  // Stats Card with 3 Columns: Memories | Followers | Following
  Widget _buildStatsCard(BuildContext context, dynamic user) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Memories
          Expanded(
            child: BlocBuilder<MemoriesCubit, MemoriesState>(
              builder: (context, memState) {
                final count = memState is MemoriesLoaded
                    ? '${memState.memories.length}'
                    : '${user.memoriesCount}';
                return _buildStatColumn(count: count, label: 'Memories');
              },
            ),
          ),

          Container(width: 1, height: 36, color: const Color(0xFFE5E7EB)),

          // 2. Followers
          Expanded(
            child: BlocBuilder<FollowersCubit, FollowersState>(
              builder: (context, fState) {
                final count = fState is FollowersLoaded
                    ? '${fState.followers.length}'
                    : '${user.followersCount}';
                return _buildStatColumn(
                  count: count,
                  label: 'Followers',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FollowersPage(initialTabIndex: 0),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Container(width: 1, height: 36, color: const Color(0xFFE5E7EB)),

          // 3. Following
          Expanded(
            child: BlocBuilder<FollowersCubit, FollowersState>(
              builder: (context, fState) {
                final count = fState is FollowersLoaded
                    ? '${fState.following.length}'
                    : '${user.followingCount}';
                return _buildStatColumn(
                  count: count,
                  label: 'Following',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FollowersPage(initialTabIndex: 1),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required String count,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  // Pill tab item
  Widget _buildTabPill({required int index, required String label}) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedTab != index) {
            setState(() => _selectedTab = index);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Active Tab content router
  Widget _buildActiveTabContent(BuildContext context) {
    switch (_selectedTab) {
      case 0:
        return _buildMemoriesTab(context, isLikedOnly: false);
      case 1:
        return _buildAlbumsTab(context);
      case 2:
        return _buildMemoriesTab(context, isLikedOnly: true);
      default:
        return const SizedBox();
    }
  }

  // Memories 2-Column Grid (matches image 2: Monsoon Rooftop Nights, etc.)
  Widget _buildMemoriesTab(BuildContext context, {required bool isLikedOnly}) {
    return BlocBuilder<MemoriesCubit, MemoriesState>(
      builder: (context, state) {
        if (state is MemoriesLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (state is MemoriesLoaded) {
          final memories = isLikedOnly
              ? state.memories
                    .where((m) => m.userReaction != null || m.likesCount > 0)
                    .toList()
              : state.memories;

          if (memories.isEmpty) {
            return _buildEmptyState(
              icon: isLikedOnly
                  ? Icons.favorite_border_rounded
                  : Icons.auto_stories_outlined,
              title: isLikedOnly
                  ? 'No Liked Memories'
                  : 'No Memories Recorded Yet',
              subtitle: isLikedOnly
                  ? 'Heart memories to save your favorites here.'
                  : 'Start recording your spoken family memories today.',
            );
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: memories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.82,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemBuilder: (context, index) {
              final memory = memories[index];
              return _buildMemoryGridCard(context, memory, index);
            },
          );
        }
        return const SizedBox();
      },
    );
  }

  // Dynamic Typed Memory Card router
  Widget _buildMemoryGridCard(
    BuildContext context,
    MemoryEntity memory,
    int index,
  ) {
    final formattedMedia = MediaUrlFormatter.format(memory.mediaUrl);
    final mediaLower = (formattedMedia ?? '').toLowerCase();
    final typeLower = (memory.mediaType ?? '').toLowerCase();

    final bool isAudio =
        typeLower == 'audio' ||
        typeLower == 'voice' ||
        mediaLower.endsWith('.mp3') ||
        mediaLower.endsWith('.m4a') ||
        mediaLower.endsWith('.wav') ||
        mediaLower.endsWith('.aac') ||
        mediaLower.endsWith('.ogg');

    final bool isVideo =
        !isAudio &&
        (typeLower == 'video' ||
            mediaLower.endsWith('.mp4') ||
            mediaLower.endsWith('.mov') ||
            mediaLower.endsWith('.webm') ||
            mediaLower.endsWith('.mkv'));

    final bool hasImageFile =
        formattedMedia != null &&
        (mediaLower.endsWith('.jpg') ||
            mediaLower.endsWith('.jpeg') ||
            mediaLower.endsWith('.png') ||
            mediaLower.endsWith('.webp') ||
            mediaLower.endsWith('.gif'));

    final bool isImage =
        !isAudio &&
        !isVideo &&
        (typeLower == 'image' || typeLower == 'photo' || hasImageFile);

    if (isAudio) {
      return _buildAudioMemoryCard(
        context,
        memory,
        formattedMedia,
        hasImageFile,
        index,
      );
    } else if (isVideo) {
      return _buildVideoMemoryCard(context, memory, formattedMedia, index);
    } else if (isImage) {
      return _buildPhotoMemoryCard(context, memory, formattedMedia, index);
    } else {
      return _buildTextMemoryCard(context, memory);
    }
  }

  // 1. Audio / Voice Memory Card
  Widget _buildAudioMemoryCard(
    BuildContext context,
    MemoryEntity memory,
    String? mediaUrl,
    bool hasImageFile,
    int index,
  ) {
    final dateBadge = _formatDateBadge(memory);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MemoryDetailPage(memoryId: memory.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background: cover image if available, else rich gradient
              if (hasImageFile && mediaUrl != null)
                Image.network(
                  mediaUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1E1B4B),
                          Color(0xFF312E81),
                          Color(0xFF4F46E5),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1E1B4B),
                        Color(0xFF312E81),
                        Color(0xFF4338CA),
                      ],
                    ),
                  ),
                ),

              // Gradient Scrim
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.88),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),

              // Top Row: Microphone icon (left) + VOICE badge (right)
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.95),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.mic_rounded,
                          color: Color(0xFF6366F1),
                          size: 18,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.graphic_eq_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            dateBadge.isNotEmpty ? dateBadge : 'VOICE',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Middle: Soundwave Equalizer Graphic
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _buildSoundwaveBars(),
                ),
              ),

              // Bottom Title
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Text(
                  memory.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.25,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Video Memory Card
  Widget _buildVideoMemoryCard(
    BuildContext context,
    MemoryEntity memory,
    String? mediaUrl,
    int index,
  ) {
    final bgImage = mediaUrl ?? _sampleCovers[index % _sampleCovers.length];
    final dateBadge = _formatDateBadge(memory);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MemoryDetailPage(memoryId: memory.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                bgImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF0F172A),
                  child: const Center(
                    child: Icon(Icons.videocam_rounded, color: Colors.white54),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
              // Top Row: Play button (left) + Video badge (right)
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.95),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Color(0xFF6366F1),
                          size: 20,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.videocam_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            dateBadge.isNotEmpty ? dateBadge : 'VIDEO',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom Title
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Text(
                  memory.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.25,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. Photo Memory Card
  Widget _buildPhotoMemoryCard(
    BuildContext context,
    MemoryEntity memory,
    String? mediaUrl,
    int index,
  ) {
    final bgImage = mediaUrl ?? _sampleCovers[index % _sampleCovers.length];
    final dateBadge = _formatDateBadge(memory);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MemoryDetailPage(memoryId: memory.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                bgImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF1E293B),
                  child: const Center(
                    child: Icon(Icons.image_rounded, color: Colors.white54),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
              // Top Row: Camera icon (left) + Date badge (right)
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.4),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.photo_camera_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    if (dateBadge.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          dateBadge,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Bottom Title
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Text(
                  memory.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.25,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. Text / Story Memory Card
  Widget _buildTextMemoryCard(BuildContext context, MemoryEntity memory) {
    final dateBadge = _formatDateBadge(memory);
    final textContent = memory.description?.isNotEmpty == true
        ? memory.description!
        : memory.title;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MemoryDetailPage(memoryId: memory.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.18),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFEDE9FE),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.format_quote_rounded,
                      color: Color(0xFF6366F1),
                      size: 18,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    dateBadge.isNotEmpty ? dateBadge : 'STORY',
                    style: GoogleFonts.outfit(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF5B21B6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Text(
                textContent,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: const Color(0xFF374151),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              memory.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundwaveBars() {
    const heights = [8.0, 14.0, 20.0, 12.0, 18.0, 10.0, 16.0];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: heights.map((h) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          width: 3,
          height: h,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }).toList(),
    );
  }

  String _formatDateBadge(MemoryEntity memory) {
    if (memory.createdAt != null && memory.createdAt!.length >= 10) {
      try {
        final dt = DateTime.parse(memory.createdAt!);
        return '${dt.day}/${dt.month}';
      } catch (_) {}
    }
    return '';
  }

  // Albums Tab
  Widget _buildAlbumsTab(BuildContext context) {
    return BlocBuilder<AlbumsCubit, AlbumsState>(
      builder: (context, state) {
        if (state is AlbumsLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (state is AlbumsLoaded) {
          final albums = state.albums;

          if (albums.isEmpty) {
            return Column(
              children: [
                _buildEmptyState(
                  icon: Icons.photo_album_outlined,
                  title: 'No Albums Yet',
                  subtitle: 'Organize your voice stories into themed albums.',
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      builder: (_) => BlocProvider.value(
                        value: context.read<AlbumsCubit>(),
                        child: const CreateAlbumModal(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: Text(
                    'Create Album',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            );
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: albums.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemBuilder: (context, index) {
              final album = albums[index];
              final cover =
                  MediaUrlFormatter.format(album.coverPhotoUrl) ??
                  _sampleCovers[index % _sampleCovers.length];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AlbumDetailPage(albumId: album.id),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          cover,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF4338CA),
                            child: const Center(
                              child: Icon(
                                Icons.photo_album_rounded,
                                color: Colors.white54,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.85),
                              ],
                              stops: const [0.5, 1.0],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                album.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${album.memoriesCount} memories',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white70,
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
            },
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: const Color(0xFF9CA3AF)),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String? name) {
    return Container(
      color: const Color(0xFFEDE9FE),
      child: Center(
        child: Text(
          name?.isNotEmpty == true ? name![0].toUpperCase() : 'M',
          style: GoogleFonts.outfit(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF6366F1),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Log Out',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to log out of Spoken Odyssey?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          side: const BorderSide(
                            color: Color(0xFFD1D5DB),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          context.read<AuthCubit>().signOut();
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/sign-in',
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          backgroundColor: Colors.redAccent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Log Out',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
