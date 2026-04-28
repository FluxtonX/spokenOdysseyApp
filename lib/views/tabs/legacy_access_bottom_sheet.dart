import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../theme/theme.dart';

class LegacyAccessBottomSheet extends StatefulWidget {
  const LegacyAccessBottomSheet({super.key});

  @override
  State<LegacyAccessBottomSheet> createState() =>
      _LegacyAccessBottomSheetState();
}

class _LegacyAccessBottomSheetState extends State<LegacyAccessBottomSheet> {
  String selectedTrustee = 'Robert Mitchell';
  String selectedCondition = 'After Death Verified';
  bool notificationsEnabled = true;
  bool isTrusteeExpanded = false;

  final List<String> familyMembers = [
    'Robert Mitchell',
    'Emily Mitchell',
    'Alex Mitchell',
    'Sophie Mitchell',
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
                'Legacy Access Settings',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.adaptiveTextPrimary,
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
                  child: Icon(
                    Icons.close,
                    size: 20,
                    color: AppTheme.adaptiveTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Scrollable Content
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warning Info Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFEF3C7)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFD97706),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'These settings determine who can access your memories after your passing. Review carefully and update regularly.',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF92400E),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildLabel('Relationship'),
                  const SizedBox(height: 8),
                  _buildTrusteeSelector(),
                  const SizedBox(height: 8),
                  Text(
                    'This person will manage access requests and your archive.',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.adaptiveTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Activation Condition',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.adaptiveTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildConditionCard(
                    title: 'After Death Verified',
                    subtitle:
                        'Access unlocked after official verification of passing',
                    isSelected: selectedCondition == 'After Death Verified',
                    onTap: () => setState(
                      () => selectedCondition = 'After Death Verified',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildConditionCard(
                    title: 'Extended Inactivity',
                    subtitle: 'After 365 days of inactivity on the platform',
                    isSelected: selectedCondition == 'Extended Inactivity',
                    onTap: () => setState(
                      () => selectedCondition = 'Extended Inactivity',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildConditionCard(
                    title: 'Manual Unlock by Trustee',
                    subtitle: 'The trustee can unlock access at any time',
                    isSelected: selectedCondition == 'Manual Unlock by Trustee',
                    onTap: () => setState(
                      () => selectedCondition = 'Manual Unlock by Trustee',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Toggle Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Inactivity Notifications',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.adaptiveTextPrimary,
                                ),
                              ),
                              Text(
                                'Notify me if I haven\'t logged in for 30 days',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: AppTheme.adaptiveTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: notificationsEnabled,
                          onChanged: (val) =>
                              setState(() => notificationsEnabled = val),
                          activeThumbColor: const Color(0xFF5544FF),
                        ),
                      ],
                    ),
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
                              color: AppTheme.adaptiveTextPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Get.back(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5544FF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Save Settings',
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
              color: AppTheme.adaptiveTextPrimary,
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

  Widget _buildTrusteeSelector() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => isTrusteeExpanded = !isTrusteeExpanded),
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
                  selectedTrustee,
                  style: GoogleFonts.outfit(
                    color: AppTheme.adaptiveTextPrimary,
                    fontSize: 15,
                  ),
                ),
                Icon(
                  isTrusteeExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppTheme.adaptiveTextPrimary,
                ),
              ],
            ),
          ),
        ),
        if (isTrusteeExpanded)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: familyMembers
                  .map(
                    (member) => InkWell(
                      onTap: () {
                        setState(() {
                          selectedTrustee = member;
                          isTrusteeExpanded = false;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: selectedTrustee == member
                              ? const Color(0xFFEBEEFF)
                              : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          member,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: selectedTrustee == member
                                ? const Color(0xFF5544FF)
                                : AppTheme.adaptiveTextPrimary,
                            fontWeight: selectedTrustee == member
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

  Widget _buildConditionCard({
    required String title,
    required String subtitle,
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
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.adaptiveTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.adaptiveTextSecondary,
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
