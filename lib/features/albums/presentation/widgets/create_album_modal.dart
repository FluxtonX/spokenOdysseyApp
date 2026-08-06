import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubits/albums_cubit.dart';

class CreateAlbumModal extends StatefulWidget {
  const CreateAlbumModal({super.key});

  @override
  State<CreateAlbumModal> createState() => _CreateAlbumModalState();
}

class _CreateAlbumModalState extends State<CreateAlbumModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _coverPath;
  bool _isCreating = false;

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _coverPath = picked.path);
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<AlbumsCubit>();

    final success = await cubit.createAlbum(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      coverPhotoPath: _coverPath,
    );

    if (mounted) {
      setState(() => _isCreating = false);
      if (success) {
        nav.pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Album created successfully!')),
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
                    'Create New Album',
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

              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Album Title *',
                  hintText: 'e.g. Grandparents Life Stories',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Album title required'
                    : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'What memories belong in this album?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Cover Photo Picker
              GestureDetector(
                onTap: _pickCoverImage,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: _coverPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            File(_coverPath!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                'Cover Selected: ${_coverPath!.split('/').last}',
                                style: GoogleFonts.outfit(fontSize: 12),
                              ),
                            ),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_photo_alternate_rounded,
                              size: 32,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Upload Cover Photo',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isCreating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Create Album',
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
}
