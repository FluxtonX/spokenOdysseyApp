import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/theme.dart';

class MemoryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> memory;
  const MemoryDetailScreen({super.key, required this.memory});

  @override
  State<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends State<MemoryDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100), // Space for bottom input
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildDescription(),
                const SizedBox(height: 24),
                _buildEngagementStats(),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                _buildSocialContext(),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                _buildCommentsList(),
              ],
            ),
          ),
          _buildBottomInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
        onPressed: () => Get.back(),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Center(
            child: Material(
              color: const Color(0xFF5D5FEF),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () => _showShareBottomSheet(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.share_outlined, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Share',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVisibilityBadge(),
          const SizedBox(height: 16),
          Text(
            widget.memory['title'] ?? 'Memory Title',
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.memory['date'] ?? 'July 22, 2023',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMoodChip('loving', const Color(0xFF5D5FEF).withOpacity(0.12), const Color(0xFF5D5FEF)),
              _buildMoodChip('grateful', const Color(0xFF5D5FEF).withOpacity(0.12), const Color(0xFF5D5FEF)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.public, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            'Public',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 14, color: AppTheme.textSecondary),
        ],
      ),
    );
  }

  Widget _buildMoodChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.memory['description'] ?? 'After years of working for others, I finally took the leap. The fear was real, but so was the excitement. I remember sitting in my small apartment, laptop open, filing the paperwork that would change my life forever.',
            style: GoogleFonts.outfit(
              fontSize: 16,
              height: 1.7,
              color: AppTheme.textPrimary.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              Text('#family', style: GoogleFonts.outfit(color: const Color(0xFF5D5FEF), fontWeight: FontWeight.w600)),
              Text('#moments', style: GoogleFonts.outfit(color: const Color(0xFF5D5FEF), fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          const Icon(Icons.favorite, size: 20, color: Color(0xFFF35C5C)),
          const SizedBox(width: 8),
          Text(
            '142',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 24),
          const Icon(Icons.chat_bubble_outline, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text(
            '23',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialContext() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildAvatarStack(),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Liked by ',
                style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textSecondary),
                children: [
                  TextSpan(
                    text: 'Emma Roberts',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: '48 others',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStack() {
    return SizedBox(
      width: 44,
      height: 24,
      child: Stack(
        children: [
          _buildCircleAvatar('https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100', 0),
          Positioned(left: 14, child: _buildCircleAvatar('https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100', 1)),
          Positioned(left: 28, child: _buildCircleAvatar('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100', 2)),
        ],
      ),
    );
  }

  Widget _buildCircleAvatar(String url, int index) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: CircleAvatar(
        radius: 10,
        backgroundColor: Colors.grey[200],
        backgroundImage: NetworkImage(url),
      ),
    );
  }

  Widget _buildCommentsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 72),
      itemBuilder: (context, index) {
        return _buildCommentItem();
      },
    );
  }

  Widget _buildCommentItem() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'James Wilson',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '3 days ago',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'This is so beautifully written. The way you describe those early days... it took me back to my own beginnings.',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    height: 1.5,
                    color: AppTheme.textPrimary.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.favorite_border, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text('7', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(width: 20),
                    Text('Reply', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInput() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Add a thoughtful comment',
                          hintStyle: GoogleFonts.outfit(
                            fontSize: 14,
                            color: AppTheme.textHint,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const Icon(Icons.send_rounded, color: Color(0xFF5D5FEF), size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Share this Memory',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Share "The Day I Started My Own Business" with the world or someone special.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildShareOption(Icons.flutter_dash, 'Twitter / X', const Color(0xFF1DA1F2))),
                const SizedBox(width: 12),
                Expanded(child: _buildShareOption(Icons.facebook, 'Facebook', const Color(0xFF1877F2))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildShareOption(Icons.email, 'Email', const Color(0xFFEA4335))),
                const SizedBox(width: 12),
                Expanded(child: _buildShareOption(Icons.link, 'Copy Link', const Color(0xFF5D5FEF))),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, size: 18, color: AppTheme.textSecondary),
                  const SizedBox(width: 12),
                  const Text('spokenodyssey.com/m...', style: TextStyle(color: AppTheme.textSecondary)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D5FEF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Copy',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
