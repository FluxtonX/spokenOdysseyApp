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
                  setState(() => _currentIndex = 2);
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

        // Custom Bottom Navigation Bar using Stack to make '+' button straddle top border line exactly like the screenshot
        bottomNavigationBar: Builder(
          builder: (context) {
            return SizedBox(
              height: 86,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  // Bottom Bar Container with Top Border Line
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(
                            color: AppColors.primary.withOpacity(0.6),
                            width: 1.2,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _buildNavItem(
                            index: 0,
                            icon: Icons.home_outlined,
                            activeIcon: Icons.home_rounded,
                            label: 'Home',
                          ),
                          _buildNavItem(
                            index: 1,
                            icon: Icons.explore_outlined,
                            activeIcon: Icons.explore_rounded,
                            label: 'Discover',
                          ),

                          // Empty gap for center floating '+' button
                          const SizedBox(width: 58),

                          _buildNavItem(
                            index: 3,
                            icon: Icons.people_outline_rounded,
                            activeIcon: Icons.people_rounded,
                            label: 'Family',
                          ),
                          _buildNavItem(
                            index: 4,
                            icon: Icons.settings_outlined,
                            activeIcon: Icons.settings_rounded,
                            label: 'Setting',
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Floating Center '+' Square Button straddling top purple line
                  Positioned(
                    top: 0,
                    child: GestureDetector(
                      onTap: () => _showCreateOptionsModal(context),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _currentIndex = index);
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            // Active indicator dot/square under text
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
