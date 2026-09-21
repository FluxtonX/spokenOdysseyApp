import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../widgets/share_profile_modal.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/media_url_formatter.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../discover/domain/repositories/discover_repository.dart';
import '../../../discover/presentation/cubits/discover_cubit.dart';
import '../../../memories/domain/entities/memory_entity.dart';
import '../../../memories/domain/repositories/memories_repository.dart';
import '../../../memories/presentation/pages/memory_detail_page.dart';

class PublicProfilePage extends StatefulWidget {
  final User person;

  const PublicProfilePage({super.key, required this.person});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  // 0 = Stories, 1 = Milestones, 2 = Albums
  int _selectedSubTab = 0;

  late bool _isFollowing;
  late int _followersCount;
  bool _isFollowLoading = false;

  bool _isLoadingContent = false;
  List<MemoryEntity> _realMemories = [];

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.person.isFollowing;
    _followersCount = widget.person.followersCount;

    _loadUserContent();
  }

  Future<void> _loadUserContent() async {
    final targetId = widget.person.firebaseUid ?? widget.person.id;
    if (targetId.isEmpty) return;

    setState(() => _isLoadingContent = true);
    try {
      final memoriesRepo = sl<MemoriesRepository>();
      final list = await memoriesRepo.getMemories(userId: targetId);
      if (mounted) {
        setState(() {
          _realMemories = list;
          _isLoadingContent = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingContent = false);
      }
    }
  }

  Future<void> _handleFollowToggle() async {
    if (_isFollowLoading) return;

    final nextState = !_isFollowing;
    final nextCount = nextState
        ? _followersCount + 1
        : (_followersCount > 0 ? _followersCount - 1 : 0);

    setState(() {
      _isFollowing = nextState;
      _followersCount = nextCount;
      _isFollowLoading = true;
    });

    try {
      final targetId = widget.person.firebaseUid ?? widget.person.id;
      final discoverRepo = sl<DiscoverRepository>();
      if (nextState) {
        await discoverRepo.followUser(targetId);
      } else {
        await discoverRepo.unfollowUser(targetId);
      }

      // Also trigger DiscoverCubit if available in tree
      try {
        if (mounted) {
          context.read<DiscoverCubit>().toggleFollow(targetId, !nextState);
        }
      } catch (_) {}
    } catch (e) {
      // Revert if error
      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
          _followersCount = _isFollowing
              ? _followersCount + 1
              : (_followersCount > 0 ? _followersCount - 1 : 0);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isFollowLoading = false);
      }
    }
  }

  void _shareProfile() {
    ShareProfileModal.show(context, widget.person);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.person.name?.isNotEmpty == true
        ? widget.person.name!
        : 'User';
    final profession = widget.person.profession?.isNotEmpty == true
        ? widget.person.profession!
        : 'Profession not provided';
    final avatar = MediaUrlFormatter.format(widget.person.avatarUrl);
    final cover = MediaUrlFormatter.format(widget.person.coverUrl);

    final storiesCount = _realMemories.isNotEmpty
        ? _realMemories.length
        : widget.person.memoriesCount;

    final milestonesCount = _realMemories.where((memory) {
      final tags = memory.tags.map((tag) => tag.toLowerCase()).toList();
      return tags.contains('milestone') ||
          tags.contains('career & growth') ||
          tags.contains('turning point') ||
          tags.contains('proud') ||
          memory.title.toLowerCase().contains('milestone');
    }).length;
    final followersFormatted = NumberFormat.compact().format(_followersCount);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F3FE),
      body: Stack(
        children: [
          // ── Scrollable Body ───────────────────────────────────────────────
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Top Cover Banner ───────────────────────────────────
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: cover != null
                      ? Image.network(
                          cover,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildCoverGradient(),
                        )
                      : _buildCoverGradient(),
                ),

                // ── 2. Floating White Profile Header Card (Figma Exact) ──
                Transform.translate(
                  offset: const Offset(0, -32),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Row: Avatar overlapping top edge + Follow Button
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Avatar sitting over the top card boundary
                              Transform.translate(
                                offset: const Offset(0, -28),
                                child: Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.12,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
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
                                            name.isNotEmpty
                                                ? name[0].toUpperCase()
                                                : 'U',
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 28,
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),

                              const Spacer(),

                              // Follow / Following Button matching Figma
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _buildFollowButton(),
                              ),
                            ],
                          ),

                          // Name
                          Text(
                            name,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111827),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),

                          // Profession / Role
                          Text(
                            profession,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B7280),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Stats Row: 45,200 followers  2 stories  2 milestones
                          Wrap(
                            spacing: 16,
                            runSpacing: 4,
                            children: [
                              _buildStatItem(followersFormatted, 'followers'),
                              _buildStatItem('$storiesCount', 'stories'),
                              _buildStatItem('$milestonesCount', 'milestones'),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // ── Segmented Sub-Tabs Bar: Stories | Milestones | Albums ──
                          _buildSubTabsBar(),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── 3. Tab Content Section ─────────────────────────────────
                Transform.translate(
                  offset: const Offset(0, -18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      children: [
                        if (_selectedSubTab == 0)
                          _buildStoriesTab()
                        else if (_selectedSubTab == 1)
                          _buildMilestonesTab()
                        else
                          _buildAlbumsTab(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),

          // ── Top Navigation Icons Bar (Over the cover) ─────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.share_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _shareProfile,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEA580C), Color(0xFF4A3AFF), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  // Follow Button (Exact Figma visual style)
  Widget _buildFollowButton() {
    if (_isFollowing) {
      return Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: InkWell(
          onTap: _handleFollowToggle,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_rounded,
                size: 15,
                color: Color(0xFF374151),
              ),
              const SizedBox(width: 5),
              Text(
                'Following',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _handleFollowToggle,
      icon: const Icon(Icons.person_add_rounded, size: 15, color: Colors.white),
      label: Text(
        'Follow',
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4A3AFF),
        elevation: 0,
        minimumSize: const Size(96, 36),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF6B7280)),
        children: [
          TextSpan(
            text: count,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          TextSpan(text: ' $label'),
        ],
      ),
    );
  }

  // ── Segmented Sub-Tabs Bar: Stories | Milestones | Albums (Figma Exact) ─
  Widget _buildSubTabsBar() {
    return Row(
      children: [
        Expanded(
          child: _buildTabPill(
            index: 0,
            label: 'Stories',
            icon: Icons.menu_book_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTabPill(
            index: 1,
            label: 'Milestones',
            icon: Icons.military_tech_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTabPill(
            index: 2,
            label: 'Albums',
            icon: Icons.folder_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildTabPill({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedSubTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedSubTab = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A3AFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? null
              : Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab 1: Stories ────────────────────────────────────────────────────────
  Widget _buildStoriesTab() {
    if (_isLoadingContent) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF4A3AFF)),
        ),
      );
    }

    if (_realMemories.isNotEmpty) {
      return Column(
        children: _realMemories.map((m) {
          final tags = m.tags.isNotEmpty ? m.tags : ['Story'];
          return _buildStoryCard(
            tags: tags,
            title: m.title,
            description: m.description ?? '',
            date: m.createdAt != null && m.createdAt!.isNotEmpty
                ? m.createdAt!
                : 'Recent',
            likesCount: m.likesCount,
            commentsCount: m.commentsCount,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MemoryDetailPage(memoryId: m.id),
                ),
              );
            },
          );
        }).toList(),
      );
    }

    // Curated Figma stories (Matches Screen 1 & Screen 2)
    return Column(
      children: [
        _buildStoryCard(
          tags: ['Career', 'Determined'],
          title: 'The Day I Wrote the Compiler',
          description:
              'Everyone said it couldn\'t be done — that computers could only understand numbers. I believed otherwise. We needed a language people could read, so I built the A-0 system.',
          date: 'September 9, 1952',
          likesCount: 3820,
          commentsCount: 241,
        ),
        const SizedBox(height: 14),
        _buildStoryCard(
          tags: ['Milestone', 'Courageous'],
          title: 'My First Day in the Navy',
          description:
              'The uniform was stiff and unfamiliar, but I wore it like armor. I was determined to prove that only purpose knows no gender, taking on the challenge with unwavering dedication.',
          date: 'September 7, 1952',
          likesCount: 6820,
          commentsCount: 141,
        ),
      ],
    );
  }

  Widget _buildStoryCard({
    required List<String> tags,
    required String title,
    required String description,
    required String date,
    required int likesCount,
    required int commentsCount,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E0FD), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tags Row
            Wrap(
              spacing: 8,
              children: tags.map((tag) {
                final isPrimary = tags.indexOf(tag) == 0;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? const Color(0xFFEDE9FE)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isPrimary
                          ? const Color(0xFF4A3AFF)
                          : const Color(0xFF4B5563),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            // Title
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
                letterSpacing: -0.2,
              ),
            ),

            const SizedBox(height: 6),

            // Description Snippet
            Text(
              description,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF4B5563),
                height: 1.45,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 14),

            // Footer: Date & Reaction Counts
            Row(
              children: [
                Text(
                  date,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.favorite_border_rounded,
                  size: 15,
                  color: Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 4),
                Text(
                  NumberFormat.compact().format(likesCount),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 14,
                  color: Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 4),
                Text(
                  NumberFormat.compact().format(commentsCount),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 2: Milestones Vertical Timeline (Matches Figma Screen 3) ─────────
  Widget _buildMilestonesTab() {
    final milestones = [
      {
        'title': 'Received the Presidential Medal of Freedom',
        'year': '2016',
        'category': 'Honor',
        'description':
            'Posthumously awarded by President Barack Obama for her contributions to computing and the Navy. Recognized for her pioneering work in programming languages.',
        'icon': Icons.emoji_events_outlined,
      },
      {
        'title': 'The Moment to Promoted to Rear Admiral',
        'year': '1985',
        'category': 'Career',
        'description':
            'Became one of the first female flag officers in naval history and a trailblazer for women in defense and computing.',
        'icon': Icons.star_outline_rounded,
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: milestones.length,
      itemBuilder: (context, index) {
        final m = milestones[index];
        final isLast = index == milestones.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connected Vertical Track + Circular Icon Node
              Column(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF4A3AFF),
                        width: 1.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF4A3AFF,
                          ).withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      m['icon'] as IconData,
                      color: const Color(0xFF4A3AFF),
                      size: 18,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 1.5,
                        color: const Color(0xFFD1D5DB),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 12),

              // Milestone Card matching Figma Screen 3
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE2E0FD),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              m['title'] as String,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF111827),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              m['category'] as String,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m['year'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        m['description'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF4B5563),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Tab 3: Albums ────────────────────────────────────────────────────────
  Widget _buildAlbumsTab() {
    final albums = [
      {
        'title': 'Naval Service Archives',
        'subtitle': 'Photographs & documents from WWII to 1986',
        'entries': 24,
        'cover':
            'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=600',
      },
      {
        'title': 'Computing Milestones',
        'subtitle': 'Harvard Mark I and UNIVAC pioneering moments',
        'entries': 18,
        'cover':
            'https://images.unsplash.com/photo-1518770660439-4636190af475?q=80&w=600',
      },
    ];

    return Column(
      children: albums.map((alb) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E0FD), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                alb['cover'] as String,
                width: 54,
                height: 54,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 54,
                  height: 54,
                  color: const Color(0xFFEDE9FE),
                  child: const Icon(
                    Icons.photo_album_rounded,
                    color: Color(0xFF4A3AFF),
                  ),
                ),
              ),
            ),
            title: Text(
              alb['title'] as String,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  alb['subtitle'] as String,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${alb['entries']} entries',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4A3AFF),
                  ),
                ),
              ],
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF9CA3AF),
            ),
          ),
        );
      }).toList(),
    );
  }
}
