import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../theme/theme.dart';

class PersonDetailScreen extends StatefulWidget {
  final Map<String, dynamic> person;
  const PersonDetailScreen({super.key, required this.person});

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  int _selectedTabIndex = 0;
  bool _isFollowing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  _buildCustomTabSelector(),
                  const SizedBox(height: 24),
                  _buildTabContent(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedTabIndex != 1 
          ? FloatingActionButton(
              onPressed: () {},
              backgroundColor: const Color(0xFF5544FF),
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover Image
        SizedBox(
          height: 240,
          width: double.infinity,
          child: Image.network(
            widget.person['bgImage'],
            fit: BoxFit.cover,
          ),
        ),
        
        // Navigation Buttons
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 20,
          child: _buildCircleButton(Icons.arrow_back, () => Get.back()),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 20,
          child: _buildCircleButton(Icons.close, () => Get.back()),
        ),

        // Profile Body
        Container(
          margin: const EdgeInsets.only(top: 200),
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
          child: Column(
            children: [
              // Follow Button
              Align(
                alignment: Alignment.topRight,
                child: _buildFollowButton(),
              ),
              
              const SizedBox(height: 4),
              Text(
                widget.person['name'],
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.person['role'],
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.person['description'],
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  height: 1.5,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatItem(widget.person['followers'], 'followers'),
                  _buildStatDivider(),
                  _buildStatItem('2', 'stories'),
                  _buildStatDivider(),
                  _buildStatItem('2', 'milestones'),
                ],
              ),
            ],
          ),
        ),

        // Avatar Overlay
        Positioned(
          top: 150,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 46,
                backgroundImage: NetworkImage(widget.person['avatar']),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String val, String label) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$val ',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          TextSpan(
            text: label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 14,
      width: 1,
      color: const Color(0xFFE5E7EB),
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildFollowButton() {
    return Material(
      color: _isFollowing ? Colors.white : const Color(0xFF5544FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: _isFollowing 
            ? const BorderSide(color: Color(0xFFE5E7EB)) 
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => setState(() => _isFollowing = !_isFollowing),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isFollowing ? Icons.check : Icons.person_add_alt_1,
                size: 16,
                color: _isFollowing ? AppTheme.textPrimary : Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                _isFollowing ? 'Following' : 'Follow',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _isFollowing ? AppTheme.textPrimary : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppTheme.textPrimary),
      ),
    );
  }

  Widget _buildCustomTabSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTabItem(0, Icons.description_outlined, 'Stories'),
          _buildTabItem(1, Icons.emoji_events_outlined, 'Milestones'),
          _buildTabItem(2, Icons.collections_outlined, 'Albums'),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected 
                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] 
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? const Color(0xFF5544FF) : AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildStoriesView();
      case 1:
        return _buildMilestonesView();
      case 2:
        return _buildAlbumsView();
      default:
        return Container();
    }
  }

  Widget _buildStoriesView() {
    return Column(
      children: [
        _buildStoryCard(
          tag: 'career',
          tagName: 'Career',
          title: 'The Day I Wrote the First Compiler',
          body: 'Everyone said it couldn\'t be done — that computers could only understand numbers. I believed otherwise. It took three years...',
          date: 'September 9, 1952',
          likes: '3,820',
        ),
        const SizedBox(height: 16),
        _buildStoryCard(
          tag: 'milestone',
          tagName: 'Milestone',
          title: 'My First Day in the Navy',
          body: 'The uniform was stiff and unfamiliar, but I wore it like armor. I was determined to prove that brilliance has no gender...',
          date: 'December 7, 1943',
          likes: '2,140',
          comments: '118',
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildStoryCard({
    required String tag,
    required String tagName,
    required String title,
    required String body,
    required String date,
    required String likes,
    String? comments,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildTag(tagName, tag == 'career' ? const Color(0xFFEEF2FF) : const Color(0xFFFFF7ED), 
                                 tag == 'career' ? const Color(0xFF4F46E5) : const Color(0xFFC2410C)),
              const SizedBox(width: 8),
              _buildTag('Determined', const Color(0xFFF3F4F6), AppTheme.textSecondary),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.5,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                date,
                style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textHint),
              ),
              const Spacer(),
              const Icon(Icons.favorite_outline, size: 14, color: AppTheme.textHint),
              const SizedBox(width: 4),
              Text(likes, style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary)),
              if (comments != null) ...[
                const SizedBox(width: 12),
                const Icon(Icons.chat_bubble_outline, size: 14, color: AppTheme.textHint),
                const SizedBox(width: 4),
                Text(comments, style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        text,
        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: textCol),
      ),
    );
  }

  Widget _buildMilestonesView() {
    return Stack(
      children: [
        // Timeline line
        Positioned(
          left: 17,
          top: 0,
          bottom: 0,
          child: Container(width: 2, color: const Color(0xFFE5E7EB)),
        ),
        Column(
          children: [
            _buildMilestoneItem(
              icon: Icons.emoji_events_outlined,
              iconColor: const Color(0xFF5544FF),
              title: 'Received the Presidential Medal of Freedom',
              year: '2016',
              desc: 'Posthumously awarded by President Barack Obama for her contributions to computing and the Navy.',
              tag: 'Honor',
            ),
            const SizedBox(height: 32),
             _buildMilestoneItem(
              icon: Icons.star_outline,
              iconColor: const Color(0xFF5544FF),
              title: 'The Moment to Promoted to Rear Admiral',
              year: '1985',
              desc: 'Became one of the first female Rear Admirals in the United States Navy. In this is.',
              tag: 'Career',
            ),
            const SizedBox(height: 48),
          ],
        ),
      ],
    );
  }

  Widget _buildMilestoneItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String year,
    required String desc,
    required String tag,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: iconColor, width: 2),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      year,
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textHint),
                    ),
                    _buildTag(tag, const Color(0xFFEEF2FF), const Color(0xFF4F46E5)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  style: GoogleFonts.outfit(fontSize: 13, height: 1.5, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumsView() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 1, // To match the vertical card layout in bottom mockup parts
      childAspectRatio: 1.5, // Reduced from 1.0 to fit images better
      mainAxisSpacing: 16,
      children: [
        _buildAlbumCard('Navy Years', '14 entries', 'assets/icons/album_icon.png'), // Using placeholder logic
        _buildAlbumCard('Computing Breakthroughs', '12 entries', 'assets/icons/album_icon.png'),
        _buildAlbumCard('Computing Breakthroughs', '24 entries', 'assets/icons/album_icon.png'),
      ],
    );
  }

  Widget _buildAlbumCard(String title, String count, String imagePath) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Container(
                color: const Color(0xFFF3F4F6),
                child: Stack(
                  children: [
                    Center(child: Icon(Icons.folder_open, size: 48, color: AppTheme.textHint.withOpacity(0.5))),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(count, style: GoogleFonts.outfit(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Icon(Icons.folder_open, color: Colors.white.withOpacity(0.8), size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Service, sacrifice, and the pursuit of excelle...',
                  style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
