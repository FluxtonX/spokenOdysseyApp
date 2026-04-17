import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/theme.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../customWidgets/custom_text_field.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final SettingsController controller = Get.put(SettingsController());
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor:
          Colors.white, // Settings screen uses white BG in screenshot
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildTabSelector(controller),
          Expanded(
            child: Obx(() {
              switch (controller.activeTabIndex.value) {
                case 0:
                  return _buildProfileTab(controller);
                case 1:
                  return _buildPrivacyTab(controller, authController);
                case 2:
                  return _buildInsightsTab();
                default:
                  return const SizedBox();
              }
            }),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
        onPressed: () => Get.back(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            'Manage your profile and see Insights',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      centerTitle: false,
    );
  }

  Widget _buildTabSelector(SettingsController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Container(
        height: 50,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1EFE9), // Match theme beige
          borderRadius: BorderRadius.circular(12),
        ),
        child: Obx(
          () => Row(
            children: [
              _buildTabItem('Profile', 0, controller),
              _buildTabItem('Privacy', 1, controller),
              _buildTabItem('Insights', 2, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(String title, int index, SettingsController controller) {
    final bool isActive = controller.activeTabIndex.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.activeTabIndex.value = index,
        child: Container(
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF5D5FEF)
                : Colors.transparent, // Purple accent matching screenshot
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
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
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'This is how others will see you',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 25),

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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Privacy & Security',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 25),

          // Biometric Toggle Section
          Obx(
            () => _buildSettingsCard(
              title: '${controller.biometricType.value} Verification',
              subtitle: 'Secure your archive with ${controller.biometricType.value.toLowerCase()}',
              icon: controller.biometricType.value == 'Face ID' ? Icons.face : Icons.fingerprint,
              trailing: Obx(
                () => Switch(
                  value: controller.isBiometricEnabled.value,
                  onChanged: (val) => controller.toggleBiometrics(val),
                  activeColor: const Color(0xFF5D5FEF),
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),

          _buildSettingsCard(
            title: 'Encryption',
            subtitle: 'End-to-end encryption for all recordings',
            icon: Icons.lock_outline,
            trailing: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(height: 40),

          // Logout Button
          Text(
            'Account Actions',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 15),
          ListTile(
            onTap: () => _showLogoutDialog(authController),
            leading: const Icon(Icons.logout, color: AppTheme.error),
            title: Text(
              'Log Out',
              style: GoogleFonts.outfit(
                color: AppTheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
            tileColor: AppTheme.error.withOpacity(0.05),
            hoverColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.insights_outlined,
            size: 80,
            color: Color(0xFF5D5FEF),
          ),
          const SizedBox(height: 20),
          Text(
            'Insights coming soon!',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Track your preservation progress and voice trends here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EFE9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF5D5FEF)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
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

  TextStyle _labelStyle() => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppTheme.textPrimary,
  );
}
