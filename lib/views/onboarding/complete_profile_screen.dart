import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../customWidgets/custom_text_field.dart';
import '../../services/profile_service.dart';
import '../../theme/theme.dart';
import '../../utils/image_picker_helper.dart';
import '../tabs/main_tab_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key, this.initialProfile});

  final Map<String, dynamic>? initialProfile;

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameController;
  late final TextEditingController _bioController;
  late final TextEditingController _locationController;

  bool _isSaving = false;
  String _defaultPrivacy = 'Private - Only by you';
  File? _profileImageFile;
  String? _existingPhotoUrl;

  final List<String> _privacyOptions = const [
    'Private - Only by you',
    'Family - Your family circle',
    'Public - Everyone',
  ];

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile ?? const <String, dynamic>{};

    _displayNameController = TextEditingController(
      text: profile['displayName']?.toString() ?? '',
    );
    _bioController = TextEditingController(
      text: profile['bio']?.toString() ?? '',
    );
    _locationController = TextEditingController(
      text: profile['location']?.toString() ?? '',
    );
    _defaultPrivacy =
        profile['defaultEntryPrivacy']?.toString().trim().isNotEmpty == true
        ? profile['defaultEntryPrivacy'].toString()
        : _defaultPrivacy;
    _existingPhotoUrl = profile['photoURL']?.toString();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_profileImageFile == null &&
        !(_existingPhotoUrl?.trim().isNotEmpty ?? false)) {
      Get.snackbar(
        'Add a profile photo',
        'Choose a profile photo before you continue into the app.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _profileService.updateProfile({
        'displayName': _displayNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'location': _locationController.text.trim(),
        'defaultEntryPrivacy': _defaultPrivacy,
        'onboardingCompleted': true,
        'profileCompleted': true,
      }, profileImageFile: _profileImageFile);

      if (!mounted) return;
      Get.offAll(() => const MainTabScreen(initialIndex: 0));
      Get.snackbar(
        'Archive ready',
        'Your profile is saved. You can start recording your first memory now.',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
    } catch (error) {
      if (!mounted) return;
      Get.snackbar(
        'Could not save profile',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickProfileImage() async {
    final file = await ImagePickerHelper.pickWithSourceSheet(context);
    if (file == null) {
      return;
    }

    setState(() {
      _profileImageFile = file;
      _existingPhotoUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5544FF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: Color(0xFF5544FF),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Complete your profile',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.adaptiveTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Before we drop you into the app, let us save the essentials to MongoDB so your archive starts with the right identity and privacy defaults.',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    height: 1.6,
                    color: AppTheme.adaptiveTextSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.adaptiveCardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.adaptiveBorder),
                    ),
                    child: Row(
                      children: [
                        _buildProfileAvatar(),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _profileImageFile != null ||
                                        (_existingPhotoUrl?.isNotEmpty ?? false)
                                    ? 'Profile photo ready'
                                    : 'Add a profile photo',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.adaptiveTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Give your archive a face before you step into the app. You can change it again later from Settings.',
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  height: 1.5,
                                  color: AppTheme.adaptiveTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF5544FF,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _profileImageFile != null ||
                                    (_existingPhotoUrl?.isNotEmpty ?? false)
                                ? 'Change'
                                : 'Upload',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF5544FF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.adaptiveSoftSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.adaptiveBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What we will set up right now',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.adaptiveTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildSetupPoint(Icons.person_outline, 'Display name'),
                      const SizedBox(height: 10),
                      _buildSetupPoint(
                        Icons.auto_stories_outlined,
                        'Short bio',
                      ),
                      const SizedBox(height: 10),
                      _buildSetupPoint(
                        Icons.lock_outline_rounded,
                        'Default privacy',
                      ),
                      const SizedBox(height: 10),
                      _buildSetupPoint(
                        Icons.family_restroom_outlined,
                        'Invite family later if you want',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  label: 'Display Name',
                  controller: _displayNameController,
                  prefixIcon: Icons.person_outline,
                  hintText: 'How should your archive address you?',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your display name';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  label: 'Short Bio',
                  controller: _bioController,
                  prefixIcon: Icons.auto_stories_outlined,
                  hintText:
                      'A short line about who you are and what matters to you',
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please add a short bio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  label: 'Location',
                  controller: _locationController,
                  prefixIcon: Icons.place_outlined,
                  hintText: 'City, country, or a place that feels like home',
                ),
                const SizedBox(height: 18),
                Text(
                  'Default Privacy',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.adaptiveTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _defaultPrivacy,
                  decoration: const InputDecoration(
                    hintText: 'Choose your archive default',
                  ),
                  items: _privacyOptions
                      .map(
                        (option) => DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _defaultPrivacy = value;
                    });
                  },
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.adaptiveSoftSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.adaptiveBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.family_restroom_outlined,
                        color: Color(0xFF5ABA82),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invite family later',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.adaptiveTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'You can skip family setup for now and invite contributors or custodians after your archive feels ready.',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                height: 1.55,
                                color: AppTheme.adaptiveTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF5ABA82,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Skip for now',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2B8A5A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5544FF),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Start Recording'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final hasRemoteImage = _existingPhotoUrl?.trim().isNotEmpty ?? false;

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF5544FF).withValues(alpha: 0.12),
      ),
      clipBehavior: Clip.antiAlias,
      child: _profileImageFile != null
          ? Image.file(_profileImageFile!, fit: BoxFit.cover)
          : hasRemoteImage
          ? Image.network(
              _existingPhotoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildInitialsAvatar(),
            )
          : _buildInitialsAvatar(),
    );
  }

  Widget _buildInitialsAvatar() {
    return Center(
      child: Text(
        _initials,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF5544FF),
        ),
      ),
    );
  }

  Widget _buildSetupPoint(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.adaptiveTextSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.adaptiveTextSecondary,
            ),
          ),
        ),
      ],
    );
  }

  String get _initials {
    final text = _displayNameController.text.trim();
    if (text.isEmpty) {
      return 'SO';
    }

    final parts = text.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.length == 1) {
      final word = parts.first;
      return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
