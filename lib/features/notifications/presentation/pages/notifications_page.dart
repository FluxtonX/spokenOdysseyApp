import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_url_formatter.dart';
import '../../../memories/presentation/pages/memory_detail_page.dart';
import '../cubits/notifications_cubit.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsCubit>().loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              context.read<NotificationsCubit>().markAllAsRead();
            },
            child: Text('Mark all read', style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<NotificationsCubit>().loadNotifications(),
        child: BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) {
            if (state is NotificationsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is NotificationsLoaded) {
              if (state.notifications.isEmpty) {
                return ListView(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none_rounded, size: 64, color: AppColors.textLight),
                          const SizedBox(height: 12),
                          Text(
                            'No Notifications',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'You are all caught up!',
                            style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.notifications.length,
                itemBuilder: (context, index) {
                  final notif = state.notifications[index];
                  final senderAvatar = MediaUrlFormatter.format(notif.sender?.avatarUrl);

                  return Dismissible(
                    key: Key(notif.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) {
                      context.read<NotificationsCubit>().deleteNotification(notif.id);
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete_rounded, color: Colors.white),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        if (!notif.isRead) {
                          context.read<NotificationsCubit>().markAsRead(notif.id);
                        }
                        if (notif.targetId != null && notif.targetId!.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MemoryDetailPage(memoryId: notif.targetId!),
                            ),
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: notif.isRead ? Colors.white : AppColors.primary.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: notif.isRead ? AppColors.borderLight : AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              backgroundImage: senderAvatar != null ? NetworkImage(senderAvatar) : null,
                              child: senderAvatar == null
                                  ? const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 18)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notif.title,
                                    style: GoogleFonts.outfit(
                                      fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notif.message,
                                    style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (!notif.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            } else if (state is NotificationsError) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(child: Text(state.message, style: const TextStyle(color: Colors.red))),
                  ),
                ],
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}
