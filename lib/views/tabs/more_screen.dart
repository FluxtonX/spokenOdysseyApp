import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/theme.dart';
import '../../theme/typography.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../customWidgets/custom_text_field.dart';
import '../../utils/image_picker_helper.dart';
import 'insights_view.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  late final SettingsController controller;
  late final AuthController authController;
  late final ThemeController themeController;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>()
        : Get.put(SettingsController());
    authController = Get.find<AuthController>();
    themeController = Get.find<ThemeController>();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final int subPage = controller.activeSubPage.value;
      final bool isMenu = subPage == -1;

      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: isMenu ? null : _buildAppBar(context, controller, isMenu),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _buildCurrentPage(
                  context,
                  controller,
                  authController,
                  themeController,
                  subPage,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCurrentPage(
    BuildContext context,
    SettingsController controller,
    AuthController authController,
    ThemeController themeController,
    int subPage,
  ) {
    switch (subPage) {
      case 0:
        return _buildProfileTab(context, controller, authController);
      case 1:
        return _buildPrivacyTab(controller, authController);
      case 2:
        return InsightsView();
      default:
        return _buildSettingsMenu(controller, authController, themeController);
    }
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    SettingsController controller,
    bool isMenu,
  ) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: isMenu
          ? null
          : IconButton(
              icon: Icon(Icons.arrow_back, color: _primaryTextColor()),
              onPressed: () => controller.activeSubPage.value = -1,
            ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isMenu ? 'Settings' : _getPageTitle(controller.activeSubPage.value),
            style: AppTextStyles.h1.copyWith(color: _primaryTextColor()),
          ),
          if (isMenu)
            Text(
              'Manage your profile and see Insights',
              style: AppTextStyles.bodySmall.copyWith(
                color: _secondaryTextColor(),
              ),
            ),
        ],
      ),
      centerTitle: false,
    );
  }

  String _getPageTitle(int subPage) {
    switch (subPage) {
      case 0:
        return 'Your Profile';
      case 1:
        return 'Privacy & Security';
      case 2:
        return 'Insights';
      default:
        return 'Settings';
    }
  }

  Widget _buildSettingsMenu(
    SettingsController controller,
    AuthController authController,
    ThemeController themeController,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        Text(
          'Settings',
          style: AppTextStyles.h1.copyWith(color: _primaryTextColor()),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage your profile and see Insights',
          style: AppTextStyles.bodyMedium.copyWith(
            color: _secondaryTextColor(),
          ),
        ),
        const SizedBox(height: 32),
        _buildMenuTile(
          icon: Icons.person_outline,
          title: 'Profile Details',
          subtitle: 'Update your display name, photo, and bio',
          onTap: () => controller.activeSubPage.value = 0,
        ),
        _buildMenuTile(
          icon: Icons.bar_chart_outlined,
          title: 'Visual Insights',
          subtitle: 'View your archive activity and impact',
          onTap: () => controller.activeSubPage.value = 2,
        ),
        _buildMenuTile(
          icon: Icons.lock_outline,
          title: 'Privacy & Security',
          subtitle: 'Manage your visibility and encryption',
          onTap: () => controller.activeSubPage.value = 1,
        ),
        const SizedBox(height: 32),
        Text(
          'Appearance',
          style: AppTextStyles.labelBold.copyWith(color: _primaryTextColor()),
        ),
        const SizedBox(height: 16),
        Obx(() => _buildThemeTile(themeController)),
        const SizedBox(height: 32),
        Text(
          'Security',
          style: AppTextStyles.labelBold.copyWith(color: _primaryTextColor()),
        ),
        const SizedBox(height: 16),
        Obx(() => _buildBiometricTile(controller)),
        const SizedBox(height: 48),
        _buildMenuTile(
          icon: Icons.logout,
          title: 'Log Out',
          subtitle: 'Safely exit your account',
          iconColor: AppTheme.error,
          textColor: AppTheme.error,
          onTap: () => _showLogoutDialog(authController),
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    final isDark = Get.isDarkMode;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _softSurfaceColor(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor()),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (iconColor ?? _accentColor()).withValues(
              alpha: isDark ? 0.18 : 0.1,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor ?? _accentColor(), size: 22),
        ),
        title: Text(
          title,
          style: AppTextStyles.labelBold.copyWith(
            color: textColor ?? _primaryTextColor(),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.caption.copyWith(color: _secondaryTextColor()),
        ),
        trailing: Icon(Icons.chevron_right, color: _hintTextColor(), size: 20),
      ),
    );
  }

  Widget _buildThemeTile(ThemeController controller) {
    final isDark = Get.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _softSurfaceColor(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor()),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _accentColor().withValues(alpha: isDark ? 0.22 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              controller.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: _accentColor(),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.isDarkMode ? 'Dark Theme' : 'Light Theme',
                  style: AppTextStyles.labelBold.copyWith(
                    color: _primaryTextColor(),
                  ),
                ),
                Text(
                  'Switch your interface mood instantly and keep it saved.',
                  style: AppTextStyles.caption.copyWith(
                    color: _secondaryTextColor(),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: controller.isDarkMode,
            onChanged: controller.toggleTheme,
            activeTrackColor: _accentColor(),
            activeThumbColor: Colors.white,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: _borderColor(),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricTile(SettingsController controller) {
    final isDark = Get.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _softSurfaceColor(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor()),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _accentColor().withValues(alpha: isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              controller.biometricType.value == 'Face ID'
                  ? Icons.face
                  : Icons.fingerprint,
              color: _accentColor(),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${controller.biometricType.value} Login',
                  style: AppTextStyles.labelBold.copyWith(
                    color: _primaryTextColor(),
                  ),
                ),
                Text(
                  'Enable secure biometric access',
                  style: AppTextStyles.caption.copyWith(
                    color: _secondaryTextColor(),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: controller.isBiometricEnabled.value,
            onChanged: (val) => controller.toggleBiometrics(val),
            activeTrackColor: _accentColor(),
            activeThumbColor: Colors.white,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: _borderColor(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(
    BuildContext context,
    SettingsController controller,
    AuthController authController,
  ) {
    return Obx(
      () => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Profile', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            Text(
              'Shape how your story, identity, and expertise appear across the archive.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: _secondaryTextColor(),
              ),
            ),
            const SizedBox(height: 24),
            _buildProfilePreviewCard(controller, authController),
            const SizedBox(height: 24),
            _buildProfileSection(
              title: 'Photos',
              subtitle: 'Choose a profile photo and atmospheric cover image.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildProfileAvatar(controller),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _pickProfileImage(context, controller),
                              icon: const Icon(
                                Icons.camera_alt_outlined,
                                size: 18,
                              ),
                              label: const Text('Change Photo'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(140, 46),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'JPG or PNG, Max 5MB.',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: _hintTextColor(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () => _pickCoverImage(context, controller),
                    child: _buildCoverCard(controller),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildProfileSection(
              title: 'Identity',
              subtitle: 'Basic details that help frame your archive.',
              child: Column(
                children: [
                  CustomTextField(
                    label: 'Display Name',
                    controller: controller.displayNameController,
                    hintText: 'John Anderson',
                  ),
                  const SizedBox(height: 18),
                  CustomTextField(
                    label: 'Profession',
                    controller: controller.professionController,
                    hintText: 'Technology Executive',
                  ),
                  const SizedBox(height: 18),
                  CustomTextField(
                    label: 'Location',
                    controller: controller.locationController,
                    hintText: 'San Francisco, CA',
                  ),
                  const SizedBox(height: 18),
                  CustomTextField(
                    label: 'Birth Date',
                    controller: controller.birthDateController,
                    hintText: 'Feb-03-1980',
                    suffixIcon: Icons.calendar_today,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildProfileSection(
              title: 'Story',
              subtitle:
                  'Give your profile emotional context and a memorable point of view.',
              child: Column(
                children: [
                  CustomTextField(
                    label: 'Bio',
                    controller: controller.bioController,
                    maxLines: 4,
                    hintText: 'Tell us about yourself...',
                  ),
                  const SizedBox(height: 18),
                  CustomTextField(
                    label: 'Life Motto',
                    controller: controller.lifeMottoController,
                    maxLines: 2,
                    hintText: 'Your philosophy...',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildProfileSection(
              title: 'Expertise',
              subtitle:
                  'Surface the themes and skills people should immediately associate with you.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: controller.expertise
                        .map(
                          (item) => Chip(
                            label: Text(
                              item,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: _accentColor(),
                              ),
                            ),
                            backgroundColor: _accentColor().withValues(
                              alpha: Get.isDarkMode ? 0.22 : 0.1,
                            ),
                            deleteIcon: Icon(
                              Icons.close,
                              size: 14,
                              color: _accentColor(),
                            ),
                            onDeleted: () => controller.removeExpertise(item),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide.none,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: controller.expertiseInputController,
                          hintText: 'Add expertise area...',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => controller.addExpertise(
                          controller.expertiseInputController.text,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor(),
                          minimumSize: const Size(80, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Obx(
              () => ElevatedButton(
                onPressed: controller.isSavingProfile.value
                    ? null
                    : () => controller.saveChanges(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor(),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  elevation: 0,
                ),
                child: controller.isSavingProfile.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Profile'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyTab(
    SettingsController controller,
    AuthController authController,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Control who can see your content',
            style: AppTextStyles.bodyMedium.copyWith(
              color: _secondaryTextColor(),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _surfaceColor(),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: _borderColor()),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: Get.isDarkMode ? 0.16 : 0.01,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Default Entry Privacy
                Text(
                  'Default Entry Privacy',
                  style: AppTextStyles.labelBold.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  'New memories will use this privacy setting by default',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 16),
                _buildPrivacySelector(
                  value: controller.defaultEntryPrivacy.value,
                  onTap: () => _showOptionSelector(
                    title: 'Default Entry Privacy',
                    options: controller.privacyOptions,
                    selectedValue: controller.defaultEntryPrivacy.value,
                    onSelected: controller.setDefaultEntryPrivacy,
                  ),
                ),
                const SizedBox(height: 32),

                // Profile Visibility
                Text(
                  'Profile Visibility',
                  style: AppTextStyles.labelBold.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  'Who can view your profile and public stories',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 16),
                _buildPrivacySelector(
                  value: controller.profileVisibility.value,
                  onTap: () => _showOptionSelector(
                    title: 'Profile Visibility',
                    options: controller.visibilityOptions,
                    selectedValue: controller.profileVisibility.value,
                    onSelected: controller.setProfileVisibility,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPrivacySelector({
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: _softSurfaceColor(),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _borderColor()),
        ),
        child: Row(
          children: [
            Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
            Icon(
              Icons.keyboard_arrow_down,
              color: _primaryTextColor(),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickProfileImage(
    BuildContext context,
    SettingsController controller,
  ) async {
    final image = await ImagePickerHelper.pickWithSourceSheet(
      context,
      imageQuality: 88,
      maxWidth: 1400,
    );
    if (image != null) {
      controller.setProfileImage(image);
    }
  }

  Future<void> _pickCoverImage(
    BuildContext context,
    SettingsController controller,
  ) async {
    final image = await ImagePickerHelper.pickWithSourceSheet(
      context,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (image != null) {
      controller.setCoverImage(image);
    }
  }

  Widget _buildProfilePreviewCard(
    SettingsController controller,
    AuthController authController,
  ) {
    final userEmail =
        authController.firebaseUser.value?.email ?? 'archive member';
    final completion = controller.profileCompletion.clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor(),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _borderColor()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Get.isDarkMode ? 0.18 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: SizedBox(
              height: 170,
              width: double.infinity,
              child: _buildCoverMedia(controller),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.translate(
                  offset: const Offset(0, -36),
                  child: _buildProfileAvatar(controller, radius: 38),
                ),
                Transform.translate(
                  offset: const Offset(0, -18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.displayNameController.text.trim().isEmpty
                            ? 'Your Name'
                            : controller.displayNameController.text.trim(),
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: _primaryTextColor(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.professionController.text.trim().isEmpty
                            ? userEmail
                            : '${controller.professionController.text.trim()} • ${controller.locationController.text.trim().isEmpty ? userEmail : controller.locationController.text.trim()}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: _secondaryTextColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        controller.bioController.text.trim().isEmpty
                            ? 'Add a short biography so family and future readers understand who you are and what matters to you.'
                            : controller.bioController.text.trim(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          height: 1.6,
                          color: _primaryTextColor(),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Profile completeness',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: _secondaryTextColor(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: completion,
                                    minHeight: 8,
                                    backgroundColor: _softSurfaceColor(),
                                    valueColor: AlwaysStoppedAnimation(
                                      _accentColor(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${(completion * 100).round()}%',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _primaryTextColor(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(
    SettingsController controller, {
    double radius = 45,
  }) {
    final imageFile = controller.profileImageFile.value;
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Get.isDarkMode ? AppTheme.darkScaffoldBg : Colors.white,
          width: 4,
        ),
        color: _accentColor(),
      ),
      child: ClipOval(
        child: imageFile != null
            ? Image.file(imageFile, fit: BoxFit.cover)
            : Center(
                child: Text(
                  controller.profileInitials,
                  style: GoogleFonts.outfit(
                    fontSize: radius * 0.45,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCoverCard(SettingsController controller) {
    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildCoverMedia(controller),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.06),
                  Colors.black.withValues(alpha: 0.28),
                ],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Cover Image',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to upload a background that sets the mood of your archive.',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          height: 1.5,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.photo_camera_back_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverMedia(SettingsController controller) {
    final file = controller.coverImageFile.value;
    if (file != null) {
      return Image.file(file, fit: BoxFit.cover);
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2532), Color(0xFF5A6174), Color(0xFFB89A81)],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Add a meaningful cover',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor(),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _borderColor()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Get.isDarkMode ? 0.14 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _primaryTextColor(),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 13,
              height: 1.5,
              color: _secondaryTextColor(),
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  void _showOptionSelector({
    required String title,
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: _surfaceColor(),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _borderColor(),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _primaryTextColor(),
                ),
              ),
              const SizedBox(height: 16),
              ...options.map((option) {
                final selected = option == selectedValue;
                return GestureDetector(
                  onTap: () {
                    onSelected(option);
                    Get.back();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _softSurfaceColor(),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected ? _accentColor() : _borderColor(),
                        width: selected ? 1.4 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _primaryTextColor(),
                            ),
                          ),
                        ),
                        if (selected)
                          Icon(Icons.check_circle, color: _accentColor()),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showLogoutDialog(AuthController authController) {
    Get.dialog(
      AlertDialog(
        backgroundColor: _surfaceColor(),
        title: Text(
          'Log Out',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: _primaryTextColor(),
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.outfit(color: _secondaryTextColor()),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: _secondaryTextColor()),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              authController.logout();
            },
            child: Text(
              'Log Out',
              style: GoogleFonts.outfit(
                color: AppTheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _isDarkTheme => Get.theme.brightness == Brightness.dark;

  Color _surfaceColor() => Get.theme.cardColor;

  Color _softSurfaceColor() =>
      _isDarkTheme ? AppTheme.darkSoftSurface : const Color(0xFFF9FAFB);

  Color _borderColor() => _isDarkTheme ? AppTheme.darkBorder : AppTheme.border;

  Color _primaryTextColor() =>
      _isDarkTheme ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

  Color _secondaryTextColor() =>
      _isDarkTheme ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

  Color _hintTextColor() =>
      _isDarkTheme ? AppTheme.darkTextHint : AppTheme.textHint;

  Color _accentColor() =>
      _isDarkTheme ? const Color(0xFF8B7BFF) : const Color(0xFF5D5FEF);
}
