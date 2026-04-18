import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/theme.dart';

class AlbumDetailScreen extends StatelessWidget {
  final Map<String, dynamic> album;
  const AlbumDetailScreen({super.key, required this.album});

  // Tag color mapping for variety
  static const Map<String, Color> _tagColors = {
    'Awestruck': Color(0xFF5ABA82),
    'Proud': Color(0xFFE2923A),
    'Grateful': Color(0xFF5D5FEF),
    'Heartfelt': Color(0xFFE85D75),
    'Adventurous': Color(0xFF3B82F6),
    'Resilient': Color(0xFF916CD3),
    'Bittersweet': Color(0xFFE2923A),
    'Joyful': Color(0xFF5ABA82),
    'Cherished': Color(0xFFE85D75),
    'Reflective': Color(0xFF6366F1),
    'Family': Color(0xFF5D5FEF),
    'Public': Color(0xFF5D5FEF),
    'Dramatic': Color(0xFF916CD3),
  };

  Color _getTagColor(String tag) {
    return _tagColors[tag] ?? const Color(0xFF5D5FEF);
  }

  @override
  Widget build(BuildContext context) {
    final memories =
        (album['memories'] as List<Map<String, dynamic>>?) ?? [];

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          // Collapsing App Bar with album cover
          SliverAppBar(
            backgroundColor: Colors.white,
            expandedHeight: 260,
            pinned: true,
            leading: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppTheme.textPrimary,
                  size: 22,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    album['image'],
                    fit: BoxFit.cover,
                  ),
                  // Bottom gradient for text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                  // Album info overlay
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User avatar row
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const CircleAvatar(
                                radius: 18,
                                backgroundImage: NetworkImage(
                                  'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=200&auto=format&fit=crop',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sarah Mitchell',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '${memories.length} memories',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.8),
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
                ],
              ),
            ),
          ),

          // Album Title Section
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album['title'],
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    album['subtitle'],
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Memory Cards
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildMemoryCard(memories[index]);
                },
                childCount: memories.length,
              ),
            ),
          ),

          // Bottom spacer for FAB
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        heroTag: 'album_detail_fab',
        backgroundColor: const Color(0xFF5ABA82),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildMemoryCard(Map<String, dynamic> memory) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tags row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Category badge (if exists)
              if (memory['category'] != null)
                _buildTagChip(
                  memory['category'],
                  _getTagColor(memory['category']),
                  filled: true,
                ),
              // Mood tags
              ...(memory['tags'] as List<String>).map(
                (tag) => _buildTagChip(
                  tag,
                  _getTagColor(tag),
                  filled: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            memory['title'],
            style: GoogleFonts.playfairDisplay(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),

          // Description
          Text(
            memory['description'],
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.6,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Bottom Row - Date & Engagement
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFF3F4F6)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: AppTheme.textSecondary.withOpacity(0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  memory['date'],
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                // Likes
                Icon(
                  Icons.favorite_border,
                  size: 15,
                  color: AppTheme.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  '${memory['likes']}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 14),
                // Comments
                Icon(
                  Icons.chat_bubble_outline,
                  size: 14,
                  color: AppTheme.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  '${memory['comments']}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String label, Color color, {bool filled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: filled ? Colors.white : color,
        ),
      ),
    );
  }
}
