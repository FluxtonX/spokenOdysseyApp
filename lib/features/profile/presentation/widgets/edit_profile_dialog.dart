import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/user.dart';
import '../cubits/profile_cubit.dart';

class EditProfileDialog extends StatefulWidget {
  final User user;

  const EditProfileDialog({super.key, required this.user});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _relationshipController;
  String? _avatarPath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name ?? '');
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _locationController = TextEditingController(text: widget.user.location ?? '');
    _relationshipController = TextEditingController(text: widget.user.relationship ?? '');
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _avatarPath = picked.path);
    }
  }

  void _submit() async {
    setState(() => _isSaving = true);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<ProfileCubit>();

    final success = await cubit.updateProfile(
          displayName: _nameController.text.trim(),
          bio: _bioController.text.trim(),
          location: _locationController.text.trim(),
          relationship: _relationshipController.text.trim(),
          avatarPath: _avatarPath,
        );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        nav.pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Edit Profile', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),

            // Avatar picker
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: const Icon(Icons.person_rounded, size: 40, color: AppColors.primary),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _bioController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Bio / Personal Mission',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : Text('Save Changes', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
