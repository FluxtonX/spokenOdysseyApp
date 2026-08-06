import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/media_url_formatter.dart';
import '../../../memories/presentation/cubits/memories_cubit.dart';
import '../../../memories/presentation/widgets/memory_card.dart';
import '../cubits/family_cubit.dart';
import '../widgets/invite_member_modal.dart';

class FamilyCirclePage extends StatefulWidget {
  const FamilyCirclePage({super.key});

  @override
  State<FamilyCirclePage> createState() => _FamilyCirclePageState();
}

class _FamilyCirclePageState extends State<FamilyCirclePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<FamilyCubit>().loadFamilyCircle();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Family Circle',
          style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => BlocProvider.value(
                  value: context.read<FamilyCubit>(),
                  child: const InviteMemberModal(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Members'),
            Tab(text: 'Shared Memories'),
            Tab(text: 'Invitations'),
          ],
        ),
      ),
      body: BlocBuilder<FamilyCubit, FamilyState>(
        builder: (context, state) {
          if (state is FamilyLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is FamilyLoaded) {
            return Column(
              children: [
                // Admin Pending Approval Banner
                if (state.isAdmin && state.pendingApprovals.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.admin_panel_settings_rounded, color: Colors.amber),
                            const SizedBox(width: 8),
                            Text(
                              'Admin Action Required (${state.pendingApprovals.length})',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...state.pendingApprovals.map((req) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${req.inviterName ?? req.inviterEmail} (${req.relationship})',
                                style: GoogleFonts.outfit(fontSize: 13),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
                                    onPressed: () => context.read<FamilyCubit>().approveInvitation(req.id),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel_rounded, color: Colors.red),
                                    onPressed: () => context.read<FamilyCubit>().declineApproval(req.id),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Members
                      state.members.isEmpty
                          ? Center(
                              child: Text(
                                'No connected family members yet.\nTap + to invite your family!',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(color: AppColors.textSecondary),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: state.members.length,
                              itemBuilder: (context, index) {
                                final member = state.members[index];
                                final avatar = MediaUrlFormatter.format(member.user?.avatarUrl);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.borderLight),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: AppColors.primary.withOpacity(0.1),
                                        backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                                        child: avatar == null
                                            ? Text(
                                                member.user?.name?.isNotEmpty == true ? member.user!.name![0] : 'F',
                                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.primary),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              member.user?.name ?? 'Family Member',
                                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    member.relationship,
                                                    style: GoogleFonts.outfit(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                if (member.role == 'admin') ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.purple.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      'ADMIN',
                                                      style: GoogleFonts.outfit(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (state.isAdmin)
                                        PopupMenuButton<String>(
                                          onSelected: (val) {
                                            if (val == 'promote') {
                                              context.read<FamilyCubit>().promoteMember(member.id);
                                            } else if (val == 'remove') {
                                              context.read<FamilyCubit>().removeMember(member.id);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(value: 'promote', child: Text('Make Admin')),
                                            const PopupMenuItem(value: 'remove', child: Text('Remove', style: TextStyle(color: Colors.red))),
                                          ],
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),

                      // Tab 2: Shared Memories
                      state.sharedMemories.isEmpty
                          ? Center(
                              child: Text(
                                'No family shared memories found.',
                                style: GoogleFonts.outfit(color: AppColors.textSecondary),
                              ),
                            )
                          : BlocProvider.value(
                              value: sl<MemoriesCubit>(),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: state.sharedMemories.length,
                                itemBuilder: (context, index) {
                                  final m = state.sharedMemories[index];
                                  return MemoryCard(
                                    memory: m,
                                    onTap: () {},
                                    onReact: (_) {},
                                  );
                                },
                              ),
                            ),

                      // Tab 3: Invitations
                      state.myInvitations.isEmpty
                          ? Center(
                              child: Text(
                                'No active invitations.',
                                style: GoogleFonts.outfit(color: AppColors.textSecondary),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: state.myInvitations.length,
                              itemBuilder: (context, index) {
                                final inv = state.myInvitations[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.borderLight),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Invitation to join as ${inv.relationship}',
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'From: ${inv.inviterName ?? inv.inviterEmail ?? "Family Admin"}',
                                        style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ],
            );
          } else if (state is FamilyError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          }
          return const SizedBox();
        },
      ),
    );
  }
}
