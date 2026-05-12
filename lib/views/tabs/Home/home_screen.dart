import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/navigation_controller.dart';
import '../../../services/memory_service.dart';
import '../../../theme/theme.dart';
import '../../albums/album_detail_screen.dart';
import '../../memories/record_story_screen.dart';
import '../../notifications/notification_screen.dart';
import '../../search/search_results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final MemoryService _memoryService = MemoryService();
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoadingMemories = true;
  List<Map<String, dynamic>> _recentMemories = [];
  Map<String, dynamic>? _userProfile;
  late final AnimationController _profileBorderAnimController;
  int _currentMemoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _profileBorderAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHomeData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _profileBorderAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadHomeData({bool forceRefresh = false}) async {
    await Future.wait([
      _loadMemories(forceRefresh: forceRefresh),
      _loadProfile(forceRefresh: forceRefresh),
    ]);
  }

  Future<void> _loadProfile({bool forceRefresh = false}) async {
    try {
      final profile = await _authController.fetchBackendProfile();
      if (!mounted) return;
      setState(() {
        _userProfile = profile;
      });
    } catch (e) {
      debugPrint('Error loading home profile: $e');
    }
  }

  String _displayName() {
    // Priority: Backend Profile > Firebase User > Fallback
    final profileName = _userProfile?['displayName']?.toString().trim();
    if (profileName != null && profileName.isNotEmpty) return profileName;

    final firebaseUser = _authController.firebaseUser.value;
    final name = firebaseUser?.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;

    final email = firebaseUser?.email;
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'Archivist';
  }

  Future<void> _loadMemories({bool forceRefresh = false}) async {
    setState(() {
      _isLoadingMemories = true;
    });

    try {
      final memories = await _memoryService.fetchMemories(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;

      final published = memories.where(
        (memory) => memory['status'] == 'published',
      );

      setState(() {
        _recentMemories = published.take(6).toList();
        _isLoadingMemories = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _recentMemories = const [];
        _isLoadingMemories = false;
      });
    }
  }

  Future<void> _startRecordStoryFlow({
    RecordStoryFormat? initialFormat,
    Map<String, dynamic>? initialDraft,
  }) async {
    final result = await Get.to<Map<String, dynamic>>(
      () => RecordStoryScreen(
        initialFormat: initialFormat,
        initialDraft: initialDraft,
      ),
    );

    if (!mounted || result == null) return;

    final memory = result['memory'];
    if (memory is! Map<String, dynamic>) return;

    await _loadHomeData();

    Get.snackbar(
      'Memory updated',
      result['status'] == 'published'
          ? 'Your memory is now part of the archive.'
          : 'Draft saved. You can continue it anytime.',
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      backgroundColor: AppTheme.adaptiveCardBg,
      colorText: AppTheme.adaptiveTextPrimary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.adaptiveScaffoldBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadHomeData(forceRefresh: true),
          color: const Color(0xFF8B7BFF),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
            children: [
              _buildTopBar(),
              const SizedBox(height: 32),
              _buildGreetingSection(),
              const SizedBox(height: 32),
              _buildRecordToday(),
              const SizedBox(height: 24),
              _buildRecentMemories(),
              const SizedBox(height: 24),
              _buildPendingInvites(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.adaptiveTextPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.adaptiveTextPrimary.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: AppTheme.adaptiveTextSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search memories...',
                      hintStyle: GoogleFonts.outfit(
                        color: AppTheme.adaptiveTextSecondary,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: GoogleFonts.outfit(
                      color: AppTheme.adaptiveTextPrimary,
                      fontSize: 14,
                    ),
                    onSubmitted: (query) {
                      if (query.trim().isNotEmpty) {
                        final q = query.trim();
                        _searchController.clear();
                        Get.to(() => SearchResultsScreen(initialQuery: q));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () => Get.to(() => const NotificationScreen()),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.adaptiveTextPrimary.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 26,
                  color: AppTheme.adaptiveTextPrimary,
                ),
              ),
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF08855),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.adaptiveScaffoldBg,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGreetingSection() {
    final now = DateTime.now();
    final month = _getMonthName(now.month);
    final weekday = _getWeekdayName(now.weekday);
    final day = now.day;
    final year = now.year;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${_displayName().split(' ').first} 👋',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.adaptiveTextPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Record your life. Treasure every moment.',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: AppTheme.adaptiveTextSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.adaptiveCardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: Color(0xFF8B7BFF),
                size: 24,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$month $day, $year',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppTheme.adaptiveTextPrimary,
                    ),
                  ),
                  Text(
                    weekday,
                    style: GoogleFonts.outfit(
                      color: AppTheme.adaptiveTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String _getWeekdayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  Widget _buildRecordToday() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.adaptiveCardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What would you like to record today?',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.adaptiveTextPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildRecordActionCard(
                  title: 'Text',
                  subtitle: 'Write your thoughts',
                  icon: Icons.notes_rounded,
                  color: const Color(0xFF907CFF),
                  onTap: () => _startRecordStoryFlow(
                    initialFormat: RecordStoryFormat.text,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildRecordActionCard(
                  title: 'Photo',
                  subtitle: 'Capture a moment',
                  icon: Icons.image_outlined,
                  color: const Color(0xFF4CB88C),
                  onTap: () => _startRecordStoryFlow(
                    initialFormat: RecordStoryFormat.photoText,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildRecordActionCard(
                  title: 'Video',
                  subtitle: 'Record a memory',
                  icon: Icons.videocam_outlined,
                  color: const Color(0xFFF08855),
                  onTap: () => _startRecordStoryFlow(
                    initialFormat: RecordStoryFormat.video,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildRecordActionCard(
                  title: 'Voice',
                  subtitle: 'Speak your mind',
                  icon: Icons.mic_none_rounded,
                  color: const Color(0xFF5B8DF2),
                  onTap: () => _startRecordStoryFlow(
                    initialFormat: RecordStoryFormat.voice,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.adaptiveTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: AppTheme.adaptiveTextSecondary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentMemories() {
    if (_isLoadingMemories) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recentMemories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: AppTheme.adaptiveCardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Memories',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.adaptiveTextPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => NavigationController.to.setTabIndex(2),
                  child: Row(
                    children: [
                      Text(
                        'View All',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF8B7BFF),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF8B7BFF),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          CarouselSlider.builder(
            itemCount: _recentMemories.length,
            itemBuilder: (context, index, realIndex) {
              return _buildMemoryCard(_recentMemories[index]);
            },
            options: CarouselOptions(
              height: 220,
              viewportFraction: 1.0,
              enlargeCenterPage: false,
              autoPlay: true,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentMemoryIndex = index;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_recentMemories.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _currentMemoryIndex == index ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: _currentMemoryIndex == index
                      ? const Color(0xFF8B7BFF)
                      : Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryCard(Map<String, dynamic> memory) {
    final title = memory['title']?.toString() ?? 'A Beautiful Evening';
    final date = memory['createdAt'] != null
        ? _formatDate(memory['createdAt'])
        : 'May 23, 2025 • 7:45 PM';
    final content =
        memory['description']?.toString() ??
        memory['textContent']?.toString() ??
        'No description added';
    final type = (memory['type']?.toString() ?? 'Text').capitalizeFirst!;
    final isText = type.toLowerCase() == 'text';
    final isVoice = type.toLowerCase().contains('voice') || type.toLowerCase().contains('audio');
    final isVideo = type.toLowerCase().contains('video');

    String imageUrl = '';
    if (!isVoice && !isText) {
      // For videos, prioritize thumbnails. If no thumbnail and it's a video, don't show the video file as an image.
      imageUrl = memory['thumbnailUrl']?.toString() ?? 
                (isVideo ? '' : (memory['mediaUrl']?.toString() ?? ''));
    }
    
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = '';
    }

    final albumName = memory['albumTitle'] ?? memory['albumName'] ?? 'General';

    return GestureDetector(
      onTap: () {
        final albumId = memory['albumId'];
        if (albumId != null) {
          Get.to(
            () => AlbumDetailScreen(
              albumId: albumId.toString(),
              initialMemoryId: memory['id']?.toString(),
              initialAlbumTitle: albumName,
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: type.toLowerCase() == 'text'
                    ? _parseColor(memory['color']?.toString())
                    : AppTheme.adaptiveTextPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                image: (type.toLowerCase() != 'text' && imageUrl.isNotEmpty && imageUrl.startsWith('http'))
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: type.toLowerCase() == 'text'
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          content,
                          textAlign: TextAlign.center,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    )
                  : (imageUrl.isEmpty || !imageUrl.startsWith('http'))
                      ? Center(
                          child: Icon(
                            _getMemoryIcon(memory['type']),
                            color: AppTheme.adaptiveTextSecondary.withValues(alpha: 0.5),
                            size: 40,
                          ),
                        )
                      : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF8B7BFF,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.notes_rounded,
                          color: Color(0xFF8B7BFF),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.adaptiveTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    date,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.adaptiveTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    content,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppTheme.adaptiveTextPrimary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildMediaCount(
                        Icons.collections_bookmark_rounded,
                        albumName,
                        const Color(0xFF8B7BFF),
                      ),
                      _buildMediaCount(
                        _getMemoryIcon(memory['type']),
                        type,
                        const Color(0xFF4CB88C),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    try {
      DateTime dt;
      if (timestamp is String) {
        dt = DateTime.parse(timestamp).toLocal();
      } else {
        dt = (timestamp as dynamic).toDate().toLocal();
      }
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $hour:$minute $amPm';
    } catch (e) {
      return 'May 23, 2025 • 7:45 PM';
    }
  }

  Widget _buildMediaCount(IconData icon, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            count,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingInvites() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.adaptiveCardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Invites',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.adaptiveTextPrimary,
                ),
              ),
              Text(
                'View All',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF8B7BFF),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildInviteCard(
                  'Invite Family',
                  Icons.person_add_alt_1_rounded,
                  const Color(0xFF907CFF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInviteCard(
                  'Invite Friends',
                  Icons.group_add_rounded,
                  const Color(0xFF4CB88C),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInviteCard(
                  'Invite Public',
                  Icons.public,
                  const Color(0xFFF08855),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCard(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.adaptiveTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return const Color(0xFFEBF5FF);
    try {
      String cleanHex = hexColor.replaceAll('#', '');
      if (cleanHex.length == 6) cleanHex = 'FF$cleanHex';
      return Color(int.parse(cleanHex, radix: 16));
    } catch (e) {
      return const Color(0xFFEBF5FF);
    }
  }

  IconData _getMemoryIcon(dynamic type) {
    final t = (type?.toString() ?? '').toLowerCase();
    if (t.contains('voice') || t.contains('audio')) return Icons.mic_rounded;
    if (t.contains('video')) return Icons.videocam_rounded;
    if (t.contains('photo') || t.contains('image')) return Icons.image_rounded;
    return Icons.notes_rounded;
  }
}
