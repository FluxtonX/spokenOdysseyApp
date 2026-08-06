import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notifications_repository.dart';

abstract class NotificationsState {}

class NotificationsInitial extends NotificationsState {}
class NotificationsLoading extends NotificationsState {}
class NotificationsLoaded extends NotificationsState {
  final List<NotificationEntity> notifications;
  final int unreadCount;
  final NotificationEntity? newestNotification;

  NotificationsLoaded({
    required this.notifications,
    required this.unreadCount,
    this.newestNotification,
  });
}
class NotificationsError extends NotificationsState {
  final String message;
  NotificationsError(this.message);
}

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationsRepository repository;
  Timer? _timer;

  NotificationsCubit({required this.repository}) : super(NotificationsInitial());

  void startRealtimeSync() {
    _timer?.cancel();
    loadNotifications();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) async {
      try {
        final count = await repository.getUnreadCount();
        final notifications = await repository.getNotifications();

        NotificationEntity? freshNotif;
        if (state is NotificationsLoaded) {
          final oldState = state as NotificationsLoaded;
          final oldIds = oldState.notifications.map((n) => n.id).toSet();
          final newUnread = notifications.where((n) => !n.isRead && !oldIds.contains(n.id)).toList();
          if (newUnread.isNotEmpty) {
            freshNotif = newUnread.first;
          }
        }

        emit(NotificationsLoaded(
          notifications: notifications,
          unreadCount: count,
          newestNotification: freshNotif,
        ));
      } catch (_) {}
    });
  }

  void stopRealtimeSync() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> loadNotifications() async {
    try {
      if (state is! NotificationsLoaded) {
        emit(NotificationsLoading());
      }
      final notifications = await repository.getNotifications();
      final count = await repository.getUnreadCount();
      emit(NotificationsLoaded(notifications: notifications, unreadCount: count));
    } catch (e) {
      if (state is! NotificationsLoaded) {
        emit(NotificationsError(e.toString()));
      }
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await repository.markAsRead(id);
      await loadNotifications();
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await repository.markAllAsRead();
      await loadNotifications();
    } catch (_) {}
  }

  Future<void> deleteNotification(String id) async {
    try {
      await repository.deleteNotification(id);
      await loadNotifications();
    } catch (_) {}
  }

  @override
  Future<void> close() {
    stopRealtimeSync();
    return super.close();
  }
}
