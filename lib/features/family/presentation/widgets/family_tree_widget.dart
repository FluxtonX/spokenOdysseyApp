import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_url_formatter.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/family_member_entity.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Supported Relationship Definitions & Tier Mapping
// ─────────────────────────────────────────────────────────────────────────────
enum FamilyTier {
  grandparents(0, 'GRANDPARENTS', 4, 'Grandparent'),
  parents(1, 'PARENTS', 3, 'Parent'),
  yourGeneration(2, 'YOUR GENERATION', 2, 'Sibling / Partner'),
  children(3, 'CHILDREN', 1, 'Child');

  final int tierIndex;
  final String label;
  final int genNumber;
  final String emptyLabel;
  const FamilyTier(this.tierIndex, this.label, this.genNumber, this.emptyLabel);
}

int _getTierForRelationship(String relationship) {
  final r = relationship.toLowerCase().trim();
  if (r.contains('grandparent') ||
      r.contains('grandfather') ||
      r.contains('grandmother') ||
      r.contains('dada') ||
      r.contains('dadi') ||
      r.contains('nana') ||
      r.contains('nani') ||
      r.contains('great')) {
    return 0; // Grandparents
  }
  if (r.contains('parent') ||
      r.contains('father') ||
      r.contains('mother') ||
      r.contains('dad') ||
      r.contains('mom') ||
      r.contains('uncle') ||
      r.contains('aunt') ||
      r.contains('stepfather') ||
      r.contains('stepmother') ||
      r.contains('in-law')) {
    return 1; // Parents
  }
  if (r.contains('child') ||
      r.contains('son') ||
      r.contains('daughter') ||
      r.contains('grandchild') ||
      r.contains('grandson') ||
      r.contains('granddaughter') ||
      r.contains('nephew') ||
      r.contains('niece') ||
      r.contains('kid')) {
    return 3; // Children
  }
  // Default: You, Sibling, Brother, Sister, Partner, Spouse, Husband, Wife, Cousin
  return 2; // Your Generation
}

const List<Color> _avatarColors = [
  Color(0xFF3B82F6), // Royal Blue
  Color(0xFFEC4899), // Pink
  Color(0xFF6366F1), // Indigo
  Color(0xFFF59E0B), // Amber
  Color(0xFF10B981), // Emerald
  Color(0xFFE11D48), // Rose
  Color(0xFF8B5CF6), // Purple
  Color(0xFF14B8A6), // Teal
  Color(0xFFF97316), // Orange
];

class FamilyTreeWidget extends StatefulWidget {
  final List<FamilyMemberEntity> members;
  final List<FamilyInvitationEntity> pendingApprovals;
  final String? currentUserId;
  final User? currentUser;
  final VoidCallback onAddMember;
  final Function(String id)? onApprovePending;
  final Function(String id)? onDeclinePending;
  final Future<void> Function()? onRefresh;

  const FamilyTreeWidget({
    super.key,
    required this.members,
    this.pendingApprovals = const [],
    this.currentUserId,
    this.currentUser,
    required this.onAddMember,
    this.onApprovePending,
    this.onDeclinePending,
    this.onRefresh,
  });

  @override
  State<FamilyTreeWidget> createState() => _FamilyTreeWidgetState();
}

class _FamilyTreeWidgetState extends State<FamilyTreeWidget> {
  // In-app relation customizations so user can assign any unassigned member
  final Map<String, String> _customRelationships = {};

  @override
  Widget build(BuildContext context) {
    // 1. Build complete member list using ONLY REAL USERS
    final List<FamilyMemberEntity> all = [];

    // Add accepted real members
    for (final m in widget.members) {
      final customRel = _customRelationships[m.id];
      if (customRel != null) {
        all.add(
          FamilyMemberEntity(
            id: m.id,
            user: m.user,
            relationship: customRel,
            role: m.role,
            status: m.status,
            joinedAt: m.joinedAt,
          ),
        );
      } else {
        all.add(m);
      }
    }

    // Add pending approvals from real invitations
    for (final p in widget.pendingApprovals) {
      final name = p.receiverName ?? p.inviterName ?? 'Family Member';
      final isAlready = all.any(
        (m) =>
            m.id == p.id ||
            m.user?.email == p.inviterEmail ||
            m.user?.name == name,
      );
      if (!isAlready) {
        all.add(
          FamilyMemberEntity(
            id: p.id,
            user: User(
              id: p.id,
              email: p.inviterEmail ?? '',
              name: name,
              avatarUrl: p.receiverAvatar ?? p.inviterAvatar,
            ),
            relationship: _customRelationships[p.id] ?? p.relationship,
            role: 'member',
            status: 'pending',
          ),
        );
      }
    }

    // Ensure 'You' (Current User) is in the tree
    final bool youPresent = all.any(
      (m) =>
          (widget.currentUserId != null &&
              m.user?.id == widget.currentUserId) ||
          (widget.currentUser != null &&
              (m.user?.id == widget.currentUser!.id ||
                  m.user?.email == widget.currentUser!.email)) ||
          m.relationship.toLowerCase() == 'you',
    );

    if (!youPresent && widget.currentUser != null) {
      all.add(
        FamilyMemberEntity(
          id: widget.currentUser!.id,
          user: widget.currentUser,
          relationship: 'You',
          role: 'admin',
          status: 'accepted',
        ),
      );
    }

    // 2. Classify real members into 4 generational tiers
    final Map<int, List<FamilyMemberEntity>> tiers = {
      0: [],
      1: [],
      2: [],
      3: [],
    };
    for (final m in all) {
      final t = _getTierForRelationship(m.relationship);
      tiers[t]!.add(m);
    }

    final int totalCount = all.length;
    final int generationCount = tiers.values.where((l) => l.isNotEmpty).length;

    final String familyTitle =
        widget.currentUser?.name != null &&
            widget.currentUser!.name!.trim().isNotEmpty
        ? '${widget.currentUser!.name!.trim().split(' ').first} Family Tree'
        : 'Family Tree';

    final listView = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // Pending approvals notification banner
        if (widget.pendingApprovals.isNotEmpty)
          _buildPendingBanner(widget.pendingApprovals.length),

        // ── Main Card Enclosing the Complete Family Tree ─────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header: Title & Generation count ───────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        familyTitle,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${generationCount > 0 ? generationCount : 1} generations · $totalCount members',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFF3F4F6)),

              const SizedBox(height: 14),

              // ── 1. GRANDPARENTS TIER (Gen 4) ───────────────────────────
              _buildTierSection(
                tier: FamilyTier.grandparents,
                members: tiers[0]!,
                showBottomBranch: true,
              ),

              // ── 2. PARENTS TIER (Gen 3) ────────────────────────────────
              _buildTierSection(
                tier: FamilyTier.parents,
                members: tiers[1]!,
                showBottomBranch: true,
              ),

              // ── 3. YOUR GENERATION TIER (Gen 2) ────────────────────────
              _buildTierSection(
                tier: FamilyTier.yourGeneration,
                members: tiers[2]!,
                showBottomBranch: true,
              ),

              // ── 4. CHILDREN TIER (Gen 1) ───────────────────────────────
              _buildTierSection(
                tier: FamilyTier.children,
                members: tiers[3]!,
                showBottomBranch: false,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Bottom Button: + Add family member ───────────────────────────
        GestureDetector(
          onTap: widget.onAddMember,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A3AFF), Color(0xFF635BFF)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A3AFF).withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Add family member',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),
      ],
    );

    return widget.onRefresh != null
        ? RefreshIndicator(
            onRefresh: widget.onRefresh!,
            color: AppColors.primary,
            child: listView,
          )
        : listView;
  }

  // ── Generation Tier Section with Responsive Layout ────────────────────────
  Widget _buildTierSection({
    required FamilyTier tier,
    required List<FamilyMemberEntity> members,
    required bool showBottomBranch,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Generation Header (e.g. GRANDPARENTS ──────── 4) ────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Text(
                tier.label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF6B7280),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(height: 1, color: const Color(0xFFE5E7EB)),
              ),
              const SizedBox(width: 10),
              Text(
                '${tier.genNumber}',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),

        // ── Responsive Dynamic Members / Empty Slot ───────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (members.isEmpty) {
                return _buildEmptySlotPlaceholder(tier, constraints.maxWidth);
              }
              return _buildResponsiveMembers(
                tier,
                members,
                constraints.maxWidth,
              );
            },
          ),
        ),

        // ── Branch Connector Line ─────────────────────────────────────────
        if (showBottomBranch) Center(child: _buildBranchConnector(tier)),
      ],
    );
  }

  // ── Responsive Layout Builder (No RenderFlex Overflow on Any Device) ──────
  Widget _buildResponsiveMembers(
    FamilyTier tier,
    List<FamilyMemberEntity> members,
    double availableWidth,
  ) {
    final int count = members.length;

    // Up to 4 members in row: calculate exact width to fit without overflow
    if (count <= 4) {
      // Calculate dynamic card width
      // spacing: (count - 1) * 6 + heart icons space
      final double totalSpacing = (count - 1) * 8.0;
      final double computedWidth = ((availableWidth - totalSpacing) / count)
          .clamp(62.0, 92.0);

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < count; i++) ...[
            _buildRealMemberCard(members[i], i, computedWidth),
            // Show couple heart between pairs of members (0&1, 2&3)
            if (i % 2 == 0 && i < count - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                child: Icon(
                  Icons.favorite_rounded,
                  size: 12,
                  color: const Color(0xFFF43F5E).withValues(alpha: 0.65),
                ),
              )
            else if (i < count - 1)
              const SizedBox(width: 6),
          ],
        ],
      );
    }

    // More than 4 members: wrap centered
    final double cardWidth = ((availableWidth - 24) / 4).clamp(64.0, 84.0);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 10,
      children: [
        for (int i = 0; i < count; i++)
          _buildRealMemberCard(members[i], i, cardWidth),
      ],
    );
  }

  // ── Empty Slot Placeholder (Clean, dashed card inviting user to add) ──────
  Widget _buildEmptySlotPlaceholder(FamilyTier tier, double availableWidth) {
    return Center(
      child: GestureDetector(
        onTap: widget.onAddMember,
        child: Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFD1D5DB),
              style: BorderStyle.solid,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC7D2FE), width: 1),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFF4A3AFF),
                  size: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tier.emptyLabel,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 1),
              Text(
                'Empty',
                style: GoogleFonts.outfit(
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF9CA3AF),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Real Member Card with Custom Dynamic Width ────────────────────────────
  Widget _buildRealMemberCard(
    FamilyMemberEntity member,
    int index,
    double cardWidth,
  ) {
    final bool isYou =
        (widget.currentUserId != null &&
            member.user?.id == widget.currentUserId) ||
        (widget.currentUser != null &&
            (member.user?.id == widget.currentUser!.id ||
                member.user?.email == widget.currentUser!.email)) ||
        member.relationship.toLowerCase() == 'you';

    final bool isPending = member.status == 'pending';
    final name = isYou
        ? (widget.currentUser?.name ?? member.user?.name ?? 'You')
        : (member.user?.name ?? 'Family Member');
    final firstName = name.split(' ').first;
    final initials = _getInitials(name);
    final avatarColor = isPending
        ? const Color(0xFFF59E0B)
        : _avatarColors[index % _avatarColors.length];
    final avatarUrl = MediaUrlFormatter.format(
      isYou
          ? (widget.currentUser?.avatarUrl ?? member.user?.avatarUrl)
          : member.user?.avatarUrl,
    );

    final relationshipLabel = isYou ? 'You' : member.relationship;

    return GestureDetector(
      onTap: () {
        if (isPending) {
          _showPendingModal(member);
        } else {
          _showSetRelationshipSheet(member);
        }
      },
      child: Container(
        width: cardWidth,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPending
                ? const Color(0xFFFCD34D)
                : (isYou
                      ? const Color(0xFF4A3AFF).withValues(alpha: 0.5)
                      : const Color(0xFFE5E7EB)),
            width: isYou || isPending ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isPending
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                  : (isYou
                        ? const Color(0xFF4A3AFF).withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.03)),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    shape: BoxShape.circle,
                  ),
                  child: avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                initials,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            initials,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                ),
                if (isYou)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A3AFF),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 8,
                      ),
                    ),
                  ),
                if (isPending)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.access_time_rounded,
                        color: Colors.white,
                        size: 8,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 5),

            // Name
            Text(
              firstName,
              style: GoogleFonts.outfit(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 1),

            // Relationship Label
            Text(
              relationshipLabel,
              style: GoogleFonts.outfit(
                fontSize: 8.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 1),

            // Status label
            Text(
              isPending ? 'Pending' : (isYou ? 'You' : 'Connected'),
              style: GoogleFonts.outfit(
                fontSize: 7.5,
                fontWeight: FontWeight.w400,
                color: isPending
                    ? const Color(0xFFD97706)
                    : const Color(0xFF9CA3AF),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Branch Connector Lines between Tiers ──────────────────────────────────
  Widget _buildBranchConnector(FamilyTier tier) {
    return SizedBox(
      height: 24,
      width: 160,
      child: CustomPaint(painter: _StemBranchPainter()),
    );
  }

  // ── Pending Approval Sheet ────────────────────────────────────────────────
  void _showPendingModal(FamilyMemberEntity member) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Color(0xFFF59E0B),
                  size: 26,
                ),
                const SizedBox(width: 10),
                Text(
                  'Review Join Request',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${member.user?.name ?? "Family Member"} accepted your invitation to join as ${member.relationship}. Approve to connect them into your Family Tree.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      widget.onDeclinePending?.call(member.id);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Decline',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      widget.onApprovePending?.call(member.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Approve',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick Set Relationship Sheet ──────────────────────────────────────────
  void _showSetRelationshipSheet(FamilyMemberEntity member) {
    const options = [
      'Father',
      'Mother',
      'Paternal Grandfather',
      'Paternal Grandmother',
      'Maternal Grandfather',
      'Maternal Grandmother',
      'Brother',
      'Sister',
      'Son',
      'Daughter',
      'Spouse',
      'Husband',
      'Wife',
      'Partner',
      'Uncle',
      'Aunt',
      'Cousin',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
                  'Set Relation for ${member.user?.name?.split(" ").first ?? "Member"}',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Choose their exact relationship to place them into the correct generation tier:',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                itemCount: options.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                itemBuilder: (context, idx) {
                  final rel = options[idx];
                  final isSelected =
                      member.relationship.toLowerCase() == rel.toLowerCase();
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      rel,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF4A3AFF)
                            : const Color(0xFF1F2937),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF4A3AFF),
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _customRelationships[member.id] = rel;
                      });
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'F';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Widget _buildPendingBanner(int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.admin_panel_settings_rounded,
            color: Color(0xFFD97706),
            size: 26,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Member Join Request Waiting',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap pending member cards to approve and link them into your tree.',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painter for Branch Connector Lines
// ─────────────────────────────────────────────────────────────────────────────
class _StemBranchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final double w = size.width;
    final double h = size.height;

    // Center stem down
    canvas.drawLine(Offset(w * 0.5, 0), Offset(w * 0.5, h * 0.5), paint);
    // Horizontal bridge
    canvas.drawLine(
      Offset(w * 0.25, h * 0.5),
      Offset(w * 0.75, h * 0.5),
      paint,
    );
    // Left & Right drops
    canvas.drawLine(Offset(w * 0.25, h * 0.5), Offset(w * 0.25, h), paint);
    canvas.drawLine(Offset(w * 0.75, h * 0.5), Offset(w * 0.75, h), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
