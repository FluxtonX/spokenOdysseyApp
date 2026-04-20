import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';

class PersonCard extends StatelessWidget {
  final String bgImageUrl; // Cover image
  final String avatarUrl; // Profile pic
  final String name;
  final String role;
  final String description;
  final String followersCount;
  final VoidCallback onFollowTrigger;
  final VoidCallback? onTap;

  const PersonCard({
    super.key,
    required this.bgImageUrl,
    required this.avatarUrl,
    required this.name,
    required this.role,
    required this.description,
    required this.followersCount,
    required this.onFollowTrigger,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: SizedBox(
                height: 120,
                child: Image.network(
                  bgImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppTheme.border,
                    child: const Center(
                      child: Icon(Icons.broken_image, color: AppTheme.textHint),
                    ),
                  ),
                ),
              ),
            ),

            // Body Section overlapping avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        role,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        description,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          height: 1.4,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: followersCount,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                TextSpan(
                                  text: ' followers',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Material(
                            color: const Color(0xFF5544FF), // Vivid pure blurple
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              onTap: onFollowTrigger,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                height: 38,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.person_add_alt_1,
                                      size: 16,
                                      color: AppTheme.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Follow',
                                      style: GoogleFonts.outfit(
                                        color: AppTheme.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Floating Avatar
                Positioned(
                  top: -36,
                  left: 20,
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.white,
                          shape: BoxShape.circle,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: AppTheme.border,
                                    child: const Icon(
                                      Icons.person,
                                      color: AppTheme.textHint,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
                      // Small floating badge pencil
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.border, width: 1),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 10,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
