import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/media_url_formatter.dart';
import '../../../family/domain/entities/family_member_entity.dart';
import '../../../family/domain/repositories/family_repository.dart';
import '../../../family/presentation/cubits/family_cubit.dart';
import '../../../family/presentation/pages/family_circle_page.dart';
import '../../../memories/presentation/pages/memory_detail_page.dart';
import '../../domain/entities/notification_entity.dart';
import '../cubits/notifications_cubit.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _activeFilter = 'All';
  final Set<String> _processingInvitationIds = {};
  final Set<String> _acceptedInvitationNotifIds = {};
  List<FamilyInvitationEntity> _pendingApprovals = [];

  @override
  void initState() {
    super.initState();
    _loadAcceptedInvitationIds();
    _loadPendingApprovals();
    context.read<NotificationsCubit>().loadNotifications();
  }

  Future<void> _loadPendingApprovals() async {
    try {
      final familyRepo = sl<FamilyRepository>();
      final isAdmin = await familyRepo.isFamilyAdmin();
      if (!isAdmin) return;
      final approvals = await familyRepo.getPendingApprovals();
      if (mounted) {
        setState(() {
          _pendingApprovals = approvals;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleApproveJoinRequest(
    FamilyInvitationEntity approval,
  ) async {
    setState(() => _processingInvitationIds.add(approval.id));
    try {
      final familyRepo = sl<FamilyRepository>();
      await familyRepo.approveInvitation(approval.id);
      if (mounted) {
        setState(() {
          _pendingApprovals.removeWhere((p) => p.id == approval.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✓ Approved! ${approval.receiverName ?? "Member"} is now connected to your Family Circle.',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve request: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingInvitationIds.remove(approval.id));
      }
    }
  }

  Future<void> _handleDeclineJoinRequest(
    FamilyInvitationEntity approval,
  ) async {
    setState(() => _processingInvitationIds.add(approval.id));
    try {
      final familyRepo = sl<FamilyRepository>();
      await familyRepo.declineApproval(approval.id);
      if (mounted) {
        setState(() {
          _pendingApprovals.removeWhere((p) => p.id == approval.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Join request declined.'),
            backgroundColor: Colors.grey.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline request: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingInvitationIds.remove(approval.id));
      }
    }
  }

  Future<void> _loadAcceptedInvitationIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('accepted_invitation_notif_ids') ?? [];
      if (mounted) {
        setState(() {
          _acceptedInvitationNotifIds.addAll(list);
        });
      }
    } catch (_) {}
  }

  Future<void> _persistAcceptedId(String notifId, String? invId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('accepted_invitation_notif_ids') ?? [];
      if (!list.contains(notifId)) list.add(notifId);
      if (invId != null && invId.isNotEmpty && !list.contains(invId)) {
        list.add(invId);
      }
      await prefs.setStringList('accepted_invitation_notif_ids', list);
    } catch (_) {}
  }

  String _formatTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Recently';
    try {
      final date = DateTime.parse(dateString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'Recently';
    }
  }

  bool _isFamilyInvite(NotificationEntity notif) {
    final type = notif.type?.toUpperCase() ?? '';
    final title = notif.title.toLowerCase();
    final actionUrl = notif.actionUrl?.toLowerCase() ?? '';
    if (type == 'FAMILY_INVITE_APPROVED') return false;
    return type.contains('FAMILY_INVITE') ||
        type.contains('FAMILY_INVITATION') ||
        title.contains('family invitation') ||
        actionUrl == '/family' ||
        actionUrl == 'family';
  }

  bool _isFamilyApproved(NotificationEntity notif) {
    final type = notif.type?.toUpperCase() ?? '';
    final title = notif.title.toLowerCase();
    return type == 'FAMILY_INVITE_APPROVED' ||
        title.contains('family circle approved') ||
        title.contains('invitation approved');
  }

  List<NotificationEntity> _filterNotifications(List<NotificationEntity> all) {
    switch (_activeFilter) {
      case 'Unread':
        return all.where((n) => !n.isRead).toList();
      case 'Family':
        return all.where((n) {
          final t = n.type?.toUpperCase() ?? '';
          return t.contains('FAMILY') ||
              (n.actionUrl?.contains('family') ?? false);
        }).toList();
      case 'Social':
        return all.where((n) {
          final t = n.type?.toUpperCase() ?? '';
          return t.contains('MEMORY') ||
              t.contains('COMMENT') ||
              t.contains('LIKE') ||
              t.contains('FOLLOW');
        }).toList();
      case 'System':
        return all.where((n) {
          final t = n.type?.toUpperCase() ?? '';
          return t.contains('SYSTEM') ||
              t.contains('BILLING') ||
              t.contains('SECURITY');
        }).toList();
      default:
        return all;
    }
  }

  IconData _getIconForType(String? type) {
    final t = type?.toUpperCase() ?? '';
    if (t.contains('FAMILY')) return Icons.people_alt_rounded;
    if (t.contains('LIKE') || t.contains('HEART')) {
      return Icons.favorite_rounded;
    }
    if (t.contains('COMMENT')) return Icons.chat_bubble_rounded;
    if (t.contains('FOLLOW')) return Icons.person_add_rounded;
    if (t.contains('BILLING')) return Icons.credit_card_rounded;
    if (t.contains('SECURITY')) return Icons.security_rounded;
    return Icons.notifications_rounded;
  }

  Color _getIconBgColor(String? type) {
    final t = type?.toUpperCase() ?? '';
    if (t.contains('FAMILY')) return const Color(0xFF5B3EFF);
    if (t.contains('LIKE') || t.contains('HEART')) {
      return const Color(0xFFF43F5E);
    }
    if (t.contains('COMMENT')) return const Color(0xFF0D9488);
    if (t.contains('FOLLOW')) return const Color(0xFF3B82F6);
    if (t.contains('BILLING')) return const Color(0xFF9333EA);
    if (t.contains('SECURITY')) return const Color(0xFFF59E0B);
    return AppColors.primary;
  }

  Future<void> _handleAcceptInvite(NotificationEntity notif) async {
    final invitationId =
        notif.metadata?['invitationId']?.toString() ?? notif.targetId ?? '';

    if (invitationId.isEmpty) {
      _navigateToFamilyCircle();
      return;
    }

    setState(() => _processingInvitationIds.add(notif.id));
    try {
      final familyRepo = sl<FamilyRepository>();
      await familyRepo.acceptFamilyInvite(invitationId);

      if (mounted) {
        setState(() => _acceptedInvitationNotifIds.add(notif.id));
        context.read<NotificationsCubit>().markAsRead(notif.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.hourglass_top_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✓ Request sent to Family Admin for final approval!',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF4F46E5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        await _persistAcceptedId(notif.id, invitationId);
      }
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('already accepted') || errStr.contains('already')) {
        if (mounted) {
          setState(() => _acceptedInvitationNotifIds.add(notif.id));
          context.read<NotificationsCubit>().markAsRead(notif.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '✓ Invitation already accepted! Waiting for Admin approval.',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF4F46E5),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          await _persistAcceptedId(notif.id, invitationId);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to accept invitation: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _processingInvitationIds.remove(notif.id));
      }
    }
  }

  Future<void> _handleDeclineInvite(NotificationEntity notif) async {
    final invitationId =
        notif.metadata?['invitationId']?.toString() ?? notif.targetId ?? '';

    if (invitationId.isEmpty) return;

    setState(() => _processingInvitationIds.add(notif.id));
    try {
      final familyRepo = sl<FamilyRepository>();
      await familyRepo.declineFamilyInvite(invitationId);

      if (mounted) {
        context.read<NotificationsCubit>().markAsRead(notif.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invitation declined.',
              style: GoogleFonts.outfit(color: Colors.white),
            ),
            backgroundColor: Colors.grey.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline invitation: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingInvitationIds.remove(notif.id));
      }
    }
  }

  void _navigateToFamilyCircle() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider<FamilyCubit>(
          create: (_) => sl<FamilyCubit>()..loadFamilyCircle(),
          child: const Scaffold(
            body: SafeArea(child: FamilyCirclePage(initialTab: 3)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              final unread = state is NotificationsLoaded
                  ? state.unreadCount
                  : 0;
              return TextButton.icon(
                onPressed: unread > 0
                    ? () => context.read<NotificationsCubit>().markAllAsRead()
                    : null,
                icon: Icon(
                  Icons.done_all_rounded,
                  size: 18,
                  color: unread > 0 ? AppColors.primary : AppColors.textLight,
                ),
                label: Text(
                  'Mark all read',
                  style: GoogleFonts.outfit(
                    color: unread > 0 ? AppColors.primary : AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            context.read<NotificationsCubit>().loadNotifications(),
            _loadPendingApprovals(),
          ]);
        },
        child: BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) {
            if (state is NotificationsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is NotificationsError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppColors.error.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(color: AppColors.error),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context
                              .read<NotificationsCubit>()
                              .loadNotifications();
                          _loadPendingApprovals();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.outfit(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is NotificationsLoaded) {
              final filtered = _filterNotifications(state.notifications);
              final showPendingApprovals =
                  (_activeFilter == 'All' ||
                      _activeFilter == 'Unread' ||
                      _activeFilter == 'Family') &&
                  _pendingApprovals.isNotEmpty;

              return Column(
                children: [
                  // Filter Chips Bar (matching web)
                  _buildFilterTabBar(state),

                  // Notification List
                  Expanded(
                    child: (filtered.isEmpty && !showPendingApprovals)
                        ? ListView(
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.5,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.08,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.notifications_none_rounded,
                                        size: 48,
                                        color: AppColors.primary.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No Notifications in $_activeFilter',
                                      style: GoogleFonts.outfit(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'You are all caught up!',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                            children: [
                              // Pending Admin Approvals (Join Requests)
                              if (showPendingApprovals) ...[
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 8,
                                    top: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade100,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.admin_panel_settings_rounded,
                                          size: 14,
                                          color: Colors.amber.shade900,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Join Requests Awaiting Your Approval (${_pendingApprovals.length})',
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ..._pendingApprovals.map(
                                  (approval) =>
                                      _buildAdminApprovalCard(approval),
                                ),
                                const SizedBox(height: 12),
                                if (filtered.isNotEmpty) ...[
                                  Divider(
                                    color: Colors.grey.shade200,
                                    height: 24,
                                  ),
                                ],
                              ],

                              // Standard notifications list
                              ...filtered.map(
                                (notif) =>
                                    _buildNotificationCard(context, notif),
                              ),
                            ],
                          ),
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

  Widget _buildFilterTabBar(NotificationsLoaded state) {
    final familyCount =
        state.notifications.where((n) {
          final t = n.type?.toUpperCase() ?? '';
          return t.contains('FAMILY') ||
              (n.actionUrl?.contains('family') ?? false);
        }).length +
        _pendingApprovals.length;

    final unreadCount = state.unreadCount + _pendingApprovals.length;

    final filters = [
      {'id': 'All', 'label': 'All'},
      {
        'id': 'Unread',
        'label': 'Unread',
        'count': unreadCount > 0 ? unreadCount : null,
      },
      {
        'id': 'Family',
        'label': 'Family',
        'count': familyCount > 0 ? familyCount : null,
      },
      {'id': 'Social', 'label': 'Social'},
      {'id': 'System', 'label': 'System'},
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final id = f['id'] as String;
          final label = f['label'] as String;
          final count = f['count'] as int?;
          final isSelected = _activeFilter == id;

          return GestureDetector(
            onTap: () => setState(() => _activeFilter = id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.borderLight,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  if (count != null && count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? AppColors.primary : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationEntity notif,
  ) {
    final senderAvatar = MediaUrlFormatter.format(notif.sender?.avatarUrl);
    final isInvite = _isFamilyInvite(notif);
    final isApproved = _isFamilyApproved(notif);
    final isProcessing = _processingInvitationIds.contains(notif.id);
    final iconData = _getIconForType(notif.type);
    final iconBg = _getIconBgColor(notif.type);

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        context.read<NotificationsCubit>().deleteNotification(notif.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: notif.isRead
                ? AppColors.borderLight
                : AppColors.primary.withValues(alpha: 0.4),
            width: notif.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: notif.isRead ? 0.03 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                if (!notif.isRead) {
                  context.read<NotificationsCubit>().markAsRead(notif.id);
                }
                if (isInvite || notif.actionUrl == '/family') {
                  _navigateToFamilyCircle();
                } else if (notif.targetId != null &&
                    notif.targetId!.isNotEmpty &&
                    !notif.targetId!.startsWith('/')) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MemoryDetailPage(memoryId: notif.targetId!),
                    ),
                  );
                }
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon or Avatar
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: iconBg.withValues(alpha: 0.12),
                        backgroundImage: senderAvatar != null
                            ? NetworkImage(senderAvatar)
                            : null,
                        child: senderAvatar == null
                            ? Icon(iconData, color: iconBg, size: 22)
                            : null,
                      ),
                      if (!notif.isRead)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notif.title,
                                style: GoogleFonts.outfit(
                                  fontWeight: notif.isRead
                                      ? FontWeight.w600
                                      : FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              _formatTime(notif.createdAt),
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notif.message,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // If this notification is FAMILY_INVITE_APPROVED
            if (isApproved) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF10B981),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Connected to Family Circle! 🎉',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF047857),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _navigateToFamilyCircle,
                      child: Row(
                        children: [
                          Text(
                            'View Family',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Interactive Accept/Decline action buttons or Accepted Status for Family Invitations
            if (isInvite) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                  ),
                ),
                child: isProcessing
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ),
                      )
                    : (_acceptedInvitationNotifIds.contains(notif.id) ||
                          (notif.metadata?['invitationId'] != null &&
                              _acceptedInvitationNotifIds.contains(
                                notif.metadata!['invitationId'].toString(),
                              )))
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFC7D2FE)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.hourglass_top_rounded,
                                  color: Color(0xFF4F46E5),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Accepted · Awaiting Admin Approval',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF4338CA),
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: _navigateToFamilyCircle,
                              child: Row(
                                children: [
                                  Text(
                                    'View',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleAcceptInvite(notif),
                              icon: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              label: Text(
                                'Accept',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _handleDeclineInvite(notif),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.borderLight,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Decline',
                                style: GoogleFonts.outfit(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _navigateToFamilyCircle,
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            tooltip: 'View in Family Circle',
                          ),
                        ],
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdminApprovalCard(FamilyInvitationEntity approval) {
    final isProcessing = _processingInvitationIds.contains(approval.id);
    final receiverName = approval.receiverName ?? 'New Member';
    final relationship = approval.relationship;
    final initials = receiverName.isNotEmpty
        ? receiverName[0].toUpperCase()
        : 'M';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.amber.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade400, Colors.amber.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.admin_panel_settings_rounded,
                                size: 12,
                                color: Colors.amber.shade900,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ADMIN APPROVAL REQUIRED',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.amber.shade900,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$receiverName accepted your invitation',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: const Color(0xFF1E1B4B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ready to join your Family Circle as $relationship',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.amber.shade100),
          const SizedBox(height: 10),
          isProcessing
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton(
                          onPressed: () => _handleDeclineJoinRequest(approval),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Decline',
                            style: GoogleFonts.outfit(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: ElevatedButton.icon(
                          onPressed: () => _handleApproveJoinRequest(approval),
                          icon: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          label: Text(
                            'Approve & Connect',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
