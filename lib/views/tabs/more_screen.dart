import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/theme.dart';
import '../../theme/typography.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../customWidgets/custom_text_field.dart';
import 'insights_view.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController controller = Get.put(SettingsController());
    final AuthController authController = Get.find<AuthController>();

    return Obx(() {
      final int subPage = controller.activeSubPage.value;
      final bool isMenu = subPage == -1;

      return Scaffold(
        backgroundColor: Colors.white,
        appBar: isMenu ? null : _buildAppBar(context, controller, isMenu),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _buildCurrentPage(controller, authController, subPage),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCurrentPage(
    SettingsController controller,
    AuthController authController,
    int subPage,
  ) {
    switch (subPage) {
      case 0:
        return _buildProfileTab(controller);
      case 1:
        return _buildPrivacyTab(controller, authController);
      case 2:
        return InsightsView();
      default:
        return _buildSettingsMenu(controller, authController);
    }
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    SettingsController controller,
    bool isMenu,
  ) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: isMenu
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
              onPressed: () => controller.activeSubPage.value = -1,
            ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isMenu ? 'Settings' : _getPageTitle(controller.activeSubPage.value),
            style: AppTextStyles.h1,
          ),
          if (isMenu)
            Text(
              'Manage your profile and see Insights',
              style: AppTextStyles.bodySmall,
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
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        Text(
          'Settings',
          style: AppTextStyles.h1,
        ),
        const SizedBox(height: 8),
        Text(
          'Manage your profile and see Insights',
          style: AppTextStyles.bodyMedium,
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
          'Security',
          style: AppTextStyles.labelBold,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (iconColor ?? AppTheme.primary).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor ?? AppTheme.primary, size: 22),
        ),
        title: Text(
          title,
          style: AppTextStyles.labelBold,
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.caption,
        ),
        trailing: Icon(Icons.chevron_right, color: AppTheme.textHint, size: 20),
      ),
    );
  }

  Widget _buildBiometricTile(SettingsController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              controller.biometricType.value == 'Face ID'
                  ? Icons.face
                  : Icons.fingerprint,
              color: AppTheme.primary,
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
                  style: AppTextStyles.labelBold,
                ),
                Text(
                  'Enable secure biometric access',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Switch(
            value: controller.isBiometricEnabled.value,
            onChanged: (val) => controller.toggleBiometrics(val),
            activeColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(SettingsController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Profile',
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: 8),
          Text(
            'This is how others will see you',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 32),

          // Profile Image Section
          Text('Profile Photo', style: _labelStyle()),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: const Color(0xFF5D5FEF),
                child: Text(
                  'JA',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Change Photo'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(140, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 110),
            child: Text(
              'JPG or PNG, Max 5MB.',
              style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textHint),
            ),
          ),
          const SizedBox(height: 25),

          // Cover Image Section
          Text('Cover Image', style: _labelStyle()),
          const SizedBox(height: 12),
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF1EFE9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.file_upload_outlined,
                  size: 30,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(height: 10),
                Text(
                  'Drag or tap to upload cover image',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Form Fields
          CustomTextField(
            label: 'Display Name',
            controller: controller.displayNameController,
            hintText: 'John Anderson',
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Profession',
            controller: controller.professionController,
            hintText: 'Technology Executive',
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Location',
            controller: controller.locationController,
            hintText: 'San Francisco, CA',
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Birth Date',
            controller: controller.birthDateController,
            hintText: 'Feb-03-1980',
            suffixIcon: Icons.calendar_today,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Bio',
            controller: controller.bioController,
            maxLines: 4,
            hintText: 'Tell us about yourself...',
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Life Motto',
            controller: controller.lifeMottoController,
            maxLines: 2,
            hintText: 'Your philosophy...',
          ),
          const SizedBox(height: 30),

          // Expertise Section
          Text('Areas of Expertise', style: _labelStyle()),
          const SizedBox(height: 12),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.expertise
                  .map(
                    (item) => Chip(
                      label: Text(
                        item,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF5D5FEF),
                        ),
                      ),
                      backgroundColor: const Color(0xFF5D5FEF).withOpacity(0.1),
                      deleteIcon: const Icon(
                        Icons.close,
                        size: 14,
                        color: Color(0xFF5D5FEF),
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
          ),
          const SizedBox(height: 12),
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
                  backgroundColor: const Color(0xFF5D5FEF),
                  minimumSize: const Size(80, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Save Button
          ElevatedButton(
            onPressed: () => controller.saveChanges(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(
                0xFFF1EFE9,
              ), // Match screenshot's light gray/beige button
              foregroundColor: AppTheme.textSecondary,
              minimumSize: const Size(double.infinity, 55),
              elevation: 0,
            ),
            child: const Text('Save Changes'),
          ),
          const SizedBox(height: 50),
        ],
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
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
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
                  onTap:
                      () {}, // Implement dropdown logic if needed or just mockup for now
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
                  onTap: () {},
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
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: AppTextStyles.bodyMedium,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppTheme.textPrimary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(AuthController authController) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Log Out',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: AppTheme.textSecondary),
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

  TextStyle _labelStyle() {
    return AppTextStyles.labelBold;
  }
}
