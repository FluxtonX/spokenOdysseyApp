import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/theme.dart';

class PersonDetailScreen extends StatefulWidget {
  final Map<String, dynamic> person;
  final bool initialIsFollowing;
  final ValueChanged<bool>? onFollowChanged;

  const PersonDetailScreen({
    super.key,
    required this.person,
    this.initialIsFollowing = false,
    this.onFollowChanged,
  });

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  int _selectedTabIndex = 0;
  late bool _isFollowing;

  List<Map<String, dynamic>> get _stories =>
      ((widget.person['stories'] as List<dynamic>?) ?? <dynamic>[])
          .cast<Map<String, dynamic>>();

  List<Map<String, dynamic>> get _milestones =>
      ((widget.person['milestones'] as List<dynamic>?) ?? <dynamic>[])
          .cast<Map<String, dynamic>>();

  List<Map<String, dynamic>> get _albums =>
      ((widget.person['albums'] as List<dynamic>?) ?? <dynamic>[])
          .cast<Map<String, dynamic>>();

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.initialIsFollowing;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.adaptiveScaffoldBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildProfileHeader(context)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 120),
              child: Column(
                children: [
                  _buildCustomTabSelector(),
                  const SizedBox(height: 24),
                  _buildTabContent(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: '${widget.person['name']}_detail_fab',
        onPressed: () {},
        backgroundColor: const Color(0xFF5544FF),
        shape: const CircleBorder(),
        child: Icon(
          _selectedTabIndex == 2
              ? Icons.add_photo_alternate_outlined
              : Icons.add,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          height: 250,
          width: double.infinity,
          child: Image.network(
            widget.person['bgImage'] as String,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: AppTheme.adaptiveBorder),
          ),
        ),
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
        Container(
          margin: const EdgeInsets.only(top: 210),
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 68, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(alignment: Alignment.topRight, child: _buildFollowButton()),
              const SizedBox(height: 4),
              Text(
                widget.person['name'] as String,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.adaptiveTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.person['role']} • ${widget.person['country']}',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.adaptiveTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.person['description'] as String,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  height: 1.6,
                  color: AppTheme.adaptiveTextPrimary,
                ),
              ),
              if ((widget.person['quote'] as String?)?.isNotEmpty ?? false) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F4EE),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    '"${widget.person['quote']}"',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.adaptiveTextPrimary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _buildStatPill(
                    widget.person['followers'] as String? ?? '0',
                    'followers',
                  ),
                  _buildStatPill(
                    '${widget.person['storiesCount'] ?? _stories.length}',
                    'stories',
                  ),
                  _buildStatPill(
                    '${widget.person['milestonesCount'] ?? _milestones.length}',
                    'milestones',
                  ),
                  _buildStatPill('${_albums.length}', 'albums'),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: 160,
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
                radius: 48,
                backgroundColor: AppTheme.adaptiveBorder,
                backgroundImage: NetworkImage(
                  widget.person['avatar'] as String,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatPill(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F2EC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$value ',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.adaptiveTextPrimary,
              ),
            ),
            TextSpan(
              text: label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.adaptiveTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowButton() {
    return Material(
      color: _isFollowing ? Colors.white : const Color(0xFF5544FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: _isFollowing
            ? BorderSide(color: AppTheme.adaptiveBorder)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          setState(() => _isFollowing = !_isFollowing);
          widget.onFollowChanged?.call(_isFollowing);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isFollowing ? Icons.check : Icons.person_add_alt_1,
                size: 16,
                color: _isFollowing
                    ? AppTheme.adaptiveTextPrimary
                    : Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                _isFollowing ? 'Following' : 'Follow',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _isFollowing
                      ? AppTheme.adaptiveTextPrimary
                      : Colors.white,
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
        child: Icon(icon, size: 20, color: AppTheme.adaptiveTextPrimary),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? const Color(0xFF5544FF)
                    : AppTheme.adaptiveTextSecondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppTheme.adaptiveTextPrimary
                        : AppTheme.adaptiveTextSecondary,
                  ),
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
        return const SizedBox.shrink();
    }
  }

  Widget _buildStoriesView() {
    if (_stories.isEmpty) {
      return _buildEmptyContent(
        icon: Icons.auto_stories_outlined,
        title: 'No public stories yet',
        body:
            'This archive does not have published stories in the discover feed yet.',
      );
    }

    return Column(
      children: _stories.map((story) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildStoryCard(story),
        );
      }).toList(),
    );
  }

  Widget _buildStoryCard(Map<String, dynamic> story) {
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTag(
                story['tag'] as String? ?? 'Story',
                const Color(0xFFEEF2FF),
                const Color(0xFF4F46E5),
              ),
              _buildTag(
                story['theme'] as String? ?? 'Archive',
                const Color(0xFFF3F4F6),
                AppTheme.adaptiveTextSecondary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            story['title'] as String,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.adaptiveTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            story['excerpt'] as String,
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.6,
              color: AppTheme.adaptiveTextSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 14,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                story['publishedLabel'] as String? ?? '',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.adaptiveTextHint,
                ),
              ),
              _buildMetaItem(
                Icons.schedule_outlined,
                story['readTime'] as String? ?? '',
              ),
              _buildMetaItem(Icons.favorite_outline, '${story['likes']}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.adaptiveTextHint),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppTheme.adaptiveTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textCol,
        ),
      ),
    );
  }

  Widget _buildMilestonesView() {
    if (_milestones.isEmpty) {
      return _buildEmptyContent(
        icon: Icons.emoji_events_outlined,
        title: 'No milestones yet',
        body:
            'Milestones will appear here when this archive has major moments published.',
      );
    }

    return Stack(
      children: [
        Positioned(
          left: 17,
          top: 0,
          bottom: 0,
          child: Container(width: 2, color: const Color(0xFFE5E7EB)),
        ),
        Column(
          children: List.generate(_milestones.length, (index) {
            final milestone = _milestones[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == _milestones.length - 1 ? 0 : 28,
              ),
              child: _buildMilestoneItem(milestone),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMilestoneItem(Map<String, dynamic> milestone) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF5544FF), width: 2),
          ),
          child: Icon(
            milestone['icon'] as IconData? ?? Icons.star_outline,
            size: 18,
            color: const Color(0xFF5544FF),
          ),
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
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Text(
                      milestone['year'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.adaptiveTextHint,
                      ),
                    ),
                    _buildTag(
                      milestone['tag'] as String? ?? 'Milestone',
                      const Color(0xFFEEF2FF),
                      const Color(0xFF4F46E5),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  milestone['title'] as String,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.adaptiveTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  milestone['desc'] as String,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    height: 1.5,
                    color: AppTheme.adaptiveTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumsView() {
    if (_albums.isEmpty) {
      return _buildEmptyContent(
        icon: Icons.collections_outlined,
        title: 'No public albums yet',
        body:
            'Albums appear here when this archive has curated collections to explore.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 2 : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isWide ? 1.28 : 1.5,
          ),
          itemCount: _albums.length,
          itemBuilder: (context, index) => _buildAlbumCard(_albums[index]),
        );
      },
    );
  }

  Widget _buildAlbumCard(Map<String, dynamic> album) {
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    album['coverImage'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFF3F4F6),
                      child: Icon(
                        Icons.folder_open,
                        size: 40,
                        color: AppTheme.adaptiveTextHint.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.48),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${album['entryCount']} entries',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  album['title'] as String,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.adaptiveTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  album['subtitle'] as String,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    height: 1.45,
                    color: AppTheme.adaptiveTextSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContent({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF5544FF).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF5544FF)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.adaptiveTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.6,
              color: AppTheme.adaptiveTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
