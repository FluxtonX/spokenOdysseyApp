import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/notification_entity.dart';

void showInAppNotificationBanner(BuildContext context, NotificationEntity notification, {VoidCallback? onTap}) {
  final overlayState = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) {
      return _NotificationBannerWidget(
        notification: notification,
        onDismiss: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
        onTap: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
          if (onTap != null) onTap();
        },
      );
    },
  );

  overlayState.insert(overlayEntry);
}

class _NotificationBannerWidget extends StatefulWidget {
  final NotificationEntity notification;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _NotificationBannerWidget({
    required this.notification,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  State<_NotificationBannerWidget> createState() => _NotificationBannerWidgetState();
}

class _NotificationBannerWidgetState extends State<_NotificationBannerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();

    _dismissTimer = Timer(const Duration(seconds: 4), () {
      _close();
    });
  }

  void _close() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: widget.onTap,
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
                _close();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B4B),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.notification.title.isNotEmpty
                              ? widget.notification.title
                              : 'New Notification',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.notification.message,
                          style: GoogleFonts.outfit(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _close,
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
