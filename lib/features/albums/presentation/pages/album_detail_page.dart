import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/media_url_formatter.dart';
import '../../../memories/domain/entities/memory_entity.dart';
import '../../../memories/presentation/cubits/memories_cubit.dart';
import '../../../memories/presentation/pages/memory_detail_page.dart';
import '../../../memories/presentation/widgets/create_memory_modal.dart';
import '../../../memories/presentation/widgets/memory_card.dart';
import '../../domain/entities/album_entity.dart';
import '../../domain/repositories/albums_repository.dart';

class AlbumDetailPage extends StatefulWidget {
  final String albumId;

  const AlbumDetailPage({super.key, required this.albumId});

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  AlbumEntity? _album;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlbum();
  }

  Future<void> _loadAlbum() async {
    try {
      setState(() => _isLoading = true);
      final repo = sl<AlbumsRepository>();
      final album = await repo.getAlbumDetails(widget.albumId);
      setState(() {
        _album = album;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _openCreateMemoryForAlbum() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: sl<MemoriesCubit>(),
        child: CreateMemoryModal(initialAlbumId: widget.albumId),
      ),
    ).then((res) {
      if (res == true) {
        _loadAlbum();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cover = MediaUrlFormatter.format(_album?.coverPhotoUrl);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          _album?.title ?? 'Album Details',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            tooltip: 'Add Memory to Album',
            onPressed: _openCreateMemoryForAlbum,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Cover Banner
                  if (cover != null)
                    Image.network(
                      cover,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _album!.title,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_album!.description != null &&
                            _album!.description!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            _album!.description!,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Memories in this Album (${_album!.memories.length})',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _openCreateMemoryForAlbum,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add Memory'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_album!.memories.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.style_outlined,
                                    size: 48,
                                    color: AppColors.textLight,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No memories in this album yet.',
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  ElevatedButton.icon(
                                    onPressed: _openCreateMemoryForAlbum,
                                    icon: const Icon(
                                      Icons.add_rounded,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      'Add First Memory',
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
                          )
                        else
                          BlocProvider.value(
                            value: sl<MemoriesCubit>(),
                            child: Column(
                              children: _album!.memories.map<Widget>((
                                MemoryEntity m,
                              ) {
                                return MemoryCard(
                                  memory: m,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            MemoryDetailPage(memoryId: m.id),
                                      ),
                                    );
                                  },
                                  onReact: (_) {},
                                );
                              }).toList(),
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
