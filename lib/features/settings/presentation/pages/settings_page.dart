import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedTabIndex = 1; // 0: Profile, 1: Privacy, 2: Insights

  String _defaultEntryPrivacy = 'Private - Only by you';
  String _profileVisibility = 'Follower only';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F6), // Soft pinkish background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Settings',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF3B2A2A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your profile and see Insights',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              
              // Custom Segmented Control
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Row(
                  children: [
                    _buildTab(0, 'Profile'),
                    _buildTab(1, 'Privacy'),
                    _buildTab(2, 'Insights'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Content based on selected tab
              if (_selectedTabIndex == 1) _buildPrivacyTab(),
              if (_selectedTabIndex == 0) _buildPlaceholder('Profile Settings coming soon.'),
              if (_selectedTabIndex == 2) _buildPlaceholder('Insights coming soon.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Text(
          text,
          style: GoogleFonts.outfit(color: Colors.grey.shade500),
        ),
      ),
    );
  }

  Widget _buildTab(int index, String title) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy Settings',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3B2A2A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Control who can see your content',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 24),

        // Dropdown 1
        _buildDropdownSetting(
          title: 'Default Entry Privacy',
          description: 'New memories will use this privacy setting by default',
          value: _defaultEntryPrivacy,
          items: const ['Private - Only by you', 'Follower only', 'Public'],
          onChanged: (val) {
            if (val != null) setState(() => _defaultEntryPrivacy = val);
          },
        ),
        const SizedBox(height: 24),

        // Dropdown 2
        _buildDropdownSetting(
          title: 'Profile Visibility',
          description: 'Who can view your profile and public stories',
          value: _profileVisibility,
          items: const ['Follower only', 'Public', 'Private'],
          onChanged: (val) {
            if (val != null) setState(() => _profileVisibility = val);
          },
        ),
        
        const SizedBox(height: 32),
        const Divider(color: Colors.purple, thickness: 0.5),
        const SizedBox(height: 24),

        // Danger Zone
        Text(
          'Danger Zone',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3B2A2A),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () {
              context.read<AuthCubit>().signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false);
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            label: Text(
              'Log Out',
              style: GoogleFonts.outfit(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.05),
              side: const BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
            color: const Color(0xFF3B2A2A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.purple.shade50.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
              style: GoogleFonts.outfit(color: const Color(0xFF3B2A2A), fontSize: 14),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
