import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_url_formatter.dart';
import '../cubits/albums_cubit.dart';
import '../widgets/create_album_modal.dart';
import 'album_detail_page.dart';

class AlbumsPage extends StatefulWidget {
  const AlbumsPage({super.key});

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  @override
  void initState() {
    super.initState();
    context.read<AlbumsCubit>().loadAlbums();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Memory Albums',
          style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => BlocProvider.value(
                  value: context.read<AlbumsCubit>(),
                  child: const CreateAlbumModal(),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<AlbumsCubit, AlbumsState>(
        builder: (context, state) {
          if (state is AlbumsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AlbumsLoaded) {
            if (state.albums.isEmpty) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_album_outlined, size: 64, color: AppColors.textLight),
                      const SizedBox(height: 12),
                      Text(
                        'No Albums Created Yet',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Organize your voice stories into themed albums.',
                        style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            builder: (_) => BlocProvider.value(
                              value: context.read<AlbumsCubit>(),
                              child: const CreateAlbumModal(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: Text('Create First Album', style: GoogleFonts.outfit(color: Colors.white)),
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AlbumDetailPage(albumId: album.id)),
                    );
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
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: cover != null
                                ? Image.network(
                                    cover,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _placeholderCover(),
                                  )
                                : _placeholderCover(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                album.title,
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${album.memoriesCount} memories',
                                style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
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
          } else if (state is AlbumsError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _placeholderCover() {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: const Center(
        child: Icon(Icons.folder_special_rounded, size: 44, color: AppColors.primary),
      ),
    );
  }
}
