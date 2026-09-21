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

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: TextField(
                      onChanged: (val) =>
                          context.read<MemoriesCubit>().searchMemories(val),
                      decoration: InputDecoration(
                        hintText: 'Search milestones...',
                        hintStyle: GoogleFonts.outfit(
                          color: AppColors.textSecondary,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.textSecondary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${displayList.length} milestones',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (!state.isGridView) {
                                      context
                                          .read<MemoriesCubit>()
                                          .toggleViewMode();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: state.isGridView
                                          ? const Color(0xFF5E4EE8)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.grid_view_rounded,
                                      size: 20,
                                      color: state.isGridView
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    if (state.isGridView) {
                                      context
                                          .read<MemoriesCubit>()
                                          .toggleViewMode();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: !state.isGridView
                                          ? const Color(0xFF5E4EE8)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.view_list_rounded,
                                      size: 20,
                                      color: !state.isGridView
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: state.isGridView
                            ? SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      childAspectRatio: 0.55,
                                    ),
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final memory = displayList[index];
                                  return MemoryCard(
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
                                  );
                                }, childCount: displayList.length),
                              )
                            : SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final memory = displayList[index];
                                  return Stack(
                                    children: [
                                      // Continuous Left Timeline Vertical Line
                                      Positioned(
                                        left: 4,
                                        top: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 2,
                                          color: const Color(
                                            0xFF5E4EE8,
                                          ).withValues(alpha: 0.2),
                                        ),
                                      ),
                                      // Blue Square Node Marker
                                      Positioned(
                                        left: 1,
                                        top: 22,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF5E4EE8),
                                            borderRadius: BorderRadius.circular(
                                              1,
                                            ),
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
                                                .reactToMemory(memory.id, type);
                                          },
                                          onDelete: () {
                                            context
                                                .read<MemoriesCubit>()
                                                .deleteMemory(memory.id);
                                          },
                                        ),
                                      ),
                                    ],
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
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: TextField(
                      onChanged: (val) {
                        context.read<FollowersCubit>().searchFollowers(val);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search followers...',
                        hintStyle: GoogleFonts.outfit(
                          color: AppColors.textSecondary,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.textSecondary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${state.searchResults.length} followers',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
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
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F1FE), // Very light purple
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(
                                0xFF5E4EE8,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child:
                                    user.avatarUrl != null &&
                                        user.avatarUrl!.isNotEmpty
                                    ? Image.network(
                                        user.avatarUrl!,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _buildAvatarPlaceholder(),
                                      )
                                    : _buildAvatarPlaceholder(),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          user.name ?? 'Unknown',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF5E4EE8,
                                            ).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            badgeText,
                                            style: GoogleFonts.outfit(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF5E4EE8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      user.bio ?? 'No bio provided.',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Align(
                                alignment: Alignment.topRight,
                                child: GestureDetector(
                                  onTap: () {
                                    context.read<FollowersCubit>().toggleFollow(
                                      user,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: user.isFollowing
                                          ? Colors.transparent
                                          : const Color(0xFF5E4EE8),
                                      border: Border.all(
                                        color: const Color(0xFF5E4EE8),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (user.isFollowing)
                                          const Icon(
                                            Icons.check,
                                            size: 12,
                                            color: Color(0xFF5E4EE8),
                                          )
                                        else
                                          const Icon(
                                            Icons.add,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                        const SizedBox(width: 4),
                                        Text(
                                          user.isFollowing
                                              ? 'Following'
                                              : 'Follow Back',
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
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
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (state.followers.isNotEmpty)
                    Center(
                      child: OutlinedButton(
                        onPressed: () {
                          // Load more functionality (pagination placeholder)
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF5E4EE8)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Load More Followers',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF5E4EE8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
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
      width: 50,
      height: 50,
      color: Colors.grey.shade200,
      child: const Icon(Icons.person, color: Colors.grey),
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
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search memories...',
                          hintStyle: GoogleFonts.outfit(
                            color: AppColors.textSecondary,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.textSecondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${state.memories.length} memories',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (!state.isGridView) {
                                        context
                                            .read<MemoriesCubit>()
                                            .toggleViewMode();
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: state.isGridView
                                            ? const Color(0xFF5E4EE8)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.grid_view_rounded,
                                        size: 20,
                                        color: state.isGridView
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      if (state.isGridView) {
                                        context
                                            .read<MemoriesCubit>()
                                            .toggleViewMode();
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: !state.isGridView
                                            ? const Color(0xFF5E4EE8)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.view_list_rounded,
                                        size: 20,
                                        color: !state.isGridView
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (state.memories.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Text(
                              'No memories found.\nTry a different search or be the first to record a memory!',
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
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: state.isGridView
                              ? SliverGrid(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                        childAspectRatio: 0.55,
                                      ),
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final memory = state.memories[index];
                                    return MemoryCard(
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
                                    );
                                  }, childCount: state.memories.length),
                                )
                              : SliverList(
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final memory = state.memories[index];
                                    return Stack(
                                      children: [
                                        // Continuous Left Timeline Vertical Line
                                        Positioned(
                                          left: 4,
                                          top: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 2,
                                            color: const Color(
                                              0xFF5E4EE8,
                                            ).withValues(alpha: 0.2),
                                          ),
                                        ),
                                        // Blue Square Node Marker
                                        Positioned(
                                          left: 1,
                                          top: 22,
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF5E4EE8),
                                              borderRadius:
                                                  BorderRadius.circular(1),
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
          // Trigger load if not already loading (extra safety net).
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
            // Empty state matching the exact screenshot layout
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 72,
                      color: AppColors.textPrimary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 16),
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
                      'Create albums in the Albums tab to organize your memories',
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

              return GestureDetector(
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
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: cover != null
                              ? Image.network(
                                  cover,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _albumPlaceholderCover(),
                                )
                              : _albumPlaceholderCover(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              album.title,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${album.memoriesCount} memories',
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
      color: AppColors.primary.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(
          Icons.photo_album_outlined,
          size: 40,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
