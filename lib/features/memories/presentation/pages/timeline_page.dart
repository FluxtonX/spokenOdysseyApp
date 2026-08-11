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
  const TimelinePage({super.key});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Top Segmented Pill Toggle (All Memories vs Albums)
          Container(
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _selectedTab = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedTab == 0
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'All Memories',
                      style: GoogleFonts.outfit(
                        color: _selectedTab == 0
                            ? Colors.white
                            : AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _selectedTab = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedTab == 1
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Albums',
                      style: GoogleFonts.outfit(
                        color: _selectedTab == 1
                            ? Colors.white
                            : AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: _selectedTab == 0
                ? _buildMemoriesTab()
                : _buildAlbumsTab(),
          ),
        ],
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
