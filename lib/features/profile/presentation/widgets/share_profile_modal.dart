import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/domain/entities/user.dart';

class ShareProfileModal extends StatelessWidget {
  final User user;

  const ShareProfileModal({super.key, required this.user});

  static void show(BuildContext context, User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ShareProfileModal(user: user),
    );
  }

  void _copyToClipboard(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Link copied to clipboard!',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF5E4EE8),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = user.name?.isNotEmpty == true
        ? user.name!
        : 'Sarah Mitchell';
    final String profileUrl = 'https://spokenodyssey.com/profile/${user.id}';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header with Title & Close Icon
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 12, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Share Profile',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF4B5563),
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Top Divider
            const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),

            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subtitle
                  Text(
                    'Share "$displayName" with the world or someone special.',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF4B5563),
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Row 1: Twitter / X & Facebook
                  Row(
                    children: [
                      // Twitter / X
                      Expanded(
                        child: _buildSharePlatformButton(
                          iconWidget: const _TwitterXIcon(),
                          label: 'Twitter / X',
                          backgroundColor: Colors.black,
                          textColor: Colors.white,
                          onTap: () {
                            _copyToClipboard(context, profileUrl);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Facebook
                      Expanded(
                        child: _buildSharePlatformButton(
                          iconWidget: const Icon(
                            Icons.facebook_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          label: 'Facebook',
                          backgroundColor: const Color(0xFF1877F2),
                          textColor: Colors.white,
                          onTap: () {
                            _copyToClipboard(context, profileUrl);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Row 2: Email & Copy Link
                  Row(
                    children: [
                      // Email
                      Expanded(
                        child: _buildSharePlatformButton(
                          iconWidget: const Icon(
                            Icons.email_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: 'Email',
                          backgroundColor: const Color(0xFFEF4444),
                          textColor: Colors.white,
                          onTap: () {
                            _copyToClipboard(context, profileUrl);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Copy Link
                      Expanded(
                        child: _buildSharePlatformButton(
                          iconWidget: const Icon(
                            Icons.link_rounded,
                            color: Color(0xFF5E4EE8),
                            size: 22,
                          ),
                          label: 'Copy Link',
                          backgroundColor: const Color(0xFFEDE9FE),
                          textColor: const Color(0xFF5E4EE8),
                          onTap: () {
                            _copyToClipboard(context, profileUrl);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Bottom Copyable Link Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F1FE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.link_rounded,
                          color: Color(0xFF6B7280),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'spokenodyssey.com/profile/${user.id}',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _copyToClipboard(context, profileUrl),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5E4EE8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.copy_rounded,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Copy',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharePlatformButton({
    required Widget iconWidget,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Twitter / X stylish icon
class _TwitterXIcon extends StatelessWidget {
  const _TwitterXIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.close_rounded, color: Colors.white, size: 20);
  }
}
