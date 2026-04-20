import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../theme/theme.dart';

class AddMemberBottomSheet extends StatefulWidget {
  const AddMemberBottomSheet({super.key});

  @override
  State<AddMemberBottomSheet> createState() => _AddMemberBottomSheetState();
}

class _AddMemberBottomSheetState extends State<AddMemberBottomSheet> {
  String selectedRelationship = 'Select Relationship...';
  String selectedAccess = 'Family Memories Only';
  bool isRelationshipExpanded = false;

  final List<String> relationships = [
    'Parents',
    'Child',
    'Sibling',
    'Grandparent',
    'Grandchild',
    'Cousin',
    'Close friends',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Family Member',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Scrollable Form
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Full Name'),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'e.g., Emma Mitchell',
                      hintStyle: GoogleFonts.outfit(
                        color: AppTheme.textHint,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Email Address'),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'their@email.com',
                      hintStyle: GoogleFonts.outfit(
                        color: AppTheme.textHint,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Relationship'),
                  const SizedBox(height: 8),
                  _buildRelationshipSelector(),
                  const SizedBox(height: 24),

                  Text(
                    'Access Level',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildAccessLevelCard(
                    title: 'Full Legacy Access',
                    subtitle:
                        'Can view all memories including private ones after your passing',
                    icon: Icons.key_outlined,
                    iconColor: const Color(0xFF22C55E),
                    isSelected: selectedAccess == 'Full Legacy Access',
                    onTap: () =>
                        setState(() => selectedAccess = 'Full Legacy Access'),
                  ),
                  const SizedBox(height: 12),
                  _buildAccessLevelCard(
                    title: 'Family Memories Only',
                    subtitle:
                        'Can view family-tagged memories and public posts only',
                    icon: Icons.people_outline,
                    iconColor: const Color(0xFF5544FF),
                    isSelected: selectedAccess == 'Family Memories Only',
                    onTap: () =>
                        setState(() => selectedAccess = 'Family Memories Only'),
                  ),
                  const SizedBox(height: 12),
                  _buildAccessLevelCard(
                    title: 'Public Only',
                    subtitle:
                        'Can only view memories you\'ve made publicly visible',
                    icon: Icons.public_outlined,
                    iconColor: const Color(0xFFF59E0B),
                    isSelected: selectedAccess == 'Public Only',
                    onTap: () => setState(() => selectedAccess = 'Public Only'),
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Get.back(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEFEBE7),
                            foregroundColor: AppTheme.textSecondary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Send Invitation',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          TextSpan(
            text: ' *',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipSelector() {
    return Column(
      children: [
        GestureDetector(
          onTap: () =>
              setState(() => isRelationshipExpanded = !isRelationshipExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedRelationship,
                  style: GoogleFonts.outfit(
                    color: selectedRelationship == 'Select Relationship...'
                        ? AppTheme.textHint
                        : AppTheme.textPrimary,
                    fontSize: 15,
                  ),
                ),
                Icon(
                  isRelationshipExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppTheme.textPrimary,
                ),
              ],
            ),
          ),
        ),
        if (isRelationshipExpanded)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: relationships
                  .map(
                    (rel) => InkWell(
                      onTap: () {
                        setState(() {
                          selectedRelationship = rel;
                          isRelationshipExpanded = false;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: selectedRelationship == rel
                              ? const Color(0xFFEBEEFF)
                              : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          rel,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: selectedRelationship == rel
                                ? const Color(0xFF5544FF)
                                : AppTheme.textPrimary,
                            fontWeight: selectedRelationship == rel
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildAccessLevelCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF5544FF)
                : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF5544FF).withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF5544FF),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
