import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../albums/domain/entities/album_entity.dart';
import '../../../albums/domain/repositories/albums_repository.dart';
import '../cubits/memories_cubit.dart';

class CreateMemoryModal extends StatefulWidget {
  final String? initialAudioPath;
  final String? initialAlbumId;

  const CreateMemoryModal({
    super.key,
    this.initialAudioPath,
    this.initialAlbumId,
  });

  @override
  State<CreateMemoryModal> createState() => _CreateMemoryModalState();
}

class _CreateMemoryModalState extends State<CreateMemoryModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  String _privacy = 'Public';
  String? _mediaPath;
  String? _mediaType;
  String? _selectedAlbumId;
  List<AlbumEntity> _availableAlbums = [];
  bool _isLoadingAlbums = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _selectedAlbumId = widget.initialAlbumId;
    if (widget.initialAudioPath != null) {
      _mediaPath = widget.initialAudioPath;
      _mediaType = 'audio';
    }
    _loadUserAlbums();
  }

  Future<void> _loadUserAlbums() async {
    try {
      final albums = await sl<AlbumsRepository>().getAlbums();
      if (mounted) {
        setState(() {
          _availableAlbums = albums;
          _isLoadingAlbums = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingAlbums = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _mediaPath = picked.path;
        _mediaType = 'image';
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<MemoriesCubit>();

    final success = await cubit.createMemory(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      mediaPath: _mediaPath,
      mediaType: _mediaType,
      privacy: _privacy,
      tags: tags,
      albumId: _selectedAlbumId,
    );

    if (mounted) {
      setState(() => _isUploading = false);
      if (success) {
        nav.pop(true);
        messenger.showSnackBar(
          const SnackBar(content: Text('Memory saved to your Odyssey!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create Memory',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title *',
                  hintText: 'e.g. My Childhood Memories',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 12),

              // Album Dropdown Selector
              Text(
                'Add to Album (Optional)',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Builder(
                builder: (context) {
                  final uniqueAlbumsMap = <String, AlbumEntity>{};
                  for (final album in _availableAlbums) {
                    if (album.id.isNotEmpty) {
                      uniqueAlbumsMap[album.id] = album;
                    }
                  }
                  final uniqueAlbums = uniqueAlbumsMap.values.toList();
                  final bool isSelectedValid = _selectedAlbumId != null &&
                      uniqueAlbums.any((a) => a.id == _selectedAlbumId);
                  final String? activeDropdownValue = isSelectedValid ? _selectedAlbumId : null;

                  return DropdownButtonFormField<String?>(
                    value: activeDropdownValue,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.folder_special_rounded, color: AppColors.primary),
                    ),
                    hint: Text(_isLoadingAlbums ? 'Loading albums...' : 'Select Album (Optional)'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('None (General Feed)'),
                      ),
                      ...uniqueAlbums.map((album) {
                        return DropdownMenuItem<String?>(
                          value: album.id,
                          child: Text(
                            album.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedAlbumId = val);
                    },
                  );
                },
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Tell the story behind this memory...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Tags
              TextFormField(
                controller: _tagsController,
                decoration: InputDecoration(
                  labelText: 'Tags (comma separated)',
                  hintText: 'childhood, advice, family',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Privacy Selector
              Text(
                'Privacy Setting',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _privacyOption('Public', 'Public', Icons.public_rounded),
                  const SizedBox(width: 8),
                  _privacyOption('Family', 'Family Only', Icons.people_rounded),
                  const SizedBox(width: 8),
                  _privacyOption('Private', 'Private', Icons.lock_rounded),
                ],
              ),
              const SizedBox(height: 16),

              // Media Status / Attach Photo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    Icon(
                      _mediaType == 'audio'
                          ? Icons.mic_rounded
                          : Icons.image_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _mediaPath != null
                            ? 'Attached: ${_mediaPath!.split('/').last}'
                            : 'No media attached yet',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                      label: const Text('Photo'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Save Memory',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _privacyOption(String key, String label, IconData icon) {
    final isSelected = _privacy == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _privacy = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderLight,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
