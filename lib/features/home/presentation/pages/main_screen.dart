import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../albums/presentation/cubits/albums_cubit.dart';
import '../../../albums/presentation/widgets/create_album_modal.dart';
import '../../../discover/presentation/cubits/discover_cubit.dart';
import '../../../discover/presentation/pages/discover_page.dart';
import '../../../family/presentation/cubits/family_cubit.dart';
import '../../../family/presentation/pages/family_circle_page.dart';
import '../../../memories/presentation/cubits/memories_cubit.dart';
import '../../../memories/presentation/pages/feed_page.dart';
import '../../../memories/presentation/pages/timeline_page.dart';
import '../../../memories/presentation/widgets/create_memory_modal.dart';
import '../../../notifications/presentation/cubits/notifications_cubit.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../notifications/presentation/widgets/in_app_notification_banner.dart';
import '../../../profile/presentation/cubits/profile_cubit.dart';
import '../../../record/presentation/pages/record_studio_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    FeedPage(),
    TimelinePage(),
    DiscoverPage(),
    RecordStudioPage(),
    FamilyCirclePage(),
    SettingsPage(),
  ];

  void _showCreateOptionsModal(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create & Record',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Option 1: Record Voice Story
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.mic_rounded, color: AppColors.primary),
                ),
                title: Text(
                  'Record Voice Story',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Text(
                  'Record audio story directly with live waveform visualizer',
                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 3);
                },
              ),
              const Divider(height: 16),

              // Option 2: Create Memory Story
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.post_add_rounded, color: AppColors.primary),
                ),
                title: Text(
                  'Create Memory',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Text(
                  'Add title, story description, media, tags & privacy',
                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: parentContext,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (_) => BlocProvider.value(
                      value: parentContext.read<MemoriesCubit>(),
                      child: const CreateMemoryModal(),
                    ),
                  );
                },
              ),
              const Divider(height: 16),

              // Option 3: Create Album
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.folder_special_rounded, color: AppColors.primary),
                ),
                title: Text(
                  'Create Memory Album',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Text(
                  'Organize memories into custom themed albums',
                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: parentContext,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (_) => BlocProvider.value(
                      value: parentContext.read<AlbumsCubit>(),
                      child: const CreateAlbumModal(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MemoriesCubit>(create: (_) => sl<MemoriesCubit>()),
        BlocProvider<DiscoverCubit>(create: (_) => sl<DiscoverCubit>()),
        BlocProvider<FamilyCubit>(create: (_) => sl<FamilyCubit>()),
        BlocProvider<AlbumsCubit>(create: (_) => sl<AlbumsCubit>()),
        BlocProvider<ProfileCubit>(create: (_) => sl<ProfileCubit>()),
        BlocProvider<NotificationsCubit>(
          create: (_) => sl<NotificationsCubit>()..startRealtimeSync(),
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Text(
            'Spoken Odyssey',
            style: GoogleFonts.outfit(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          actions: [
            Builder(
              builder: (context) {
                return BlocBuilder<NotificationsCubit, NotificationsState>(
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
                                  value: context.read<NotificationsCubit>(),
                                  child: const NotificationsPage(),
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
                                unreadCount > 99 ? '99+' : '$unreadCount',
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
          ],
        ),

        body: BlocListener<NotificationsCubit, NotificationsState>(
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
          child: IndexedStack(index: _currentIndex, children: _pages),
        ),
        
        // True Floating Action Button
        floatingActionButton: GestureDetector(
          onTap: () => _showCreateOptionsModal(context),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF6D28D9), // Deep purple matching the screenshot
              borderRadius: BorderRadius.circular(16), // Rounded square
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6D28D9).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

        // Clean, readable, full-width modern Bottom Navigation Bar
        bottomNavigationBar: Builder(
          builder: (context) {
            final bottomPadding = MediaQuery.of(context).padding.bottom;
            return Container(
              padding: EdgeInsets.only(bottom: bottomPadding), // Respect system safe area
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
              ),
              child: SizedBox(
                height: 72, // Generous height for touch targets and readability
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildNavItem(0, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
                    _buildNavItem(1, Icons.auto_stories_outlined, Icons.auto_stories_rounded, 'Memories'),
                    _buildNavItem(2, Icons.explore_outlined, Icons.explore_rounded, 'Discover'),
                    _buildNavItem(4, Icons.people_outline_rounded, Icons.people_rounded, 'Family'),
                    _buildNavItem(5, Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _currentIndex = index);
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
