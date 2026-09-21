import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/media_url_formatter.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../memories/presentation/cubits/memories_cubit.dart';
import '../../../memories/presentation/pages/memory_detail_page.dart';
import '../../../memories/presentation/widgets/memory_card.dart';
import '../../../memories/presentation/widgets/publish_wizard_modal.dart';
import '../../domain/entities/family_member_entity.dart';
import '../cubits/family_cubit.dart';
import '../pages/qr_scanner_page.dart';
import '../widgets/family_tree_widget.dart';
import '../widgets/invite_member_modal.dart';

class FamilyCirclePage extends StatefulWidget {
  final int initialTab;
  const FamilyCirclePage({super.key, this.initialTab = 0});

  @override
  State<FamilyCirclePage> createState() => _FamilyCirclePageState();
}

class _FamilyCirclePageState extends State<FamilyCirclePage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  String _selectedMemberFilterId = 'ALL';
  String _selectedFormatFilter = 'ALL';
  String _memorySearchQuery = '';
  final TextEditingController _memorySearchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
    final familyCubit = context.read<FamilyCubit>();
    if (familyCubit.state is! FamilyLoaded) {
      familyCubit.loadFamilyCircle();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _memorySearchController.dispose();
    super.dispose();
  }

  void _openInviteModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<FamilyCubit>(),
        child: const InviteMemberModal(),
      ),
    );
  }

  void _openCreateMemoryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => BlocProvider.value(
        value: sl<MemoriesCubit>(),
        child: const PublishWizardModal(initialPrivacy: 'Family'),
      ),
    ).then((_) {
      if (mounted) {
        context.read<FamilyCubit>().loadFamilyCircle(forceRefresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<FamilyCubit, FamilyState>(
        builder: (context, state) {
          int totalInvitesBadge = 0;
          if (state is FamilyLoaded) {
            totalInvitesBadge =
                state.myInvitations.length +
                state.pendingApprovals.length +
                state.awaitingApprovalInvites.length;
          }

          return Column(
            children: [
              // Tab bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderLight, width: 1),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                  labelStyle: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: GoogleFonts.outfit(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  tabs: [
                    const Tab(text: 'Members'),
                    const Tab(text: 'Family Tree'),
                    const Tab(text: 'Memories'),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Invitations'),
                          if (totalInvitesBadge > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$totalInvitesBadge',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Builder(
                  builder: (context) {
                    if (state is FamilyLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is FamilyError) {
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
                                style: GoogleFonts.outfit(
                                  color: AppColors.error,
                                ),
                              ),
                              const SizedBox(height: 16),
                              AppButton(
                                label: 'Retry',
                                expand: false,
                                onPressed: () => context
                                    .read<FamilyCubit>()
                                    .loadFamilyCircle(),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (state is FamilyLoaded) {
                      final authState = context.watch<AuthCubit>().state;
                      final currentUserId = authState is Authenticated
                          ? authState.user.id
                          : null;
                      final currentUser = authState is Authenticated
                          ? authState.user
                          : null;

                      return TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: Members
                          _buildMembersTab(context, state),
                          // Tab 2: Family Tree
                          FamilyTreeWidget(
                            members: state.members,
                            pendingApprovals: state.pendingApprovals,
                            currentUserId: currentUserId,
                            currentUser: currentUser,
                            onAddMember: _openInviteModal,
                            onApprovePending: (id) => context
                                .read<FamilyCubit>()
                                .approveInvitation(id),
                            onDeclinePending: (id) =>
                                context.read<FamilyCubit>().declineApproval(id),
                            onRefresh: () =>
                                context.read<FamilyCubit>().loadFamilyCircle(),
                          ),
                          // Tab 3: Shared Memories
                          _buildMemoriesTab(context, state),
                          // Tab 4: Invitations (Pending Approvals + Incoming Invitations)
                          _buildInvitationsTab(context, state),
                        ],
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────
  //  TAB 1: Members — Connected Family Style
  // ──────────────────────────────────────────
  Widget _buildMembersTab(BuildContext context, FamilyLoaded state) {
    // Merge confirmed members with any pending approvals awaiting admin action
    final List<FamilyMemberEntity> displayedMembers = List.from(state.members);
    for (final pending in state.pendingApprovals) {
      final isAlreadyIn = displayedMembers.any(
        (m) =>
            m.id == pending.id ||
            (pending.inviterEmail != null &&
                m.user?.email == pending.inviterEmail) ||
            (pending.receiverName != null &&
                m.user?.name == pending.receiverName),
      );
      if (!isAlreadyIn) {
        displayedMembers.add(
          FamilyMemberEntity(
            id: pending.id,
            user: User(
              id: pending.id,
              email: pending.inviterEmail ?? '',
              name:
                  pending.receiverName ??
                  pending.inviterName ??
                  'Family Member',
              avatarUrl: pending.receiverAvatar ?? pending.inviterAvatar,
            ),
            relationship: pending.relationship,
            role: 'member',
            status: 'pending',
          ),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: () =>
          context.read<FamilyCubit>().loadFamilyCircle(forceRefresh: true),
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          // Action Required Banner for Admins
          if (state.pendingApprovals.isNotEmpty)
            GestureDetector(
              onTap: () => _tabController.animateTo(3),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.amber,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${state.pendingApprovals.length} Member Join Request${state.pendingApprovals.length > 1 ? "s" : ""}',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.amber.shade900,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Tap to review and approve new family circle members.',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.amber,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

          // Header info bar
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connected Family',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${displayedMembers.length} member${displayedMembers.length != 1 ? 's' : ''} · Private circle',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _openInviteModal,
                  icon: const Icon(
                    Icons.person_add_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: Text(
                    'Invite',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),

          if (displayedMembers.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40, bottom: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 56,
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No connected family members yet.\nTap Invite to build your circle!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            )
          else
            ...displayedMembers.map(
              (member) =>
                  _buildMemberCard(context, member, state.isAdmin, state),
            ),

          // Bottom CTAs
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedMemberFilterId = 'ALL';
                      });
                      _tabController.animateTo(2);
                    },
                    icon: const Icon(Icons.photo_library_outlined, size: 16),
                    label: Text(
                      'Shared Memories',
                      style: GoogleFonts.outfit(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _tabController.animateTo(1),
                    icon: const Icon(Icons.account_tree_outlined, size: 16),
                    label: Text(
                      'Family Tree',
                      style: GoogleFonts.outfit(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
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

  Widget _buildMemberCard(
    BuildContext context,
    FamilyMemberEntity member,
    bool isAdmin,
    FamilyLoaded state,
  ) {
    final avatar = MediaUrlFormatter.format(member.user?.avatarUrl);
    final name = member.user?.name ?? 'Family Member';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'F';
    final isPending = member.status == 'pending';
    final isLegacyAccess =
        (member.role == 'admin' || member.role == 'ADMIN') && !isPending;
    final joinedDate = _formatJoinDate(member.joinedAt);

    final memCount = state.sharedMemories.where((mem) {
      final matchesId =
          member.user?.id != null &&
          (mem.author?.id == member.user!.id ||
              mem.author?.firebaseUid == member.user!.id);
      final matchesEmail =
          member.user?.email != null &&
          mem.author?.email.toLowerCase() == member.user!.email.toLowerCase();
      return matchesId || matchesEmail;
    }).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending ? Colors.amber.shade400 : const Color(0xFF6366F1),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPending ? Colors.amber : const Color(0xFF6366F1))
                .withValues(alpha: 0.06),
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
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: isPending
                    ? Colors.amber.shade50
                    : const Color(0xFFEEF2FF),
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? Text(
                        initials,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: isPending
                              ? Colors.amber.shade800
                              : const Color(0xFF4A3AFF),
                          fontSize: 20,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Name + relationship info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: const Color(0xFF1E1B4B),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          member.relationship,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: isPending
                                ? Colors.amber.shade800
                                : const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (!isPending) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite_border_rounded,
                                size: 13,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '$memCount shared',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 13,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                joinedDate,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            '• Awaiting Approval',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // Badge
              if (isPending)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 11,
                        color: Colors.amber.shade900,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Join Request',
                        style: GoogleFonts.outfit(
                          fontSize: 10.5,
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                _buildAccessBadge(
                  isLegacyAccess ? 'Legacy Access' : 'Public Only',
                  isLegacyAccess,
                ),
            ],
          ),

          const SizedBox(height: 12),
          // Horizontal divider line
          Container(
            height: 1,
            color: const Color(0xFFC7D2FE).withValues(alpha: 0.8),
          ),
          const SizedBox(height: 12),

          // Action buttons (Sleek height)
          Row(
            children: [
              if (isPending) ...[
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton(
                      onPressed: () => context
                          .read<FamilyCubit>()
                          .declineApproval(member.id),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.borderLight),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: () => context
                          .read<FamilyCubit>()
                          .approveInvitation(member.id),
                      icon: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                      label: Text(
                        'Approve & Connect',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
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
              ] else ...[
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedMemberFilterId = member.user?.id ?? 'ALL';
                        });
                        _tabController.animateTo(2);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A3AFF),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 38),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'View Shared',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
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
                    child: isAdmin
                        ? PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'promote') {
                                context.read<FamilyCubit>().promoteMember(
                                  member.id,
                                );
                              } else if (val == 'remove') {
                                context.read<FamilyCubit>().removeMember(
                                  member.id,
                                );
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'promote',
                                child: Text('Make Admin'),
                              ),
                              const PopupMenuItem(
                                value: 'remove',
                                child: Text(
                                  'Remove',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                            child: OutlinedButton(
                              onPressed: null,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF4A3AFF),
                                  width: 1,
                                ),
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 38),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Manage Access',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF1E1B4B),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                        : OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFF4A3AFF),
                                width: 1,
                              ),
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 38),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Manage Access',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF1E1B4B),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccessBadge(String label, bool isLegacy) {
    if (isLegacy) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF15803D),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_outlined, size: 11, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10.5,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1D5CE),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 11,
              color: Color(0xFFC2410C),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10.5,
                color: const Color(0xFFC2410C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
  }

  String _formatJoinDate(String? joinedAt) {
    if (joinedAt == null) return 'Recently';
    try {
      final dt = DateTime.parse(joinedAt);
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
      return '${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return 'Recently';
    }
  }

  // ──────────────────────────────────────────
  //  TAB 3: Shared Memories
  // ──────────────────────────────────────────
  Widget _buildMemoriesTab(BuildContext context, FamilyLoaded state) {
    final filteredMemories = state.sharedMemories.where((m) {
      // 1. Member filter
      if (_selectedMemberFilterId != 'ALL') {
        final matchesId =
            m.author?.id == _selectedMemberFilterId ||
            m.author?.firebaseUid == _selectedMemberFilterId;
        final selectedMember = state.members.firstWhere(
          (mb) => mb.user?.id == _selectedMemberFilterId,
          orElse: () => state.members.first,
        );
        final matchesEmail =
            selectedMember.user?.email != null &&
            m.author?.email.toLowerCase() ==
                selectedMember.user!.email.toLowerCase();
        if (!matchesId && !matchesEmail) return false;
      }

      // 2. Format filter
      if (_selectedFormatFilter != 'ALL') {
        final normType = (m.mediaType ?? '').toLowerCase();
        if (_selectedFormatFilter == 'Voice' &&
            normType != 'voice' &&
            normType != 'audio') {
          return false;
        }
        if (_selectedFormatFilter == 'Photo' &&
            normType != 'image' &&
            normType != 'photo' &&
            normType != 'visual') {
          return false;
        }
        if (_selectedFormatFilter == 'Written' &&
            normType != 'text' &&
            normType != 'written' &&
            (m.mediaUrl != null && m.mediaUrl!.isNotEmpty)) {
          return false;
        }
      }

      // 3. Search query
      if (_memorySearchQuery.isNotEmpty) {
        final q = _memorySearchQuery.toLowerCase();
        final titleMatch = m.title.toLowerCase().contains(q);
        final descMatch = (m.description ?? '').toLowerCase().contains(q);
        if (!titleMatch && !descMatch) return false;
      }

      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: () =>
          context.read<FamilyCubit>().loadFamilyCircle(forceRefresh: true),
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Header info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Shared Family Memories',
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A3AFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${state.sharedMemories.length}',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stories and photos shared across your family circle.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: Color(0xFF4A3AFF),
                  size: 28,
                ),
                onPressed: _openCreateMemoryModal,
                tooltip: 'Create Family Story',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: TextField(
              controller: _memorySearchController,
              onChanged: (val) {
                setState(() {
                  _memorySearchQuery = val.trim();
                });
              },
              style: GoogleFonts.outfit(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search family stories...',
                hintStyle: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: _memorySearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _memorySearchController.clear();
                          setState(() {
                            _memorySearchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Member Filter Horizontal List
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMemberFilterChip(
                  label: 'All Members',
                  isSelected: _selectedMemberFilterId == 'ALL',
                  onTap: () => setState(() => _selectedMemberFilterId = 'ALL'),
                ),
                const SizedBox(width: 8),
                ...state.members.map((m) {
                  final uid = m.user?.id ?? '';
                  final name = m.user?.name ?? m.user?.email ?? 'Member';
                  final isSelected = _selectedMemberFilterId == uid;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildMemberFilterChip(
                      label: '$name (${m.relationship})',
                      isSelected: isSelected,
                      initial: name.isNotEmpty ? name[0].toUpperCase() : 'M',
                      onTap: () =>
                          setState(() => _selectedMemberFilterId = uid),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Media Format Horizontal List
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFormatChip(label: 'All Formats', value: 'ALL'),
                const SizedBox(width: 8),
                _buildFormatChip(label: '🎙️ Voice Stories', value: 'Voice'),
                const SizedBox(width: 8),
                _buildFormatChip(label: '📷 Photos', value: 'Photo'),
                const SizedBox(width: 8),
                _buildFormatChip(label: '📝 Written', value: 'Written'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Empty state or Memory list
          if (filteredMemories.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        size: 32,
                        color: Color(0xFF4A3AFF),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Shared Family Memories Yet',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'When connected family members publish memories with family or public privacy, they will automatically appear here.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _openCreateMemoryModal,
                      icon: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        'Create Family Story',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A3AFF),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            BlocProvider.value(
              value: sl<MemoriesCubit>(),
              child: Column(
                children: filteredMemories.map((m) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: MemoryCard(
                      memory: m,
                      onTap: () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    MemoryDetailPage(memoryId: m.id),
                              ),
                            )
                            .then((_) {
                              if (context.mounted) {
                                context.read<FamilyCubit>().loadFamilyCircle(
                                  forceRefresh: true,
                                );
                              }
                            });
                      },
                      onReact: (type) {
                        context.read<FamilyCubit>().reactToSharedMemory(
                          m.id,
                          type,
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMemberFilterChip({
    required String label,
    required bool isSelected,
    String? initial,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A3AFF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF4A3AFF) : AppColors.borderLight,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4A3AFF).withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (initial != null) ...[
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.3)
                      : const Color(0xFF6366F1),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatChip({required String label, required String value}) {
    final isSelected = _selectedFormatFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFormatFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E1B4B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  //  TAB 4: Invitations (Pending Approvals + Incoming)
  // ──────────────────────────────────────────
  Widget _buildInvitationsTab(BuildContext context, FamilyLoaded state) {
    final hasPendingApprovals = state.pendingApprovals.isNotEmpty;
    final hasIncomingInvites = state.myInvitations.isNotEmpty;

    return RefreshIndicator(
      onRefresh: () =>
          context.read<FamilyCubit>().loadFamilyCircle(forceRefresh: true),
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // 1. QR Scanner banner
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<FamilyCubit>(),
                    child: const QRScannerPage(),
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B3EFF), Color(0xFF7C5CFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan QR to Join',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Got a family invitation QR? Tap to scan and join.',
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          // 2. Section 1: Pending Admin Approvals (Admin review flow)
          if (hasPendingApprovals) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 16,
                      color: Colors.amber.shade900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pending Admin Approvals (${state.pendingApprovals.length})',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
            ),
            ...state.pendingApprovals.map(
              (approval) => _buildAdminApprovalCard(context, approval),
            ),
            const SizedBox(height: 12),
          ],

          // 3. Section 2: Direct Incoming Invitations
          if (hasIncomingInvites) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.mail_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Incoming Invitations (${state.myInvitations.length})',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            ...state.myInvitations.map(
              (inv) => _buildIncomingInvitationCard(context, inv),
            ),
          ],

          // 4. Section 3: Awaiting Admin Confirmation
          if (state.awaitingApprovalInvites.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      size: 16,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Awaiting Admin Approval (${state.awaitingApprovalInvites.length})',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4F46E5),
                    ),
                  ),
                ],
              ),
            ),
            ...state.awaitingApprovalInvites.map(
              (inv) => _buildAwaitingApprovalCard(context, inv),
            ),
          ],

          // 4. Section 3: Sent Invitations (Outgoing)
          if (state.sentInvitations.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      size: 16,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sent Invitations (${state.sentInvitations.length})',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            ...state.sentInvitations.map(
              (inv) => _buildSentInvitationCard(context, inv, state),
            ),
          ],

          // 5. Clean Empty State when none exists
          if (!hasPendingApprovals &&
              !hasIncomingInvites &&
              state.awaitingApprovalInvites.isEmpty &&
              state.sentInvitations.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.mail_outline_rounded,
                      size: 56,
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No active invitations or pending approvals.',
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Card for Admin Approval (when an invitee accepted and awaits admin final confirmation)
  Widget _buildAdminApprovalCard(
    BuildContext context,
    FamilyInvitationEntity approval,
  ) {
    final avatar = MediaUrlFormatter.format(approval.receiverAvatar);
    final name =
        approval.receiverName ?? approval.inviterName ?? 'Family Member';
    final email = approval.inviterEmail ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'F';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade400, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.06),
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
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.amber.shade50,
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? Text(
                        initials,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: const Color(0xFF1E1B4B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade200),
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
                            'Wants to join as ${approval.relationship}',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.alternate_email_rounded,
                            size: 12,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              email,
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                color: const Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          // Horizontal divider line
          Container(height: 1, color: Colors.amber.shade100),
          const SizedBox(height: 12),

          // Sleek 38px Action buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () => context
                        .read<FamilyCubit>()
                        .declineApproval(approval.id),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Decline',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF64748B),
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
                    onPressed: () async {
                      await context.read<FamilyCubit>().approveInvitation(
                        approval.id,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '✓ $name is now connected in your Family Circle!',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    label: Text(
                      'Approve & Connect',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
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

  // Card for Direct Incoming Invitation
  Widget _buildIncomingInvitationCard(
    BuildContext context,
    FamilyInvitationEntity inv,
  ) {
    final avatar = MediaUrlFormatter.format(inv.inviterAvatar);
    final inviter = inv.inviterName ?? 'Family Member';
    final email = inv.inviterEmail ?? '';
    final initials = inviter.isNotEmpty ? inviter[0].toUpperCase() : 'F';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6366F1), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.06),
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
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFEEF2FF),
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? Text(
                        initials,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4A3AFF),
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inviter,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: const Color(0xFF1E1B4B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people_outline_rounded,
                            size: 12,
                            color: Color(0xFF4A3AFF),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Wants to connect as ${inv.relationship}',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4A3AFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.alternate_email_rounded,
                            size: 12,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              email,
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                color: const Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          // Horizontal divider line
          Container(
            height: 1,
            color: const Color(0xFFC7D2FE).withValues(alpha: 0.8),
          ),
          const SizedBox(height: 12),

          // Sleek 38px Action buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () =>
                        context.read<FamilyCubit>().declineFamilyInvite(inv.id),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Decline',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF64748B),
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
                    onPressed: () async {
                      await context.read<FamilyCubit>().acceptFamilyInvite(
                        inv.id,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '✓ Invitation accepted! Awaiting Admin approval to join Family Circle.',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: const Color(0xFF4F46E5),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    label: Text(
                      'Accept & Connect',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A3AFF),
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

  // Card for Awaiting Admin Confirmation (when invitee accepted and awaits admin final confirmation)
  Widget _buildAwaitingApprovalCard(
    BuildContext context,
    FamilyInvitationEntity inv,
  ) {
    final name = inv.inviterName ?? 'Family Member';
    final email = inv.inviterEmail ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC7D2FE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A3AFF).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4A3AFF)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'F',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: const Color(0xFF1E1B4B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Text(
                        'Invitation Accepted as ${inv.relationship}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4A3AFF),
                        ),
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Awaiting confirmation from Family Admin. You will automatically be connected once approved.',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      color: const Color(0xFF475569),
                      fontWeight: FontWeight.w500,
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

  // Card for Sent Invitations (invitations sent out by the current user)
  Widget _buildSentInvitationCard(
    BuildContext context,
    FamilyInvitationEntity inv,
    FamilyLoaded state,
  ) {
    final name = inv.receiverName ?? inv.email ?? 'Invited Member';
    final email = inv.email ?? '';
    final isAccepted =
        inv.status == 'ACCEPTED' ||
        state.pendingApprovals.any(
          (a) =>
              (inv.id.isNotEmpty && a.id == inv.id) ||
              (email.isNotEmpty &&
                  a.email?.toLowerCase() == email.toLowerCase()),
        );
    final isJoined =
        inv.status == 'APPROVED' ||
        state.members.any(
          (m) =>
              email.isNotEmpty &&
              m.user?.email.toLowerCase() == email.toLowerCase(),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAccepted
              ? Colors.amber.shade300
              : (isJoined ? const Color(0xFFA7F3D0) : AppColors.borderLight),
          width: isAccepted ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isAccepted
                        ? [Colors.amber.shade400, Colors.amber.shade700]
                        : (isJoined
                              ? [
                                  const Color(0xFF10B981),
                                  const Color(0xFF059669),
                                ]
                              : [
                                  const Color(0xFF6366F1),
                                  const Color(0xFF4A3AFF),
                                ]),
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'M',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: const Color(0xFF1E1B4B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Invited as ${inv.relationship}',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                        if (inv.createdAt != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '• ${_formatTime(inv.createdAt)}',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (email.isNotEmpty && email != name) ...[
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Status banner
          if (isAccepted) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16,
                    color: Colors.amber.shade900,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Accepted by recipient! Ready for your approval.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                  if (state.pendingApprovals.any(
                    (a) =>
                        (inv.id.isNotEmpty && a.id == inv.id) ||
                        (email.isNotEmpty &&
                            a.email?.toLowerCase() == email.toLowerCase()),
                  )) ...[
                    GestureDetector(
                      onTap: () {
                        final approval = state.pendingApprovals.firstWhere(
                          (a) =>
                              (inv.id.isNotEmpty && a.id == inv.id) ||
                              (email.isNotEmpty &&
                                  a.email?.toLowerCase() ==
                                      email.toLowerCase()),
                        );
                        context.read<FamilyCubit>().approveInvitation(
                          approval.id,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Approve',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else if (isJoined) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Connected to Family Circle',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF047857),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.mail_outline_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Invitation sent · Waiting for recipient to accept in-app',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
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
}
