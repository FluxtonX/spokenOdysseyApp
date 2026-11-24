import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/utils/media_url_formatter.dart';
import '../../../albums/presentation/cubits/albums_cubit.dart';
import '../../../albums/presentation/pages/album_detail_page.dart';
import '../../../albums/presentation/widgets/create_album_modal.dart';
import '../../../connectivity/presentation/cubit/connectivity_cubit.dart';
import '../cubits/memories_cubit.dart';
import '../widgets/memory_card.dart';
import 'memory_detail_page.dart';
import '../../../profile/presentation/cubits/followers_cubit.dart';
import '../../../profile/presentation/cubits/followers_state.dart';

class TimelinePage extends StatefulWidget {
  final int initialTab;
  const TimelinePage({super.key, this.initialTab = 0});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage>
    with AutomaticKeepAliveClientMixin {
  late int _selectedTab;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safety net: if MemoriesCubit is still in its initial state (no load
    // was triggered at creation), kick off the feed load now.
    final memoriesState = context.read<MemoriesCubit>().state;
    if (memoriesState is MemoriesInitial) {
      context.read<MemoriesCubit>().loadMemories();
    }
    // Same for AlbumsCubit.
    final albumsState = context.read<AlbumsCubit>().state;
    if (albumsState is AlbumsInitial) {
      context.read<AlbumsCubit>().loadAlbums();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<MemoriesCubit>().searchMemories(query);
    });
  }

  /// Back online after showing the offline copy (or an error): reload.
  void _onConnectivityChanged(BuildContext context, ConnectivityState _) {
    final cubit = context.read<MemoriesCubit>();
    final current = cubit.state;
    if (current is MemoriesError ||
        (current is MemoriesLoaded && current.isOffline)) {
      cubit.loadMemories(forceRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<ConnectivityCubit, ConnectivityState>(
      listenWhen: (previous, current) =>
          !previous.isOnline && current.isOnline,
      listener: _onConnectivityChanged,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppSegmentedControl(
              selectedIndex: _selectedTab,
              labels: const [
                'All Memories',
                'Albums',
                'Milestones',
                'Followers',
              ],
              onChanged: (index) => setState(() => _selectedTab = index),
            ),
          ),
          const SizedBox(height: 12),

          Expanded(child: _getSelectedTabWidget()),
        ],
      ),
    );
  }

  Widget _getSelectedTabWidget() {
    switch (_selectedTab) {
      case 0:
        return _buildMemoriesTab();
      case 1:
        return _buildAlbumsTab();
      case 2:
        return _buildMilestonesTab();
      case 3:
        return _buildFollowersTab();
      default:
        return _buildMemoriesTab();
    }
  }

  Widget _buildMilestonesTab() {
    return RefreshIndicator(
      onRefresh: () => context.read<MemoriesCubit>().loadMemories(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(
                    hintText: 'Search milestones...',
                    onChanged: (val) =>
                        context.read<MemoriesCubit>().searchMemories(val),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          BlocBuilder<MemoriesCubit, MemoriesState>(
            builder: (context, state) {
              if (state is MemoriesLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (state is MemoriesLoaded) {
                final milestones = state.memories.where((m) {
                  final tags = m.tags.map((tag) => tag.toLowerCase()).toList();
                  final title = m.title.toLowerCase();
                  return tags.contains('milestone') ||
                      tags.contains('career & growth') ||
                      tags.contains('turning point') ||
                      tags.contains('proud') ||
                      title.contains('milestone');
                }).toList();

                final displayList = milestones;

                return SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${displayList.length} milestones',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            _buildViewToggle(state.isGridView),
                          ],
                        ),
                      ),
                    ),
                    if (displayList.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'No milestones found.',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        sliver: state.isGridView
                            ? SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 0.55,
                                    ),
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final memory = displayList[index];
                                  return _FadeSlideIn(
                                    index: index,
                                    child: MemoryCard(
                                      memory: memory,
                                      isGridMode: true,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => MemoryDetailPage(
                                              memoryId: memory.id,
                                            ),
                                          ),
                                        );
                                      },
                                      onReact: (type) {
                                        context
                                            .read<MemoriesCubit>()
                                            .reactToMemory(memory.id, type);
                                      },
                                      onDelete: () {
                                        context
                                            .read<MemoriesCubit>()
                                            .deleteMemory(memory.id);
                                      },
                                    ),
                                  );
                                }, childCount: displayList.length),
                              )
                            : SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final memory = displayList[index];
                                  return _FadeSlideIn(
                                    index: index,
                                    child: Stack(
                                      children: [
                                        // Continuous Left Timeline Vertical Line
                                        Positioned(
                                          left: 4,
                                          top: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 2,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  const Color(
                                                    0xFF5E4EE8,
                                                  ).withValues(alpha: 0.3),
                                                  const Color(
                                                    0xFF5E4EE8,
                                                  ).withValues(alpha: 0.1),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Purple Glowing Square Node Marker
                                        Positioned(
                                          left: 1,
                                          top: 22,
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF5E4EE8),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF5E4EE8,
                                                  ).withValues(alpha: 0.4),
                                                  blurRadius: 4,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Memory Card
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 18,
                                            bottom: 16,
                                          ),
                                          child: MemoryCard(
                                            memory: memory,
                                            isGridMode: false,
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      MemoryDetailPage(
                                                        memoryId: memory.id,
                                                      ),
                                                ),
                                              );
                                            },
                                            onReact: (type) {
                                              context
                                                  .read<MemoriesCubit>()
                                                  .reactToMemory(
                                                    memory.id,
                                                    type,
                                                  );
                                            },
                                            onDelete: () {
                                              context
                                                  .read<MemoriesCubit>()
                                                  .deleteMemory(memory.id);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }, childCount: displayList.length),
                              ),
                      ),
                  ],
                );
              }
              return const SliverToBoxAdapter(child: SizedBox());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFollowersTab() {
    return BlocProvider.value(
      value: context.read<FollowersCubit>(),
      child: BlocBuilder<FollowersCubit, FollowersState>(
        builder: (context, state) {
          if (state is FollowersLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is FollowersLoaded) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(
                    hintText: 'Search followers...',
                    onChanged: (val) {
                      context.read<FollowersCubit>().searchFollowers(val);
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${state.searchResults.length} followers',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: state.searchResults.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final user = state.searchResults[index];
                        final badgeText = user.relationship ?? 'Follower';
                        return _FadeSlideIn(
                          index: index,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(
                                  0xFF5E4EE8,
                                ).withValues(alpha: 0.12),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(
                                          0xFF5E4EE8,
                                        ).withValues(alpha: 0.7),
                                        const Color(
                                          0xFF7000FF,
                                        ).withValues(alpha: 0.7),
                                      ],
                                    ),
                                  ),
                                  child: ClipOval(
                                    child:
                                        user.avatarUrl != null &&
                                            user.avatarUrl!.isNotEmpty
                                        ? Image.network(
                                            user.avatarUrl!,
                                            width: 46,
                                            height: 46,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _buildAvatarPlaceholder(),
                                          )
                                        : _buildAvatarPlaceholder(),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              user.name ?? 'Unknown',
                                              style: GoogleFonts.outfit(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                                color: AppColors.textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF5E4EE8,
                                              ).withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              badgeText,
                                              style: GoogleFonts.outfit(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF5E4EE8),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (user.bio != null &&
                                          user.bio!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          user.bio!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(
                                            fontSize: 12.5,
                                            color: AppColors.textSecondary,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () {
                                      context
                                          .read<FollowersCubit>()
                                          .toggleFollow(user);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: user.isFollowing
                                            ? Colors.transparent
                                            : const Color(0xFF5E4EE8),
                                        border: Border.all(
                                          color: const Color(0xFF5E4EE8),
                                          width: 1.2,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: user.isFollowing
                                            ? null
                                            : [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF5E4EE8,
                                                  ).withValues(alpha: 0.25),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            user.isFollowing
                                                ? Icons.check_rounded
                                                : Icons.add_rounded,
                                            size: 13,
                                            color: user.isFollowing
                                                ? const Color(0xFF5E4EE8)
                                                : Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            user.isFollowing
                                                ? 'Following'
                                                : 'Follow Back',
                                            style: GoogleFonts.outfit(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: user.isFollowing
                                                  ? const Color(0xFF5E4EE8)
                                                  : Colors.white,
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
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (state.followers.isNotEmpty)
                    Center(
                      child: OutlinedButton(
                        onPressed: () {
                          // Load more functionality
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: const Color(
                              0xFF5E4EE8,
                            ).withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        child: Text(
                          'Load More Followers',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF5E4EE8),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          } else if (state is FollowersError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFF5E4EE8).withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person_rounded,
        color: Color(0xFF5E4EE8),
        size: 24,
      ),
    );
  }

  Widget _buildMemoriesTab() {
    return RefreshIndicator(
      onRefresh: () => context.read<MemoriesCubit>().loadMemories(),
      child: BlocListener<MemoriesCubit, MemoriesState>(
        listener: (context, state) {
          if (state is MemoriesLoaded && state.actionError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.actionError!),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(
                      controller: _searchController,
                      hintText: 'Search memories...',
                      onChanged: _onSearchChanged,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            BlocBuilder<MemoriesCubit, MemoriesState>(
              builder: (context, state) {
                if (state is MemoriesLoading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (state is MemoriesLoaded) {
                  return SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                state.isOffline
                                    ? 'Offline · showing ${state.memories.length} saved ${state.memories.length == 1 ? 'memory' : 'memories'}'
                                    : '${state.memories.length} memories',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              _buildViewToggle(state.isGridView),
                            ],
                          ),
                        ),
                      ),
                      if (state.memories.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Text(
                              state.isOffline
                                  ? "You're offline.\nYour latest memories will appear here once you've been online."
                                  : 'No memories found.\nTry a different search or be the first to record a memory!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          sliver: state.isGridView
                              ? SliverGrid(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: 0.55,
                                      ),
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final memory = state.memories[index];
                                    return _FadeSlideIn(
                                      index: index,
                                      child: MemoryCard(
                                        memory: memory,
                                        isGridMode: true,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => MemoryDetailPage(
                                                memoryId: memory.id,
                                              ),
                                            ),
                                          );
                                        },
                                        onReact: (type) {
                                          context
                                              .read<MemoriesCubit>()
                                              .reactToMemory(memory.id, type);
                                        },
                                        onDelete: () {
                                          context
                                              .read<MemoriesCubit>()
                                              .deleteMemory(memory.id);
                                        },
                                      ),
                                    );
                                  }, childCount: state.memories.length),
                                )
                              : SliverList(
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final memory = state.memories[index];
                                    return _FadeSlideIn(
                                      index: index,
                                      child: Stack(
                                        children: [
                                          // Continuous Left Timeline Vertical Line
                                          Positioned(
                                            left: 4,
                                            top: 0,
                                            bottom: 0,
                                            child: Container(
                                              width: 2,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    const Color(
                                                      0xFF5E4EE8,
                                                    ).withValues(alpha: 0.3),
                                                    const Color(
                                                      0xFF5E4EE8,
                                                    ).withValues(alpha: 0.1),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Purple Glowing Square Node Marker
                                          Positioned(
                                            left: 1,
                                            top: 22,
                                            child: Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF5E4EE8),
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(
                                                      0xFF5E4EE8,
                                                    ).withValues(alpha: 0.4),
                                                    blurRadius: 4,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          // Memory Card
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 18,
                                              bottom: 16,
                                            ),
                                            child: MemoryCard(
                                              memory: memory,
                                              isGridMode: false,
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        MemoryDetailPage(
                                                          memoryId: memory.id,
                                                        ),
                                                  ),
                                                );
                                              },
                                              onReact: (type) {
                                                context
                                                    .read<MemoriesCubit>()
                                                    .reactToMemory(
                                                      memory.id,
                                                      type,
                                                    );
                                              },
                                              onDelete: () {
                                                context
                                                    .read<MemoriesCubit>()
                                                    .deleteMemory(memory.id);
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }, childCount: state.memories.length),
                                ),
                        ),
                    ],
                  );
                } else if (state is MemoriesError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        state.message,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumsTab() {
    return BlocBuilder<AlbumsCubit, AlbumsState>(
      builder: (context, state) {
        if (state is AlbumsInitial) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted &&
                context.read<AlbumsCubit>().state is AlbumsInitial) {
              context.read<AlbumsCubit>().loadAlbums();
            }
          });
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AlbumsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is AlbumsLoaded) {
          if (state.albums.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5E4EE8).withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.photo_library_outlined,
                        size: 40,
                        color: Color(0xFF5E4EE8),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No albums yet',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create albums to organize your special voice memories into curated collections',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.82,
            ),
            itemCount: state.albums.length,
            itemBuilder: (context, index) {
              final album = state.albums[index];
              final cover = MediaUrlFormatter.format(album.coverPhotoUrl);

              return _FadeSlideIn(
                index: index,
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AlbumDetailPage(albumId: album.id),
                      ),
                    );
                    if (context.mounted) {
                      context.read<AlbumsCubit>().loadAlbums();
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.borderLight.withValues(alpha: 0.6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                cover != null
                                    ? Image.network(
                                        cover,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _albumPlaceholderCover(),
                                      )
                                    : _albumPlaceholderCover(),
                                // Subtle bottom gradient overlay
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  height: 36,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.35),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Memories badge
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.mic_none_rounded,
                                          size: 11,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${album.memoriesCount}',
                                          style: GoogleFonts.outfit(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  album.title,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${album.memoriesCount} ${album.memoriesCount == 1 ? "memory" : "memories"}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  Widget _albumPlaceholderCover() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF5E4EE8).withValues(alpha: 0.15),
            const Color(0xFF7000FF).withValues(alpha: 0.08),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.photo_library_outlined,
          size: 38,
          color: Color(0xFF5E4EE8),
        ),
      ),
    );
  }

  Widget _buildSearchBar({
    TextEditingController? controller,
    required String hintText,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF5E4EE8).withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.outfit(
            color: AppColors.textSecondary.withValues(alpha: 0.7),
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF5E4EE8),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildViewToggle(bool isGridView) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF5E4EE8).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              if (!isGridView) {
                context.read<MemoriesCubit>().toggleViewMode();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isGridView
                    ? const Color(0xFF5E4EE8)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                boxShadow: isGridView
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFF5E4EE8,
                          ).withValues(alpha: 0.35),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.grid_view_rounded,
                size: 17,
                color: isGridView ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: () {
              if (isGridView) {
                context.read<MemoriesCubit>().toggleViewMode();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: !isGridView
                    ? const Color(0xFF5E4EE8)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                boxShadow: !isGridView
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFF5E4EE8,
                          ).withValues(alpha: 0.35),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.view_list_rounded,
                size: 17,
                color: !isGridView ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;

  const _FadeSlideIn({required this.child, required this.index});

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
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
