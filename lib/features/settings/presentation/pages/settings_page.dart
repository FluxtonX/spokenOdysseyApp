import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/asset_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/media_url_formatter.dart';
import '../../../profile/presentation/cubits/profile_cubit.dart';
import '../cubits/settings_cubit.dart';
import '../widgets/mfa_setup_modal.dart';
import 'legacy_vault_page.dart';

import '../../../smart_glasses/presentation/cubit/glasses_cubit.dart';

class SettingsPage extends StatelessWidget {
  final int initialTab;

  const SettingsPage({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProfileCubit>(
          create: (_) => sl<ProfileCubit>()..loadProfile(),
        ),
        BlocProvider<SettingsCubit>(
          create: (_) => sl<SettingsCubit>()..loadSettings(),
        ),
        BlocProvider<GlassesCubit>.value(value: sl<GlassesCubit>()),
      ],
      child: _SettingsViewState(initialTab: initialTab),
    );
  }
}

class _SettingsViewState extends StatefulWidget {
  final int initialTab;

  const _SettingsViewState({this.initialTab = 0});

  @override
  State<_SettingsViewState> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsViewState> {
  late int _selectedTabIndex;

  // Privacy dropdown settings
  String _defaultEntryPrivacy = 'Private - Only by you';
  String _profileVisibility = 'Follower only';
  bool _isSavingPrivacy = false;

  // Profile editing controllers
  late TextEditingController _displayNameController;
  late TextEditingController _professionController;
  late TextEditingController _locationController;
  late TextEditingController _birthDateController;
  late TextEditingController _bioController;
  late TextEditingController _lifeMottoController;
  late TextEditingController _newExpertiseController;

  List<String> _expertiseList = [];
  File? _avatarFile;
  File? _coverFile;
  bool _isSavingProfile = false;

  // Security Controllers & State
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  bool _isChangingPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  List<Map<String, dynamic>> _activeSessions = [];
  bool _isLoadingSessions = false;
  bool _mfaEnabled = false;

  // Notifications State
  bool _pushNotif = true;
  bool _emailNotif = true;
  bool _familyNotif = true;
  bool _communityNotif = true;
  bool _isLoadingNotif = false;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTab;

    final profileState = context.read<ProfileCubit>().state;
    final user = profileState is ProfileLoaded ? profileState.user : null;

    _displayNameController = TextEditingController(
      text: user?.name ?? 'John Anderson',
    );
    _professionController = TextEditingController(
      text: user?.profession?.isNotEmpty == true
          ? user!.profession!
          : 'Technology Executive & Mentor',
    );
    _locationController = TextEditingController(
      text: user?.location?.isNotEmpty == true
          ? user!.location!
          : 'San Francisco, CA',
    );
    _birthDateController = TextEditingController(
      text: user?.birthDate?.isNotEmpty == true
          ? user!.birthDate!
          : (user?.dateOfBirth?.isNotEmpty == true
                ? user!.dateOfBirth!
                : 'Feb-03-1980'),
    );
    _bioController = TextEditingController(
      text: user?.bio?.isNotEmpty == true
          ? user!.bio!
          : 'Documenting my journey and preserving wisdom for the next generation.',
    );
    _lifeMottoController = TextEditingController(
      text: user?.lifeMotto?.isNotEmpty == true
          ? user!.lifeMotto!
          : 'The best time to plant a tree was 20 years ago. The second best time is now.',
    );
    _newExpertiseController = TextEditingController();

    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    if (user?.expertise != null && user!.expertise!.isNotEmpty) {
      _expertiseList = List.from(user.expertise!);
    } else {
      _expertiseList = ['Leadership', 'IT', 'Mentorship'];
    }

    _fetchNotificationData();
    _fetchSecurityData();
  }

  Future<void> _fetchNotificationData() async {
    setState(() => _isLoadingNotif = true);
    final settingsCubit = context.read<SettingsCubit>();
    final prefs = await settingsCubit.getNotificationPreferences();
    if (mounted) {
      setState(() {
        _pushNotif = prefs['push'] ?? true;
        _emailNotif = prefs['email'] ?? true;
        _familyNotif = prefs['familyUpdates'] ?? true;
        _communityNotif = prefs['communityLikes'] ?? true;
        _isLoadingNotif = false;
      });
    }
  }

  Future<void> _fetchSecurityData() async {
    setState(() => _isLoadingSessions = true);
    final settingsCubit = context.read<SettingsCubit>();
    final sessions = await settingsCubit.getActiveSessions();
    final mfaStatus = await settingsCubit.repository.getMfaStatus();
    if (mounted) {
      setState(() {
        _activeSessions = sessions;
        _mfaEnabled = mfaStatus['isEnabled'] ?? false;
        _isLoadingSessions = false;
      });
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _professionController.dispose();
    _locationController.dispose();
    _birthDateController.dispose();
    _bioController.dispose();
    _lifeMottoController.dispose();
    _newExpertiseController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showImageSourceBottomSheet({
    required String title,
    required ValueChanged<ImageSource> onSelectSource,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF1F2937),
                          size: 22,
                        ),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  width: double.infinity,
                  color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(modalContext);
                        onSelectSource(ImageSource.gallery);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEEF2FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  color: Color(0xFF5E4EE8),
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Choose from Gallery',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Upload from your device',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(modalContext);
                        onSelectSource(ImageSource.camera);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEEF2FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.camera_alt_outlined,
                                  color: Color(0xFF5E4EE8),
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Take a Photo',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Use your camera',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _pickAvatar() {
    _showImageSourceBottomSheet(
      title: 'Change Profile Photo',
      onSelectSource: (source) async {
        final picker = ImagePicker();
        final image = await picker.pickImage(source: source, imageQuality: 85);
        if (image != null) {
          setState(() => _avatarFile = File(image.path));
        }
      },
    );
  }

  void _pickCover() {
    _showImageSourceBottomSheet(
      title: 'Change Cover Photo',
      onSelectSource: (source) async {
        final picker = ImagePicker();
        final image = await picker.pickImage(source: source, imageQuality: 85);
        if (image != null) {
          setState(() => _coverFile = File(image.path));
        }
      },
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1985, 3, 15),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF5E4EE8)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final formatted = DateFormat('MMM-dd-yyyy').format(picked);
      setState(() => _birthDateController.text = formatted);
    }
  }

  void _addExpertise() {
    final text = _newExpertiseController.text.trim();
    if (text.isNotEmpty && !_expertiseList.contains(text)) {
      setState(() {
        _expertiseList.add(text);
        _newExpertiseController.clear();
      });
    }
  }

  void _removeExpertise(String item) {
    setState(() => _expertiseList.remove(item));
  }

  Future<void> _saveProfile() async {
    setState(() => _isSavingProfile = true);
    final success = await context.read<ProfileCubit>().updateProfile(
      displayName: _displayNameController.text.trim(),
      profession: _professionController.text.trim(),
      location: _locationController.text.trim(),
      birthDate: _birthDateController.text.trim(),
      bio: _bioController.text.trim(),
      lifeMotto: _lifeMottoController.text.trim(),
      expertise: _expertiseList,
      avatarPath: _avatarFile?.path,
      coverPath: _coverFile?.path,
    );

    if (mounted) {
      setState(() => _isSavingProfile = false);
      _showSnackbar(
        success ? 'Profile updated successfully!' : 'Failed to update profile.',
        isError: !success,
      );
    }
  }

  Future<void> _savePrivacy() async {
    if (_isSavingPrivacy) return;
    setState(() => _isSavingPrivacy = true);
    final success = await context.read<SettingsCubit>().updatePrivacySettings(
      defaultEntryPrivacy: _defaultEntryPrivacy,
      profileVisibility: _profileVisibility,
    );
    if (mounted) {
      setState(() => _isSavingPrivacy = false);
      _showSnackbar(
        success
            ? 'Privacy preferences saved to backend!'
            : 'Failed to update privacy.',
        isError: !success,
      );
    }
  }

  Future<void> _savePassword() async {
    final current = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _showSnackbar('Please fill out all password fields.', isError: true);
      return;
    }
    if (newPass != confirm) {
      _showSnackbar('New passwords do not match.', isError: true);
      return;
    }
    if (newPass.length < 6) {
      _showSnackbar('Password must be at least 6 characters.', isError: true);
      return;
    }

    setState(() => _isChangingPassword = true);
    final success = await context.read<SettingsCubit>().changePassword(
      currentPassword: current,
      newPassword: newPass,
    );
    if (mounted) {
      setState(() => _isChangingPassword = false);
      if (success) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _showSnackbar('Password updated successfully!');
      } else {
        _showSnackbar(
          'Failed to change password. Check your current password.',
          isError: true,
        );
      }
    }
  }

  Future<void> _updateNotification(String key, bool val) async {
    final updated = {
      'push': key == 'push' ? val : _pushNotif,
      'email': key == 'email' ? val : _emailNotif,
      'familyUpdates': key == 'familyUpdates' ? val : _familyNotif,
      'communityLikes': key == 'communityLikes' ? val : _communityNotif,
    };
    setState(() {
      if (key == 'push') _pushNotif = val;
      if (key == 'email') _emailNotif = val;
      if (key == 'familyUpdates') _familyNotif = val;
      if (key == 'communityLikes') _communityNotif = val;
    });

    final success = await context
        .read<SettingsCubit>()
        .updateNotificationPreferences(updated);
    if (!success && mounted) {
      _showSnackbar('Failed to update notification setting.', isError: true);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF5E4EE8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FD),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AssetConstants.bgPic),
            fit: BoxFit.cover,
            opacity: 0.45,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF1F2937),
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Settings',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1F2937),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage account preferences, privacy, and security',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Horizontal Scrollable Segmented Control
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(
                                0xFF5E4EE8,
                              ).withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildSegmentTab(
                                0,
                                'Profile',
                                Icons.person_outline_rounded,
                              ),
                              _buildSegmentTab(
                                1,
                                'Privacy',
                                Icons.lock_outline_rounded,
                              ),
                              _buildSegmentTab(
                                2,
                                'Security',
                                Icons.shield_outlined,
                              ),
                              _buildSegmentTab(
                                3,
                                'Notifications',
                                Icons.notifications_none_rounded,
                              ),
                              _buildSegmentTab(
                                4,
                                'Insights',
                                Icons.analytics_outlined,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tab Contents
                      if (_selectedTabIndex == 0) _buildProfileTab(),
                      if (_selectedTabIndex == 1) _buildPrivacyTab(),
                      if (_selectedTabIndex == 2) _buildSecurityTab(),
                      if (_selectedTabIndex == 3) _buildNotificationsTab(),
                      if (_selectedTabIndex == 4) _buildInsightsTab(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentTab(int index, String title, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTabIndex = index);
        if (index == 2) _fetchSecurityData();
        if (index == 3) _fetchNotificationData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5E4EE8) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF5E4EE8),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF5E4EE8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── TAB 0: PROFILE ────────────────────────────────────────────────────────
  Widget _buildProfileTab() {
    final profileState = context.watch<ProfileCubit>().state;
    final user = profileState is ProfileLoaded ? profileState.user : null;
    final formattedAvatar = MediaUrlFormatter.format(user?.avatarUrl);
    final formattedCover =
        MediaUrlFormatter.format(user?.coverUrl) ??
        'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=1200&q=80';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Profile',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'This is how family and followers see you',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 16),

        // Photos Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF6366F1).withValues(alpha: 0.25),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile & Cover Photo',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _avatarFile != null
                            ? Image.file(_avatarFile!, fit: BoxFit.cover)
                            : (formattedAvatar != null
                                  ? Image.network(
                                      formattedAvatar,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: Colors.white,
                                      child: const Icon(
                                        Icons.person,
                                        size: 36,
                                        color: Color(0xFF5E4EE8),
                                      ),
                                    )),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _pickAvatar,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDE9FE),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFF5E4EE8),
                                    width: 1.2,
                                  ),
                                ),
                                child: Text(
                                  'Change Photo',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF5E4EE8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _pickCover,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFF5E4EE8),
                                    width: 1.2,
                                  ),
                                ),
                                child: Text(
                                  _coverFile != null
                                      ? 'Cover Set'
                                      : (formattedCover.isNotEmpty
                                            ? 'Cover'
                                            : 'Cover'),
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF5E4EE8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'JPG or PNG up to 8MB',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _buildInputField(
          label: 'Display Name',
          controller: _displayNameController,
          hintText: 'Full Name',
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: 'Profession',
          controller: _professionController,
          hintText: 'e.g. Technology Executive',
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: 'Location',
          controller: _locationController,
          hintText: 'e.g. San Francisco, CA',
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: 'Birth Date',
          controller: _birthDateController,
          hintText: 'Select date',
          readOnly: true,
          onTap: _pickBirthDate,
          suffixIcon: const Icon(
            Icons.calendar_today_outlined,
            color: Color(0xFF5E4EE8),
            size: 18,
          ),
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: 'Bio',
          controller: _bioController,
          hintText: 'Your story...',
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: 'Life Motto',
          controller: _lifeMottoController,
          hintText: 'Personal quote...',
          maxLines: 2,
        ),
        const SizedBox(height: 16),

        // Expertise Section
        Text(
          'Areas of Expertise',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _expertiseList.map((exp) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    exp,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5E4EE8),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _removeExpertise(exp),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Color(0xFF5E4EE8),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),
                child: TextField(
                  controller: _newExpertiseController,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFF1F2937),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Add expertise tag...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9CA3AF),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => _addExpertise(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _addExpertise,
              icon: const Icon(
                Icons.add_rounded,
                size: 16,
                color: Colors.white,
              ),
              label: Text(
                'Add',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E4EE8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSavingProfile ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5E4EE8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSavingProfile
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Save Profile Changes',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── TAB 1: PRIVACY ────────────────────────────────────────────────────────
  Widget _buildPrivacyTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy Settings',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Control default visibility and content permissions',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 24),

        _buildDropdownSetting(
          title: 'Default Entry Privacy',
          description:
              'New voice odysseys will default to this visibility setting',
          value: _defaultEntryPrivacy,
          items: const ['Private - Only by you', 'Follower only', 'Public'],
          onChanged: (val) {
            if (val != null) {
              setState(() => _defaultEntryPrivacy = val);
              _savePrivacy();
            }
          },
        ),
        const SizedBox(height: 24),

        _buildDropdownSetting(
          title: 'Profile Visibility',
          description: 'Who can discover your profile and public audio stories',
          value: _profileVisibility,
          items: const ['Follower only', 'Public', 'Private'],
          onChanged: (val) {
            if (val != null) {
              setState(() => _profileVisibility = val);
              _savePrivacy();
            }
          },
        ),

        const SizedBox(height: 28),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LegacyVaultPage()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5E4EE8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Digital Legacy Vault Settings',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        'Manage release conditions & executor contacts',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFF5E4EE8),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── TAB 2: SECURITY ───────────────────────────────────────────────────────
  Widget _buildSecurityTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security & Credentials',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Change password, manage active sessions, and MFA',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 20),

        // Password Form Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF6366F1).withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Change Password',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              _buildPasswordField(
                label: 'Current Password',
                controller: _currentPasswordController,
                obscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              const SizedBox(height: 12),
              _buildPasswordField(
                label: 'New Password',
                controller: _newPasswordController,
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
              const SizedBox(height: 12),
              _buildPasswordField(
                label: 'Confirm New Password',
                controller: _confirmPasswordController,
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _isChangingPassword ? null : _savePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E4EE8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isChangingPassword
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Update Password',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // MFA Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFF5E4EE8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.vibration_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Multi-Factor Auth (MFA)',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      _mfaEnabled
                          ? 'TOTP Authenticator Active'
                          : 'Enhance security with 2FA',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _mfaEnabled,
                activeTrackColor: const Color(0xFF5E4EE8),
                onChanged: (val) async {
                  if (val) {
                    // Show MFA Setup Modal
                    final result = await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      builder: (_) => BlocProvider.value(
                        value: context.read<SettingsCubit>(),
                        child: const MfaSetupModal(),
                      ),
                    );
                    if (result == true) {
                      setState(() => _mfaEnabled = true);
                      _showSnackbar('MFA Successfully Enabled');
                    }
                  } else {
                    // Disable MFA
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Disable MFA?'),
                        content: const Text(
                          'Are you sure you want to disable Two-Factor Authentication? Your account will be less secure.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              'Disable',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      if (!context.mounted) return;
                      final success = await context
                          .read<SettingsCubit>()
                          .disableMfa();
                      if (success) {
                        setState(() => _mfaEnabled = false);
                        _showSnackbar('MFA Disabled');
                      } else {
                        _showSnackbar('Failed to disable MFA', isError: true);
                      }
                    }
                  }
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Active Sessions List
        Text(
          'Active Login Sessions',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 10),
        if (_isLoadingSessions)
          const Center(child: CircularProgressIndicator())
        else if (_activeSessions.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.phone_iphone_rounded,
                  color: Color(0xFF5E4EE8),
                ),
                const SizedBox(width: 12),
                Text(
                  'Current Mobile Device (Active Now)',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: _activeSessions.map((session) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.devices_rounded, color: Color(0xFF5E4EE8)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session['device'] ?? 'Mobile Device',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            session['ip'] ?? 'Active Session',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final success = await context
                            .read<SettingsCubit>()
                            .revokeSession(session['id'] ?? '');
                        if (success) _fetchSecurityData();
                      },
                      child: Text(
                        'Revoke',
                        style: GoogleFonts.outfit(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // ── TAB 3: NOTIFICATIONS ──────────────────────────────────────────────────
  Widget _buildNotificationsTab() {
    if (_isLoadingNotif) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notification Preferences',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage how and when Spoken Odyssey sends alerts',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 20),

        _buildNotificationTile(
          title: 'Push Notifications',
          subtitle: 'Receive real-time push alerts on your mobile device',
          icon: Icons.notifications_active_outlined,
          value: _pushNotif,
          onChanged: (val) => _updateNotification('push', val),
        ),
        const SizedBox(height: 12),
        _buildNotificationTile(
          title: 'Email Notifications & Digest',
          subtitle: 'Receive story summaries and account updates via email',
          icon: Icons.mark_email_unread_outlined,
          value: _emailNotif,
          onChanged: (val) => _updateNotification('email', val),
        ),
        const SizedBox(height: 12),
        _buildNotificationTile(
          title: 'Family Circle Activity',
          subtitle:
              'Alerts when members share stories or join your family tree',
          icon: Icons.family_restroom_rounded,
          value: _familyNotif,
          onChanged: (val) => _updateNotification('familyUpdates', val),
        ),
        const SizedBox(height: 12),
        _buildNotificationTile(
          title: 'Community Likes & Comments',
          subtitle:
              'Notifications when someone interacts with your public stories',
          icon: Icons.favorite_border_rounded,
          value: _communityNotif,
          onChanged: (val) => _updateNotification('communityLikes', val),
        ),
      ],
    );
  }

  // ── TAB 4: INSIGHTS ───────────────────────────────────────────────────────
  Widget _buildInsightsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Archive Insights & Analytics',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your family story repository stats at a glance',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 20),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.25,
          children: [
            _buildInsightCard(
              title: 'Recorded Odysseys',
              value: '24',
              subtitle: 'Voice Memories',
              icon: Icons.mic_rounded,
              color: const Color(0xFF5E4EE8),
            ),
            _buildInsightCard(
              title: 'Audio Hours',
              value: '8.4 hrs',
              subtitle: 'Total Storytelling',
              icon: Icons.schedule_rounded,
              color: const Color(0xFF10B981),
            ),
            _buildInsightCard(
              title: 'Family Members',
              value: '6',
              subtitle: 'Connected Circle',
              icon: Icons.group_rounded,
              color: const Color(0xFFF59E0B),
            ),
            _buildInsightCard(
              title: 'Vault Status',
              value: 'Protected',
              subtitle: 'Legacy Executor Active',
              icon: Icons.verified_user_rounded,
              color: const Color(0xFF6366F1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF5E4EE8), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: const Color(0xFF5E4EE8),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
            decoration: InputDecoration(
              hintText: '••••••••',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF5E4EE8),
                  size: 18,
                ),
                onPressed: onToggle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            readOnly: readOnly,
            onTap: onTap,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF9CA3AF),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownSetting({
    required String title,
    required String description,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF5E4EE8),
              ),
              style: GoogleFonts.outfit(
                color: const Color(0xFF1F2937),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              items: items.map((item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
