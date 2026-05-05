import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../customWidgets/recent_memory_media_carousel.dart';
import '../../../controllers/auth_controller.dart';
import '../../../services/album_service.dart';
import '../../../services/memory_service.dart';
import '../../../theme/theme.dart';
import '../../albums/album_detail_screen.dart';
import '../../memories/record_story_screen.dart';
import '../albums_screen.dart';
import '../discover_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final AlbumService _albumService = AlbumService();
  final MemoryService _memoryService = MemoryService();
  final AuthController _authController = Get.find<AuthController>();
  final List<String> _heroBackgroundImages = const [
    'https://images.unsplash.com/photo-1517486808906-6ca8b3f04846?q=80&w=1600&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?q=80&w=1600&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1493246507139-91e8fad9978e?q=80&w=1600&auto=format&fit=crop',
  ];
  final List<String> _heroSupportPhrases = const [
    'Turn everyday memories into a private archive that still feels alive.',
    'Keep photos, voice notes, and family moments together without losing their emotion.',
    'Shape the memories your future family will want to revisit in your own voice.',
  ];

  bool _isLoadingAlbums = true;
  bool _isLoadingMemories = true;
  String? _albumError;
  String? _memoryError;
  List<Map<String, dynamic>> _recentAlbums = [];
  List<Map<String, dynamic>> _recentMemories = [];
  Map<String, dynamic>? _userProfile;
  Timer? _heroBackgroundTimer;
  Timer? _heroHeadlineTimer;
  Timer? _heroSupportTimer;
  late final AnimationController _profileBorderAnimController;
  int _heroImageIndex = 0;
  int _albumSpotlightIndex = 0;
  int _emptyAlbumBgIndex = 0;
  Timer? _emptyAlbumBgTimer;
  final List<String> _emptyAlbumBgImages = const [
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=1200&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?q=80&w=1200&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?q=80&w=1200&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1506744038136-46273834b3fb?q=80&w=1200&auto=format&fit=crop',
  ];
  int _heroSupportIndex = 0;
  bool _didPrecacheHeroImages = false;
  bool _showGreeting = false;
  bool _showHeroSupport = false;
  String _animatedHeroHeadline = '';

  final List<Map<String, dynamic>> _featuredVoices = const [
    {
      'title': 'Extraordinary Lives',
      'subtitle': 'Explore archives that inspire how we preserve memory.',
      'accent': Color(0xFF5544FF),
      'icon': Icons.auto_stories_outlined,
    },
    {
      'title': 'Family Legacy',
      'subtitle': 'See how shared memories can become a living archive.',
      'accent': Color(0xFFE2923A),
      'icon': Icons.family_restroom_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _profileBorderAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _startHeroBackgroundRotation();
    _startHeroCopyAnimation();
    _startEmptyAlbumBgRotation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHomeData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheHeroImages) {
      return;
    }

    for (final imageUrl in _heroBackgroundImages) {
      precacheImage(NetworkImage(imageUrl), context);
    }
    _didPrecacheHeroImages = true;
  }

  @override
  void dispose() {
    _heroBackgroundTimer?.cancel();
    _heroHeadlineTimer?.cancel();
    _heroSupportTimer?.cancel();
    _emptyAlbumBgTimer?.cancel();
    _profileBorderAnimController.dispose();
    super.dispose();
  }

  void _startEmptyAlbumBgRotation() {
    _emptyAlbumBgTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() {
        _emptyAlbumBgIndex =
            (_emptyAlbumBgIndex + 1) % _emptyAlbumBgImages.length;
      });
    });
  }

  Future<void> _loadAlbums({bool forceRefresh = false}) async {
    setState(() {
      _isLoadingAlbums = true;
      _albumError = null;
    });

    try {
      final albums = await _albumService.fetchAlbums(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;

      setState(() {
        _recentAlbums = albums.take(8).toList();
        if (_albumSpotlightIndex >= _recentAlbums.length &&
            _recentAlbums.isNotEmpty) {
          _albumSpotlightIndex = 0;
        }
        _isLoadingAlbums = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _albumError = error.toString().replaceFirst('Exception: ', '');
        _isLoadingAlbums = false;
      });
    }
  }

  Future<void> _loadMemories({bool forceRefresh = false}) async {
    setState(() {
      _isLoadingMemories = true;
      _memoryError = null;
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
        _memoryError = error.toString().replaceFirst('Exception: ', '');
        _recentMemories = const [];
        _isLoadingMemories = false;
      });
    }
  }

  Future<void> _loadHomeData({bool forceRefresh = false}) async {
    await Future.wait([
      _loadAlbums(forceRefresh: forceRefresh),
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
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

  void _startHeroBackgroundRotation() {
    _heroBackgroundTimer?.cancel();
    _heroBackgroundTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _heroImageIndex = (_heroImageIndex + 1) % _heroBackgroundImages.length;
      });
    });
  }

  void _startHeroCopyAnimation() {
    const headline = 'Keep what matters in your own voice.';

    _heroHeadlineTimer?.cancel();
    _heroSupportTimer?.cancel();
    _animatedHeroHeadline = '';
    _heroSupportIndex = 0;
    _showGreeting = false;
    _showHeroSupport = false;

    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;

      setState(() {
        _showGreeting = true;
      });

      var nextLength = 0;
      _heroHeadlineTimer = Timer.periodic(const Duration(milliseconds: 26), (
        timer,
      ) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        nextLength += 1;
        if (nextLength >= headline.length) {
          setState(() {
            _animatedHeroHeadline = headline;
            _showHeroSupport = true;
          });
          timer.cancel();
          _startHeroSupportRotation();
          return;
        }

        setState(() {
          _animatedHeroHeadline = headline.substring(0, nextLength);
        });
      });
    });
  }

  void _startHeroSupportRotation() {
    _heroSupportTimer?.cancel();
    _heroSupportTimer = Timer.periodic(const Duration(milliseconds: 2800), (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _heroSupportIndex =
            (_heroSupportIndex + 1) % _heroSupportPhrases.length;
      });
    });
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadHomeData(forceRefresh: true),
          color: AppTheme.primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
            children: [
              _buildHeroHeader(),
              const SizedBox(height: 22),
              _buildCloudAlbumsShowcaseCard(),
              const SizedBox(height: 24),
              _buildSectionHeader(
                title: 'Quick Actions',
                subtitle: 'Start in the format that fits the memory.',
              ),
              const SizedBox(height: 14),
              _buildQuickActions(),
              const SizedBox(height: 28),
              _buildSectionHeader(
                title: 'Recent Memories',
                subtitle: 'Return to moments you captured recently.',
                trailing: TextButton(
                  onPressed: () => _startRecordStoryFlow(),
                  child: const Text('New memory'),
                ),
              ),
              const SizedBox(height: 14),
              _buildRecentMemoriesSection(),
              const SizedBox(height: 28),
              _buildSectionHeader(
                title: 'Recent Albums',
                subtitle: 'Collections shaping your archive right now.',
                trailing: TextButton(
                  onPressed: () => Get.to(() => const AlbumsScreen()),
                  child: const Text('Open albums'),
                ),
              ),
              const SizedBox(height: 14),
              _buildRecentAlbumsSection(),
              const SizedBox(height: 28),
              _buildSectionHeader(
                title: 'Legacy & Activity',
                subtitle: 'A quick pulse on your preservation journey.',
              ),
              const SizedBox(height: 14),
              _buildInsightsGrid(),
              const SizedBox(height: 28),
              _buildSectionHeader(
                title: 'Discover',
                subtitle: 'Move beyond your archive when you want inspiration.',
                trailing: TextButton(
                  onPressed: () => Get.to(() => const DiscoverScreen()),
                  child: const Text('Explore'),
                ),
              ),
              const SizedBox(height: 14),
              _buildDiscoverSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      height: 320,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(30)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 1800),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInOutCubic,
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            transitionBuilder: (child, animation) {
              final fade = CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              );
              final slide = Tween<Offset>(
                begin: const Offset(0.03, 0),
                end: Offset.zero,
              ).animate(fade);

              return FadeTransition(
                opacity: fade,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: _buildHeroBackgroundImage(
              _heroBackgroundImages[_heroImageIndex],
              ValueKey(_heroBackgroundImages[_heroImageIndex]),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF141B27).withValues(alpha: 0.84),
                  const Color(0xFF253247).withValues(alpha: 0.68),
                  const Color(0xFF8A6A50).withValues(alpha: 0.46),
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.28),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _profileBorderAnimController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _GradientBorderPainter(
                            rotation: _profileBorderAnimController.value * 6.2832,
                            gradientColors: const [
                              Color(0xFF5544FF),
                              Color(0xFF8B7BFF),
                              Color(0xFFE2923A),
                              Color(0xFF5ABA82),
                              Color(0xFF5544FF),
                            ],
                            strokeWidth: 2.5,
                          ),
                          child: child,
                        );
                      },
                      child: Container(
                        width: 54,
                        height: 54,
                        padding: const EdgeInsets.all(3.0),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: (_userProfile?['photoURL'] ??
                                      _authController.firebaseUser.value?.photoURL) !=
                                  null
                              ? Image.network(
                                  (_userProfile?['photoURL'] ??
                                          _authController
                                              .firebaseUser.value!.photoURL!)
                                      .toString(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, _, __) => Container(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    child: const Icon(Icons.person_rounded,
                                        color: Colors.white70),
                                  ),
                                )
                              : Container(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  child: const Icon(Icons.person_rounded,
                                      color: Colors.white70),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayName(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            _userProfile?['email'] ?? _authController.firebaseUser.value?.email ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Moved greeting here as requested
                AnimatedSlide(
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  offset: _showGreeting ? Offset.zero : const Offset(0, 0.18),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOutCubic,
                    opacity: _showGreeting ? 1 : 0,
                    child: Text(
                      '${_greeting()},',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _animatedHeroHeadline.isEmpty ? ' ' : _animatedHeroHeadline,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 30,
                    height: 1.14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 450),
                  opacity: _showHeroSupport ? 1 : 0,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 650),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.22),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      _heroSupportPhrases[_heroSupportIndex],
                      key: ValueKey<String>(
                        _heroSupportPhrases[_heroSupportIndex],
                      ),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.white.withValues(alpha: 0.84),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBackgroundImage(String imageUrl, Key key) {
    return TweenAnimationBuilder<double>(
      key: key,
      tween: Tween<double>(begin: 1.04, end: 1),
      duration: const Duration(seconds: 5),
      curve: Curves.easeOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF202938),
                  Color(0xFF3A4457),
                  Color(0xFF7A6858),
                ],
              ),
            ),
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF202938),
                  Color(0xFF3A4457),
                  Color(0xFF7A6858),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCloudAlbumsShowcaseCard() {
    if (_isLoadingAlbums) {
      return Container(
        height: 236,
        decoration: BoxDecoration(
          color: AppTheme.adaptiveCardBg,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_recentAlbums.isEmpty) {
      return Container(
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Sliding background images ──
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 1200),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Image.network(
                _emptyAlbumBgImages[_emptyAlbumBgIndex],
                key: ValueKey<int>(_emptyAlbumBgIndex),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF202938),
                        Color(0xFF445065),
                        Color(0xFF8A755F),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // ── Gradient overlay ──
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF202938).withValues(alpha: 0.45),
                    const Color(0xFF202938).withValues(alpha: 0.55),
                    const Color(0xFF202938).withValues(alpha: 0.88),
                  ],
                ),
              ),
            ),
            // ── Content ──
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Album Spotlight',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'The next cloud album you create will begin rotating here.',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Create an album from the archive tab and keep every memory synced to the cloud.',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final visibleDotCount = _recentAlbums.length > 5 ? 5 : _recentAlbums.length;

    return GestureDetector(
      onTap: () => Get.to(
        () => AlbumDetailScreen(album: _recentAlbums[_albumSpotlightIndex]),
      ),
      child: Container(
        height: 236,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CarouselSlider.builder(
              itemCount: _recentAlbums.length,
              itemBuilder: (context, index, realIndex) {
                final album = _recentAlbums[index];
                return SizedBox.expand(child: _buildAlbumCover(album));
              },
              options: CarouselOptions(
                viewportFraction: 1,
                height: 236,
                autoPlay: true,
                autoPlayInterval: const Duration(milliseconds: 2200),
                autoPlayAnimationDuration: const Duration(milliseconds: 900),
                autoPlayCurve: Curves.easeInOutCubic,
                enlargeCenterPage: false,
                onPageChanged: (index, reason) {
                  if (!mounted) return;
                  setState(() {
                    _albumSpotlightIndex = index;
                  });
                },
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.06),
                    Colors.black.withValues(alpha: 0.16),
                    Colors.black.withValues(alpha: 0.64),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 18,
              left: 18,
              right: 18,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  child: Text(
                      'Album',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(visibleDotCount, (index) {
                      final active =
                          index == (_albumSpotlightIndex % visibleDotCount);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        margin: const EdgeInsets.only(left: 6),
                        width: active ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _recentAlbums[_albumSpotlightIndex]['title']?.toString() ??
                        'Cloud album',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _recentAlbums[_albumSpotlightIndex]['subtitle']
                            ?.toString() ??
                        'A synced collection ready to keep growing in your archive.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      height: 1.5,
                      color: Colors.white.withValues(alpha: 0.86),
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

  Widget _buildRecentMemoriesSection() {
    if (_isLoadingMemories) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_memoryError != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.adaptiveCardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.adaptiveBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We could not load your recent memories.',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.adaptiveTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _memoryError!,
              style: GoogleFonts.outfit(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.adaptiveTextSecondary,
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => _loadMemories(forceRefresh: true),
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (_recentMemories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.adaptiveCardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.adaptiveBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No published memories yet.',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.adaptiveTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The first memory you publish will appear here automatically after it is saved to your archive.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.adaptiveTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RecentMemoryMediaCarousel(memories: _recentMemories);
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.adaptiveTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  height: 1.45,
                  color: AppTheme.adaptiveTextSecondary,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildQuickActions() {
    final items = [
      _QuickActionData(
        title: 'Voice',
        subtitle: '',
        icon: Icons.mic_none_rounded,
        accent: const Color(0xFF5544FF),
        onTap: () =>
            _startRecordStoryFlow(initialFormat: RecordStoryFormat.voice),
      ),
      _QuickActionData(
        title: 'Write',
        subtitle: '',
        icon: Icons.edit_note_rounded,
        accent: const Color(0xFF5ABA82),
        onTap: () =>
            _startRecordStoryFlow(initialFormat: RecordStoryFormat.text),
      ),
      _QuickActionData(
        title: 'Photo',
        subtitle: '',
        icon: Icons.collections_outlined,
        accent: const Color(0xFFE2923A),
        onTap: () =>
            _startRecordStoryFlow(initialFormat: RecordStoryFormat.photoText),
      ),
      _QuickActionData(
        title: 'Video',
        subtitle: '',
        icon: Icons.videocam_outlined,
        accent: const Color(0xFFE85D75),
        onTap: () =>
            _startRecordStoryFlow(initialFormat: RecordStoryFormat.video),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items.map((item) {
          return _buildQuickActionIconItem(
            title: item.title,
            icon: item.icon,
            accent: item.accent,
            onTap: item.onTap,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickActionIconItem({
    required String title,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.18), width: 1.5),
            ),
            child: Icon(
              icon,
              color: accent,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.adaptiveTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAlbumsSection() {
    if (_isLoadingAlbums) {
      return SizedBox(
        height: 228,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (context, index) => Container(
            width: 250,
            decoration: BoxDecoration(
              color: AppTheme.adaptiveCardBg,
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }

    if (_albumError != null) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppTheme.adaptiveCardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.adaptiveBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Albums could not load',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.adaptiveTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _albumError!,
              style: GoogleFonts.outfit(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.adaptiveTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _loadAlbums(forceRefresh: true),
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (_recentAlbums.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppTheme.adaptiveCardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.adaptiveBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No albums yet',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.adaptiveTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first album to start organizing memories into meaningful chapters.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.adaptiveTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Get.to(() => const AlbumsScreen()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5544FF),
                minimumSize: const Size(0, 48),
              ),
              child: const Text('Create first album'),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 252,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _recentAlbums.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final album = _recentAlbums[index];
          return _buildRecentAlbumCard(album);
        },
      ),
    );
  }

  Widget _buildRecentAlbumCard(Map<String, dynamic> album) {
    return GestureDetector(
      onTap: () => Get.to(() => AlbumDetailScreen(album: album)),
      child: Container(
        height: 252,
        width: 254,
        decoration: BoxDecoration(
          color: AppTheme.adaptiveCardBg,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppTheme.adaptiveBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    height: 144,
                    width: double.infinity,
                    child: _buildAlbumCover(album),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${album['entries'] ?? 0} memories',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      album['title']?.toString() ?? 'Untitled Album',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.adaptiveTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        album['subtitle']?.toString().isNotEmpty == true
                            ? album['subtitle'].toString()
                            : 'A chapter in your archive waiting to grow.',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          height: 1.5,
                          color: AppTheme.adaptiveTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumCover(Map<String, dynamic> album) {
    final imageUrl = album['coverImageUrl']?.toString();
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildAlbumFallback(album),
      );
    }

    final assetPath = album['image']?.toString();
    if (assetPath != null && assetPath.isNotEmpty) {
      return Image.asset(assetPath, fit: BoxFit.cover);
    }

    return _buildAlbumFallback(album);
  }

  Widget _buildAlbumFallback(Map<String, dynamic> album) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E3748), Color(0xFF6E5A4F), Color(0xFFB79E87)],
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Text(
          album['title']?.toString() ?? 'Album',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildInsightsGrid() {
    final memoryCount = _recentMemories.length;
    final albumCount = _recentAlbums.length;
    final publicMemories = _recentMemories
        .where((memory) => memory['privacy'] == 'Public')
        .length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.adaptiveCardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.adaptiveBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF5ABA82).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Color(0xFF5ABA82),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Archive Overview',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.adaptiveTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildInsightStat(
                  title: 'Memories',
                  value: '$memoryCount',
                  subtitle: 'This week',
                ),
              ),
              Container(width: 1, height: 40, color: AppTheme.adaptiveDivider),
              Expanded(
                child: _buildInsightStat(
                  title: 'Albums',
                  value: '$albumCount',
                  subtitle: 'Active',
                ),
              ),
              Container(width: 1, height: 40, color: AppTheme.adaptiveDivider),
              Expanded(
                child: _buildInsightStat(
                  title: 'Shared',
                  value: '$publicMemories',
                  subtitle: 'Publicly',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightStat({
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.playfairDisplay(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppTheme.adaptiveTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.adaptiveTextPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: AppTheme.adaptiveTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoverSection() {
    return SizedBox(
      height: 176,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _featuredVoices.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = _featuredVoices[index];
          final accent = item['accent'] as Color;

          return GestureDetector(
            onTap: () => Get.to(() => const DiscoverScreen()),
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.adaptiveCardBg,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: accent.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(item['icon'] as IconData, color: accent),
                  ),
                  const Spacer(),
                  Text(
                    item['title'] as String,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.adaptiveTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['subtitle'] as String,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      height: 1.55,
                      color: AppTheme.adaptiveTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double rotation;
  final List<Color> gradientColors;
  final double strokeWidth;

  _GradientBorderPainter({
    required this.rotation,
    required this.gradientColors,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = SweepGradient(
        colors: gradientColors,
        transform: GradientRotation(rotation),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.gradientColors != gradientColors ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}


class _QuickActionData {
  const _QuickActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
}
