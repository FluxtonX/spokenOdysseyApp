import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:spokenodyssey/features/memories/presentation/widgets/ai_historian_sheet.dart';
import 'package:spokenodyssey/features/profile/presentation/pages/profile_page.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../albums/presentation/cubits/albums_cubit.dart';
import '../../../discover/presentation/cubits/discover_cubit.dart';
import '../../../discover/presentation/pages/discover_page.dart';
import '../../../family/presentation/cubits/family_cubit.dart';
import '../../../family/presentation/pages/family_circle_page.dart';
import '../../../memories/presentation/cubits/memories_cubit.dart';
import '../../../memories/presentation/pages/timeline_page.dart';
import '../../../notifications/presentation/cubits/notifications_cubit.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../notifications/presentation/widgets/in_app_notification_banner.dart';
import '../../../profile/presentation/cubits/profile_cubit.dart';
import '../../../record/presentation/pages/record_studio_page.dart';
import '../../../family/presentation/widgets/invite_member_modal.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../profile/presentation/cubits/followers_cubit.dart';
import '../../../smart_glasses/presentation/widgets/smart_glasses_status_bar.dart';
import '../widgets/create_options_modal.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isAppBarVisible = true;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        final result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showMaterialBanner(
              MaterialBanner(
                backgroundColor: AppColors.primary,
                contentTextStyle: GoogleFonts.outfit(color: Colors.white),
                content: const Text('An update has been downloaded.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      InAppUpdate.completeFlexibleUpdate();
                      ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                    },
                    child: Text(
                      'INSTALL NOW',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('In-app update error: $e');
    }
  }

  final List<Widget> _pages = const [
    TimelinePage(),
    DiscoverPage(),
    RecordStudioPage(),
    FamilyCirclePage(),
    ProfilePage(),
  ];

  void _showCreateOptionsModal(BuildContext parentContext) {
    CreateOptionsModal.show(
      parentContext,
      onRecordVoiceStory: () {
        setState(() => _currentIndex = 2);
      },
    );
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Spoken Odyssey';
      case 1:
        return 'Discover Odysseys';
      case 2:
        return 'Voice Studio';
      case 3:
        return 'Family Circle';
      case 4:
        return 'My Profile';
      default:
        return 'Spoken Odyssey';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MemoriesCubit>(
          create: (_) => sl<MemoriesCubit>()..loadMemories(),
        ),
        BlocProvider<DiscoverCubit>(create: (_) => sl<DiscoverCubit>()),
        BlocProvider<FamilyCubit>(
          create: (_) => sl<FamilyCubit>()..loadFamilyCircle(),
        ),
        BlocProvider<AlbumsCubit>(
          create: (_) => sl<AlbumsCubit>()..loadAlbums(),
        ),
        BlocProvider<ProfileCubit>(
          create: (_) => sl<ProfileCubit>()..loadProfile(),
        ),
        BlocProvider<FollowersCubit>(
          create: (_) => sl<FollowersCubit>()..loadFollowers(),
        ),
        BlocProvider<NotificationsCubit>(
          create: (_) => sl<NotificationsCubit>()..startRealtimeSync(),
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _currentIndex == 4
            ? null
            : PreferredSize(
                preferredSize: Size.fromHeight(
                  _isAppBarVisible ? kToolbarHeight : 0,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  height: _isAppBarVisible
                      ? (kToolbarHeight + MediaQuery.of(context).padding.top)
                      : 0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOutCubic,
                    offset: _isAppBarVisible
                        ? Offset.zero
                        : const Offset(0, -1),
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: AppBar(
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        automaticallyImplyLeading:
                            false, // main tab — never show back button
                        titleSpacing: 20,
                        title: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.04, 0.0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            _getTitleForIndex(_currentIndex),
                            key: ValueKey<int>(_currentIndex),
                            style: GoogleFonts.outfit(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        actions: [
                          const SmartGlassesStatusBar(),
                          IconButton(
                            icon: const Icon(
                              Icons.auto_awesome_rounded,
                              color: AppColors.primary,
                            ),
                            tooltip: 'AI Family Historian',
                            onPressed: () => AiHistorianSheet.show(context),
                          ),
                          if (_currentIndex == 3)
                            Builder(
                              builder: (ctx) {
                                return IconButton(
                                  icon: const Icon(
                                    Icons.person_add_alt_1_rounded,
                                    color: AppColors.primary,
                                  ),
                                  tooltip: 'Invite Member',
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.white,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(24),
                                        ),
                                      ),
                                      builder: (_) => BlocProvider.value(
                                        value: ctx.read<FamilyCubit>(),
                                        child: const InviteMemberModal(),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          Builder(
                            builder: (context) {
                              return BlocBuilder<
                                NotificationsCubit,
                                NotificationsState
                              >(
                                builder: (context, notifState) {
                                  int unreadCount = 0;
                                  if (notifState is NotificationsLoaded) {
                                    unreadCount = notifState.unreadCount;
                                  }
                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.notifications_none_rounded,
                                          color: AppColors.textPrimary,
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => BlocProvider.value(
                                                value: context
                                                    .read<NotificationsCubit>(),
                                                child:
                                                    const NotificationsPage(),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      if (unreadCount > 0)
                                        Positioned(
                                          right: 8,
                                          top: 8,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 16,
                                              minHeight: 16,
                                            ),
                                            child: Text(
                                              unreadCount > 99
                                                  ? '99+'
                                                  : '$unreadCount',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

        body: MultiBlocListener(
          listeners: [
            BlocListener<AuthCubit, AuthState>(
              listener: (context, state) {
                if (state is Unauthenticated) {
                  // Go to sign-in on logout — onboarding is only for new users
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/sign-in',
                    (route) => false,
                  );
                }
              },
            ),
            BlocListener<NotificationsCubit, NotificationsState>(
              listener: (context, state) {
                if (state is NotificationsLoaded &&
                    state.newestNotification != null) {
                  final notif = state.newestNotification!;

                  // Trigger interactive top floating banner
                  showInAppNotificationBanner(
                    context,
                    notif,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: context.read<NotificationsCubit>(),
                            child: const NotificationsPage(),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ],
          child: NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction == ScrollDirection.reverse) {
                if (_isAppBarVisible) {
                  setState(() => _isAppBarVisible = false);
                }
              } else if (notification.direction == ScrollDirection.forward) {
                if (!_isAppBarVisible) {
                  setState(() => _isAppBarVisible = true);
                }
              }
              return false;
            },
            child: IndexedStack(index: _currentIndex, children: _pages),
          ),
        ),
        // True Floating Action Button docked to center
        floatingActionButton: GestureDetector(
          onTap: () => _showCreateOptionsModal(context),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16), // Modern rounded square
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        // Clean, readable, full-width modern Bottom Navigation Bar
        bottomNavigationBar: Builder(
          builder: (context) {
            final bottomPadding = MediaQuery.of(context).padding.bottom;
            return Container(
              padding: EdgeInsets.only(bottom: bottomPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                height: 60, // Sleek, notch-aware height
                child: Row(
                  children: [
                    _buildNavItem(
                      0,
                      Icons.home_outlined,
                      Icons.home_rounded,
                      'Home',
                    ),
                    _buildNavItem(
                      1,
                      Icons.explore_outlined,
                      Icons.explore_rounded,
                      'Discover',
                    ),

                    // Empty space in the exact center for the docked FAB
                    const SizedBox(width: 60),

                    _buildNavItem(
                      3,
                      Icons.people_outline_rounded,
                      Icons.people_rounded,
                      'Family',
                    ),
                    _buildNavItem(
                      4,
                      Icons.person_outline_rounded,
                      Icons.person_rounded,
                      'Profile',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _currentIndex = index);
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top active indicator pill bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              height: 3,
              width: isSelected ? 24 : 0,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(2),
                ),
              ),
            ),

            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      isSelected ? activeIcon : icon,
                      key: ValueKey(isSelected),
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 10.5,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 1),
          ],
        ),
      ),
    );
  }
}
