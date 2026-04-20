// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../theme/theme.dart';
import 'add_member_bottom_sheet.dart';

class FamilyTreeDetailScreen extends StatelessWidget {
  const FamilyTreeDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: const Icon(Icons.arrow_back, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Family Circles',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 44),
                    child: Text(
                      'Share your stories with those who matter most.\nCreate a legacy that spans generations.',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Main Tree Card
                  _buildMainTreeCard(),

                  const SizedBox(height: 100), // Spacing for FAB
                ],
              ),
            ),

            // FAB
            Positioned(
              right: 20,
              bottom: 100,
              child: GestureDetector(
                onTap: () {
                  Get.bottomSheet(
                    const AddMemberBottomSheet(),
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                  );
                },
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5544FF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5544FF).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 36),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTreeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildCardHeader(),
          const SizedBox(height: 40),
          _buildDetailedTree(),
          const SizedBox(height: 48),
          _buildAddMemberButton(),
        ],
      ),
    );
  }

  Widget _buildCardHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mitchell Family Tree',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '4 generations • 9 members',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Get.bottomSheet(
              const AddMemberBottomSheet(),
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEBEEFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.add, size: 16, color: Color(0xFF5544FF)),
                const SizedBox(width: 6),
                Text(
                  'Add',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5544FF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedTree() {
    return Column(
      children: [
        // Grandparents
        _buildGenerationHeader('GRANDPARENTS', '4'),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTreeNode(
              initials: 'HM',
              name: 'Harold',
              role: 'Paternal\nGrandfather',
              dates: '1925–2002',
              color: const Color(0xFF64748B),
              showInnerIcon: true,
            ),
            _buildTreeNode(
              initials: 'WH',
              name: 'Walter',
              role: 'Maternal\nGrandfather',
              dates: '1930–1998',
              color: const Color(0xFF1E293B),
              showInnerIcon: true,
            ),
          ],
        ),

        _buildVerticalConnector(),

        // Parents
        _buildGenerationHeader('PARENTS', '2'),
        const SizedBox(height: 32),
        _buildTreeNode(
          initials: 'RM',
          name: 'Robert',
          role: 'Father',
          dates: '1955',
          color: const Color(0xFF3B82F6),
        ),

        _buildVerticalConnector(),

        // Your Generation
        _buildGenerationHeader('YOUR GENERATION', '2'),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTreeNode(
              initials: 'SM',
              name: 'Sarah',
              role: 'You',
              dates: '1985',
              color: const Color(0xFF5544FF),
              showHeartBadge: true,
            ),
            _buildTreeNode(
              initials: 'AX',
              name: 'Alex',
              role: 'Sibling',
              dates: '1988',
              color: const Color(0xFFF97316),
            ),
          ],
        ),

        _buildVerticalConnector(),

        // Children
        _buildGenerationHeader('CHILDREN', '1'),
        const SizedBox(height: 32),
        _buildTreeNode(
          initials: 'SM',
          name: 'Sophie',
          role: 'Daughter',
          dates: '2018',
          color: const Color(0xFFA855F7),
        ),
      ],
    );
  }

  Widget _buildGenerationHeader(String label, String count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.textHint,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
          const SizedBox(width: 12),
          Text(
            count,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeNode({
    required String initials,
    required String name,
    required String role,
    required String dates,
    required Color color,
    bool showHeartBadge = false,
    bool showInnerIcon = false,
  }) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            if (showHeartBadge)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF5544FF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            if (showInnerIcon)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(Icons.add, size: 10, color: Colors.white),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          role,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 10,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          name,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          dates,
          style: GoogleFonts.outfit(
            fontSize: 10,
            color: AppTheme.textHint,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalConnector() {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(vertical: 0),
      color: const Color(0xFFE5E7EB),
    );
  }

  Widget _buildAddMemberButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Get.bottomSheet(
              const AddMemberBottomSheet(),
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, size: 20, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Add family member',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
