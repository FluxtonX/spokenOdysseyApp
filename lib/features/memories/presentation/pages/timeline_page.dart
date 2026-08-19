import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_url_formatter.dart';
import '../../../albums/presentation/cubits/albums_cubit.dart';
import '../../../albums/presentation/pages/album_detail_page.dart';
import '../../../albums/presentation/widgets/create_album_modal.dart';
import '../cubits/memories_cubit.dart';
import '../widgets/memory_card.dart';
import 'memory_detail_page.dart';

class TimelinePage extends StatefulWidget {
  final int initialTab;
  const TimelinePage({super.key, this.initialTab = 0});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Top Segmented Pill Toggle (Scrollable)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              showsHorizontalScrollIndicator: false,
              child: Row(
                children: [
                  _buildTabButton(0, 'All Memories'),
                  const SizedBox(width: 8),
                  _buildTabButton(1, 'Albums'),
                  const SizedBox(width: 8),
                  _buildTabButton(2, 'Milestones'),
                  const SizedBox(width: 8),
                  _buildTabButton(3, 'Followers'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: _getSelectedTabWidget(),
          ),
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

  Widget _buildTabButton(int index, String label) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMilestonesTab() {
    return Center(
      child: Text(
        'Milestones coming soon.',
        style: GoogleFonts.outfit(
          fontSize: 16,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildFollowersTab() {
    return Center(
      child: Text(
        'Followers coming soon.',
        style: GoogleFonts.outfit(
          fontSize: 16,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildMemoriesTab() {
    return RefreshIndicator(
      onRefresh: () => context.read<MemoriesCubit>().loadFeedMemories(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Community & Family Feed',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
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
                if (state.memories.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No memories found in feed.\nBe the first to record a memory!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final memory = state.memories[index];
                      return MemoryCard(
                        memory: memory,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MemoryDetailPage(memoryId: memory.id),
                            ),
                          );
                        },
                        onReact: (type) {
                          context.read<MemoriesCubit>().reactToMemory(
                            memory.id,
                            type,
                          );
                        },
                        onDelete: () {
                          context.read<MemoriesCubit>().deleteMemory(memory.id);
                        },
                      );
                    }, childCount: state.memories.length),
                  ),
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
    );
  }

  Widget _buildAlbumsTab() {
    return BlocBuilder<AlbumsCubit, AlbumsState>(
      builder: (context, state) {
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
                      color: AppColors.textPrimary.withOpacity(0.7),
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
                        color: Colors.black.withOpacity(0.04),
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
      color: AppColors.primary.withOpacity(0.1),
      child: const Center(
        child: Icon(Icons.photo_album_outlined,
            size: 40, color: AppColors.primary),
      ),
    );
  }
}
