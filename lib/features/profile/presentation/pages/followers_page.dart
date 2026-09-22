import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/media_url_formatter.dart';
import '../../../auth/domain/entities/user.dart';
import '../cubits/followers_cubit.dart';
import '../cubits/followers_state.dart';
import 'public_profile_page.dart';

class FollowersPage extends StatefulWidget {
  final int initialTabIndex; // 0 = Followers, 1 = Following

  const FollowersPage({super.key, this.initialTabIndex = 0});

  @override
  State<FollowersPage> createState() => _FollowersPageState();
}

class _FollowersPageState extends State<FollowersPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FollowersCubit>(
      create: (_) {
        final cubit = sl<FollowersCubit>()..loadFollowers();
        if (widget.initialTabIndex == 1) {
          cubit.setTab('following');
        }
        return cubit;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF9FD),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Connections',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: BlocBuilder<FollowersCubit, FollowersState>(
          builder: (context, state) {
            if (state is FollowersLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (state is FollowersError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 44,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Unable to load connections',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            context.read<FollowersCubit>().loadFollowers(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is FollowersLoaded) {
              final isFollowingTab = state.selectedTab == 'following';
              final currentList = state.searchResults;

              return Column(
                children: [
                  // Tab selector: Followers vs Following
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(
                      children: [
                        Container(
                          height: 44,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _TabButton(
                                  label:
                                      'Followers (${state.followers.length})',
                                  isSelected: !isFollowingTab,
                                  onTap: () {
                                    _searchController.clear();
                                    context.read<FollowersCubit>().setTab(
                                      'followers',
                                    );
                                  },
                                ),
                              ),
                              Expanded(
                                child: _TabButton(
                                  label:
                                      'Following (${state.following.length})',
                                  isSelected: isFollowingTab,
                                  onTap: () {
                                    _searchController.clear();
                                    context.read<FollowersCubit>().setTab(
                                      'following',
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Search bar
                        Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => context
                                .read<FollowersCubit>()
                                .searchFollowers(val),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: isFollowingTab
                                  ? 'Search people you follow...'
                                  : 'Search followers...',
                              hintStyle: GoogleFonts.outfit(
                                fontSize: 13,
                                color: const Color(0xFF9CA3AF),
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: Color(0xFF9CA3AF),
                                size: 18,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear_rounded,
                                        size: 16,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        context
                                            .read<FollowersCubit>()
                                            .searchFollowers('');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content list
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () =>
                          context.read<FollowersCubit>().loadFollowers(),
                      child: currentList.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 40),
                                Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        isFollowingTab
                                            ? Icons.person_add_disabled_rounded
                                            : Icons.people_outline_rounded,
                                        size: 54,
                                        color: const Color(0xFFD1D5DB),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        isFollowingTab
                                            ? 'Not following anyone yet'
                                            : 'No followers found',
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isFollowingTab
                                            ? 'Explore extraordinary people on the Discover page'
                                            : 'Share your archive memories to grow your circle',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (state.suggestions.isNotEmpty) ...[
                                  const SizedBox(height: 36),
                                  _SuggestedSection(
                                    suggestions: state.suggestions,
                                    onToggleFollow: (u) => context
                                        .read<FollowersCubit>()
                                        .toggleFollow(u),
                                  ),
                                ],
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              itemCount: currentList.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, idx) {
                                final person = currentList[idx];
                                return _PersonTile(
                                  person: person,
                                  onToggleFollow: () => context
                                      .read<FollowersCubit>()
                                      .toggleFollow(person),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PublicProfilePage(person: person),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

// ── Tab Button ────────────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

// ── Person Tile ───────────────────────────────────────────────────────────────

class _PersonTile extends StatelessWidget {
  final User person;
  final VoidCallback onToggleFollow;
  final VoidCallback onTap;

  const _PersonTile({
    required this.person,
    required this.onToggleFollow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = person.avatarUrl;
    final name = person.name ?? person.email.split('@').first;
    final isFollowing = person.isFollowing;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECEEF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFF4A3AFF),
          backgroundImage: avatar != null && avatar.isNotEmpty
              ? NetworkImage(MediaUrlFormatter.format(avatar)!)
              : null,
          child: avatar == null || avatar.isEmpty
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                )
              : null,
        ),
        title: Text(
          name,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (person.bio != null && person.bio!.isNotEmpty)
              Text(
                person.bio!,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 2),
            Text(
              '${person.memoriesCount} memories • ${person.followersCount} followers',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
        trailing: SizedBox(
          height: 34,
          child: OutlinedButton(
            onPressed: onToggleFollow,
            style: OutlinedButton.styleFrom(
              backgroundColor: isFollowing
                  ? const Color(0xFFF3F4F6)
                  : AppColors.primary,
              foregroundColor: isFollowing
                  ? const Color(0xFF374151)
                  : Colors.white,
              side: BorderSide(
                color: isFollowing
                    ? const Color(0xFFD1D5DB)
                    : AppColors.primary,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              isFollowing ? 'Following' : 'Follow',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Suggested People Section ──────────────────────────────────────────────────

class _SuggestedSection extends StatelessWidget {
  final List<User> suggestions;
  final void Function(User) onToggleFollow;

  const _SuggestedSection({
    required this.suggestions,
    required this.onToggleFollow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Suggested for you',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, idx) {
              final u = suggestions[idx];
              final name = u.name ?? u.email.split('@').first;

              return Container(
                width: 130,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFECEEF2)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF4A3AFF),
                      backgroundImage:
                          u.avatarUrl != null && u.avatarUrl!.isNotEmpty
                          ? NetworkImage(
                              MediaUrlFormatter.format(u.avatarUrl!)!,
                            )
                          : null,
                      child: u.avatarUrl == null || u.avatarUrl!.isEmpty
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 28,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => onToggleFollow(u),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: u.isFollowing
                              ? const Color(0xFFF3F4F6)
                              : AppColors.primary,
                          foregroundColor: u.isFollowing
                              ? const Color(0xFF374151)
                              : Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          u.isFollowing ? 'Following' : 'Follow',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
