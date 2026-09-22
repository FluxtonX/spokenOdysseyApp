import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/media_url_formatter.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../memories/domain/entities/memory_entity.dart';
import '../../../memories/presentation/cubits/memories_cubit.dart';
import '../../../memories/presentation/pages/memory_detail_page.dart';
import '../../../memories/presentation/widgets/memory_card.dart';
import '../../../memories/presentation/widgets/publish_wizard_modal.dart';
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
      builder: (_) => BlocProvider(
        create: (_) => sl<MemoriesCubit>(),
        child: PublishWizardModal(initialAlbumId: widget.albumId),
      ),
    ).then((res) {
      if (res == true) {
        _loadAlbum();
      }
    });
  }

  Future<void> _editAlbum() async {
    if (_album == null) return;
    final titleCtrl = TextEditingController(text: _album!.title);
    final descCtrl = TextEditingController(text: _album!.description ?? '');
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Text(
              'Edit Album',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: titleCtrl,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'Album Title',
                labelStyle: GoogleFonts.outfit(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              style: GoogleFonts.outfit(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                labelStyle: GoogleFonts.outfit(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && mounted) {
      try {
        final repo = sl<AlbumsRepository>();
        final updated = await repo.updateAlbum(
          albumId: widget.albumId,
          title: titleCtrl.text.trim().isEmpty ? null : titleCtrl.text.trim(),
          description: descCtrl.text.trim(),
        );
        if (mounted) setState(() => _album = updated);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update album: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
    titleCtrl.dispose();
    descCtrl.dispose();
  }

  Future<void> _deleteAlbum() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Album?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will permanently delete "${_album?.title ?? 'this album'}" and remove all memories from it. This action cannot be undone.',
          style: GoogleFonts.outfit(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await sl<AlbumsRepository>().deleteAlbum(widget.albumId);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete album: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
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
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.textPrimary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (value) {
              if (value == 'add') _openCreateMemoryForAlbum();
              if (value == 'edit') _editAlbum();
              if (value == 'delete') _deleteAlbum();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'add',
                child: Row(
                  children: [
                    const Icon(Icons.add_rounded, size: 20, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text('Add Memory', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit_rounded, size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Text('Edit Album', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_rounded, size: 20, color: AppColors.error),
                    const SizedBox(width: 10),
                    Text('Delete Album', style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? AsyncStateView(
              isLoading: false,
              errorMessage: _error,
              isEmpty: false,
              emptyTitle: '',
              emptyMessage: '',
              onRetry: _loadAlbum,
              child: const SizedBox.shrink(),
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
                                  AppButton(
                                    expand: false,
                                    icon: Icons.add_rounded,
                                    label: 'Add memory',
                                    onPressed: _openCreateMemoryForAlbum,
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
