import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/theme.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final TextEditingController _inviteEmailController = TextEditingController();

  final List<String> _albumChoices = const [
    'Letters & Keepsakes',
    'Family Reunion 2023',
    'Kitchen Stories',
    'Childhood Memories',
    'Legacy Archive',
  ];

  late final List<_SharedMemory> _sharedMemories = [
    _SharedMemory(
      id: 'm1',
      title: 'Family Reunion 2023',
      authorName: 'Emily Mitchell',
      dateLabel: 'July 15, 2023',
      snippet:
          'Three generations under one roof. Laughter echoing through the halls like music and every table full of old stories.',
      sharedWith: 'Full Family Circle',
    ),
    _SharedMemory(
      id: 'm2',
      title: 'Teaching Dad to Use His Phone',
      authorName: 'Sarah Mitchell',
      dateLabel: 'November 3, 2021',
      snippet:
          'Patience tested. Love strengthened. Technology conquered, at least for one afternoon.',
      sharedWith: 'Selected Albums',
    ),
    _SharedMemory(
      id: 'm3',
      title: 'Mom\'s Recipe Book',
      authorName: 'Robert Mitchell',
      dateLabel: 'December 25, 2023',
      snippet:
          'Found her handwritten notes in the margins. Each stain tells a story of meals shared and late-night kitchen lessons.',
      sharedWith: 'Full Family Circle',
    ),
    _SharedMemory(
      id: 'm4',
      title: 'First School Performance',
      authorName: 'Sophie Mitchell',
      dateLabel: 'March 8, 2024',
      snippet:
          'A tiny stage, shaky hands, then sudden confidence. The whole family stood up before the final note had ended.',
      sharedWith: 'Selected Albums',
    ),
  ];

  late List<_FamilyMember> _members = [
    _FamilyMember(
      id: 'rm',
      name: 'Robert Mitchell',
      email: 'robert@mitchell.family',
      relationship: 'Father',
      role: _FamilyRole.legacyCustodian,
      access: _FamilyAccess.fullCircle,
      selectedAlbums: const [],
      sharedCount: 14,
      joinedLabel: 'Joined January 2024',
      initials: 'RM',
      avatarColor: const Color(0xFFE0E7FF),
      status: _MemberStatus.active,
    ),
    _FamilyMember(
      id: 'em',
      name: 'Emily Mitchell',
      email: 'emily@mitchell.family',
      relationship: 'Mother',
      role: _FamilyRole.contributor,
      access: _FamilyAccess.fullCircle,
      selectedAlbums: const [],
      sharedCount: 42,
      joinedLabel: 'Joined January 2024',
      initials: 'EM',
      avatarColor: const Color(0xFFFFE4E6),
      status: _MemberStatus.active,
    ),
    _FamilyMember(
      id: 'am',
      name: 'Alex Mitchell',
      email: 'alex@mitchell.family',
      relationship: 'Sibling',
      role: _FamilyRole.contributor,
      access: _FamilyAccess.selectedAlbums,
      selectedAlbums: const ['Family Reunion 2023', 'Letters & Keepsakes'],
      sharedCount: 28,
      joinedLabel: 'Joined March 2024',
      initials: 'AM',
      avatarColor: const Color(0xFFFEF3C7),
      status: _MemberStatus.active,
    ),
    _FamilyMember(
      id: 'sm',
      name: 'Sophie Mitchell',
      email: 'sophie@mitchell.family',
      relationship: 'Daughter',
      role: _FamilyRole.viewer,
      access: _FamilyAccess.privateOnly,
      selectedAlbums: const [],
      sharedCount: 15,
      joinedLabel: 'Invited June 2024',
      initials: 'SM',
      avatarColor: const Color(0xFFF3E8FF),
      status: _MemberStatus.pending,
    ),
  ];

  _LegacyConfig _legacyConfig = const _LegacyConfig(
    trusteeMemberId: 'rm',
    activationLabel: 'After death verified',
    notificationsEnabled: true,
  );

  String _memberFilter = 'All';

  @override
  void dispose() {
    _inviteEmailController.dispose();
    super.dispose();
  }

  List<_FamilyMember> get _filteredMembers {
    switch (_memberFilter) {
      case 'Contributors':
        return _members
            .where((member) => member.role == _FamilyRole.contributor)
            .toList();
      case 'Custodians':
        return _members
            .where((member) => member.role == _FamilyRole.legacyCustodian)
            .toList();
      case 'Pending':
        return _members
            .where((member) => member.status == _MemberStatus.pending)
            .toList();
      default:
        return _members;
    }
  }

  _FamilyMember? get _trustedCustodian {
    try {
      return _members.firstWhere(
        (member) => member.id == _legacyConfig.trusteeMemberId,
      );
    } catch (_) {
      return null;
    }
  }

  int get _sharedMemoryCount => _sharedMemories.length;

  int get _contributorCount =>
      _members.where((member) => member.role == _FamilyRole.contributor).length;

  int get _custodianCount => _members
      .where((member) => member.role == _FamilyRole.legacyCustodian)
      .length;

  Future<void> _openInviteSheet({String? initialEmail}) async {
    final createdMember = await showModalBottomSheet<_FamilyMember>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AddFamilyMemberSheet(
          initialEmail: initialEmail,
          albumChoices: _albumChoices,
        );
      },
    );

    if (createdMember == null || !mounted) {
      return;
    }

    setState(() {
      _members = [createdMember, ..._members];
      _inviteEmailController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Invitation prepared for ${createdMember.name}.',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openManageAccessSheet(_FamilyMember member) async {
    final updatedMember = await showModalBottomSheet<_FamilyMember>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ManageAccessSheet(member: member, albumChoices: _albumChoices);
      },
    );

    if (updatedMember == null || !mounted) {
      return;
    }

    setState(() {
      _members = _members
          .map((item) => item.id == updatedMember.id ? updatedMember : item)
          .toList();

      final trusteeStillExists = _members.any(
        (item) => item.id == _legacyConfig.trusteeMemberId,
      );
      if (!trusteeStillExists && _members.isNotEmpty) {
        _legacyConfig = _legacyConfig.copyWith(
          trusteeMemberId: _members.first.id,
        );
      }
    });
  }

  Future<void> _openLegacySettingsSheet() async {
    final updatedConfig = await showModalBottomSheet<_LegacyConfig>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _LegacySettingsSheet(
          members: _members,
          initialConfig: _legacyConfig,
        );
      },
    );

    if (updatedConfig == null || !mounted) {
      return;
    }

    setState(() {
      _legacyConfig = updatedConfig;
    });
  }

  Future<void> _openSharedMemoriesSheet(_FamilyMember member) async {
    final relevantMemories = _sharedMemories
        .where(
          (memory) =>
              memory.authorName == member.name ||
              member.access == _FamilyAccess.fullCircle,
        )
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SharedMemoriesSheet(member: member, memories: relevantMemories);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildOverviewCard(),
              const SizedBox(height: 24),
              _buildInviteBanner(),
              const SizedBox(height: 30),
              _buildConnectedFamilySection(),
              const SizedBox(height: 30),
              _buildSharedMemoriesSection(),
              const SizedBox(height: 30),
              _buildLegacyCard(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'family_fab',
        backgroundColor: AppTheme.floatingActionButton,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        onPressed: _openInviteSheet,
        child: const Icon(Icons.person_add_alt_1_outlined),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Family Circles',
          style: GoogleFonts.playfairDisplay(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: AppTheme.adaptiveTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Invite family, define access, and shape exactly how your shared legacy should be experienced.',
          style: GoogleFonts.outfit(
            fontSize: 15,
            height: 1.6,
            color: AppTheme.adaptiveTextSecondary,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildTopStat('Members', '${_members.length}'),
            _buildTopStat('Contributors', '$_contributorCount'),
            _buildTopStat('Memories Shared', '$_sharedMemoryCount'),
          ],
        ),
      ],
    );
  }

  Widget _buildTopStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.adaptiveSoftSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.adaptiveBorder),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$value ',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.adaptiveTextPrimary,
              ),
            ),
            TextSpan(
              text: label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.adaptiveTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    final custodianName = _trustedCustodian?.name ?? 'Not selected';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.adaptiveCardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.adaptiveBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mitchell Family Circle',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.adaptiveTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_members.length} members • $_custodianCount custodians • ${_sharedMemories.length} shared memories',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppTheme.adaptiveTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildIconAction(
                icon: Icons.shield_outlined,
                label: 'Legacy',
                onTap: _openLegacySettingsSheet,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildOverviewPill(
                icon: Icons.key_outlined,
                title: 'Trusted custodian',
                value: custodianName,
                accent: const Color(0xFF22C55E),
              ),
              _buildOverviewPill(
                icon: Icons.lock_clock_outlined,
                title: 'Activation',
                value: _legacyConfig.activationLabel,
                accent: const Color(0xFF5544FF),
              ),
              _buildOverviewPill(
                icon: Icons.folder_shared_outlined,
                title: 'Shared albums',
                value:
                    '${_members.where((m) => m.access != _FamilyAccess.privateOnly).length} members connected',
                accent: const Color(0xFFE2923A),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'Invite Member',
                  filled: true,
                  onTap: _openInviteSheet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  label: 'Edit Legacy',
                  filled: false,
                  onTap: _openLegacySettingsSheet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.adaptiveSoftSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF5544FF)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.adaptiveTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewPill({
    required IconData icon,
    required String title,
    required String value,
    required Color accent,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.adaptiveSoftSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.adaptiveTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.adaptiveTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: filled
              ? const Color(0xFF5544FF)
              : AppTheme.adaptiveSoftSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: filled ? const Color(0xFF5544FF) : AppTheme.adaptiveBorder,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: filled ? Colors.white : AppTheme.adaptiveTextPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildInviteBanner() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF5544FF).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF5544FF).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF5544FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mail_outline,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invite Family Members',
                      style: GoogleFonts.outfit(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.adaptiveTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Send a thoughtful invite, assign their role, and decide what they can access from day one.',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        height: 1.5,
                        color: AppTheme.adaptiveTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.adaptiveCardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.adaptiveBorder),
                  ),
                  child: TextField(
                    controller: _inviteEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Enter email address...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintStyle: GoogleFonts.outfit(
                        color: AppTheme.adaptiveTextHint,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _openInviteSheet(
                  initialEmail: _inviteEmailController.text.trim(),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5544FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
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

  Widget _buildConnectedFamilySection() {
    final filters = ['All', 'Contributors', 'Custodians', 'Pending'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Connected Family',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.adaptiveTextPrimary,
                ),
              ),
            ),
            Text(
              '${_filteredMembers.length} shown',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.adaptiveTextSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: filters.map((filter) {
            final selected = _memberFilter == filter;
            return GestureDetector(
              onTap: () => setState(() => _memberFilter = filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF5544FF)
                      : AppTheme.adaptiveSoftSurface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF5544FF)
                        : AppTheme.adaptiveBorder,
                  ),
                ),
                child: Text(
                  filter,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? Colors.white
                        : AppTheme.adaptiveTextPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        ..._filteredMembers.map(_buildMemberCard),
      ],
    );
  }

  Widget _buildMemberCard(_FamilyMember member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.adaptiveCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.adaptiveBorder),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: member.avatarColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  member.initials,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.adaptiveTextPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.adaptiveTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${member.relationship} • ${member.joinedLabel}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppTheme.adaptiveTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildMemberBadge(
                          member.role.label,
                          member.role.badgeColor,
                          member.role.badgeTextColor,
                        ),
                        _buildMemberBadge(
                          member.access.label,
                          member.access.badgeColor,
                          member.access.badgeTextColor,
                        ),
                        if (member.status == _MemberStatus.pending)
                          _buildMemberBadge(
                            'Pending invite',
                            const Color(0xFFFFF5D9),
                            const Color(0xFF9A6700),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildMemberStat(
                  icon: Icons.favorite_outline,
                  label: '${member.sharedCount} shared',
                ),
              ),
              Expanded(
                child: _buildMemberStat(
                  icon: Icons.collections_bookmark_outlined,
                  label: member.access == _FamilyAccess.selectedAlbums
                      ? '${member.selectedAlbums.length} albums'
                      : member.access.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openSharedMemoriesSheet(member),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'View Shared',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.adaptiveTextPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _openManageAccessSheet(member),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.adaptiveSoftSurface,
                    foregroundColor: AppTheme.adaptiveTextPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Manage Access',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
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

  Widget _buildMemberBadge(String label, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }

  Widget _buildMemberStat({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.adaptiveTextHint),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.adaptiveTextSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSharedMemoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Shared Memories',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.adaptiveTextPrimary,
                ),
              ),
            ),
            Text(
              '${_sharedMemories.length} stories',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.adaptiveTextSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        ..._sharedMemories.take(3).map(_buildMemoryCard),
      ],
    );
  }

  Widget _buildMemoryCard(_SharedMemory memory) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.adaptiveCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.adaptiveBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  memory.title,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.adaptiveTextPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF5544FF).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  memory.sharedWith,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5544FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'by ${memory.authorName} • ${memory.dateLabel}',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.adaptiveTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            memory.snippet,
            style: GoogleFonts.outfit(
              fontSize: 13,
              height: 1.55,
              color: AppTheme.adaptiveTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegacyCard() {
    final custodianName = _trustedCustodian?.name ?? 'Not selected';

    return GestureDetector(
      onTap: _openLegacySettingsSheet,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2532),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E2532).withValues(alpha: 0.24),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.key_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Legacy Access Settings',
              style: GoogleFonts.playfairDisplay(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Choose who becomes the trusted custodian, define the trigger condition, and keep your archive aligned with your intent.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                height: 1.6,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 24),
            _buildLegacyRow('Trusted custodian', custodianName),
            const SizedBox(height: 14),
            _buildLegacyRow('Activation', _legacyConfig.activationLabel),
            const SizedBox(height: 14),
            _buildLegacyRow(
              'Notifications',
              _legacyConfig.notificationsEnabled ? 'Enabled' : 'Disabled',
            ),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                'Configure Now',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E2532),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegacyRow(String title, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.62),
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _AddFamilyMemberSheet extends StatefulWidget {
  const _AddFamilyMemberSheet({required this.albumChoices, this.initialEmail});

  final String? initialEmail;
  final List<String> albumChoices;

  @override
  State<_AddFamilyMemberSheet> createState() => _AddFamilyMemberSheetState();
}

class _AddFamilyMemberSheetState extends State<_AddFamilyMemberSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  String _relationship = 'Sibling';
  _FamilyRole _role = _FamilyRole.viewer;
  _FamilyAccess _access = _FamilyAccess.fullCircle;
  final Set<String> _selectedAlbums = <String>{};

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final initials = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    final palette = [
      const Color(0xFFE0E7FF),
      const Color(0xFFFFE4E6),
      const Color(0xFFF3E8FF),
      const Color(0xFFFEF3C7),
      const Color(0xFFD1FAE5),
    ];

    Navigator.of(context).pop(
      _FamilyMember(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: _emailController.text.trim(),
        relationship: _relationship,
        role: _role,
        access: _access,
        selectedAlbums: _selectedAlbums.toList(),
        sharedCount: 0,
        joinedLabel: 'Invited today',
        initials: initials.isEmpty ? 'FM' : initials,
        avatarColor: palette[name.length % palette.length],
        status: _MemberStatus.pending,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetShell(
      title: 'Add Family Member',
      subtitle:
          'Invite someone into your family circle, choose their role, and decide what they can access.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Full Name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
              decoration: const InputDecoration(
                hintText: 'e.g., Emma Mitchell',
              ),
            ),
            const SizedBox(height: 18),
            _buildLabel('Email Address'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final text = value?.trim() ?? '';
                if (!text.contains('@') || !text.contains('.')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
              decoration: const InputDecoration(hintText: 'their@email.com'),
            ),
            const SizedBox(height: 18),
            _buildLabel('Relationship'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children:
                  [
                    'Parent',
                    'Child',
                    'Sibling',
                    'Grandparent',
                    'Cousin',
                    'Friend',
                  ].map((item) {
                    return _SelectionChip(
                      label: item,
                      selected: _relationship == item,
                      onTap: () => setState(() => _relationship = item),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 20),
            _buildLabel('Role'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _FamilyRole.values.map((role) {
                return _SelectionChip(
                  label: role.label,
                  selected: _role == role,
                  onTap: () => setState(() => _role = role),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _buildLabel('Access'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _FamilyAccess.values.map((access) {
                return _SelectionChip(
                  label: access.label,
                  selected: _access == access,
                  onTap: () => setState(() => _access = access),
                );
              }).toList(),
            ),
            if (_access == _FamilyAccess.selectedAlbums) ...[
              const SizedBox(height: 18),
              Text(
                'Choose albums',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.adaptiveTextPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: widget.albumChoices.map((album) {
                  final selected = _selectedAlbums.contains(album);
                  return _SelectionChip(
                    label: album,
                    selected: selected,
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selectedAlbums.remove(album);
                        } else {
                          _selectedAlbums.add(album);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5544FF),
                    ),
                    child: const Text('Send Invite'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.adaptiveTextPrimary,
      ),
    );
  }
}

class _ManageAccessSheet extends StatefulWidget {
  const _ManageAccessSheet({required this.member, required this.albumChoices});

  final _FamilyMember member;
  final List<String> albumChoices;

  @override
  State<_ManageAccessSheet> createState() => _ManageAccessSheetState();
}

class _ManageAccessSheetState extends State<_ManageAccessSheet> {
  late _FamilyRole _role;
  late _FamilyAccess _access;
  late Set<String> _selectedAlbums;

  @override
  void initState() {
    super.initState();
    _role = widget.member.role;
    _access = widget.member.access;
    _selectedAlbums = widget.member.selectedAlbums.toSet();
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetShell(
      title: 'Manage Access',
      subtitle:
          'Refine how ${widget.member.name} participates in the family circle.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.member.name,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.adaptiveTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.member.email,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppTheme.adaptiveTextSecondary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Role',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.adaptiveTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _FamilyRole.values.map((role) {
              return _SelectionChip(
                label: role.label,
                selected: _role == role,
                onTap: () => setState(() => _role = role),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Text(
            'Access',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.adaptiveTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _FamilyAccess.values.map((access) {
              return _SelectionChip(
                label: access.label,
                selected: _access == access,
                onTap: () => setState(() => _access = access),
              );
            }).toList(),
          ),
          if (_access == _FamilyAccess.selectedAlbums) ...[
            const SizedBox(height: 18),
            Text(
              'Album permissions',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.adaptiveTextPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: widget.albumChoices.map((album) {
                final selected = _selectedAlbums.contains(album);
                return _SelectionChip(
                  label: album,
                  selected: selected,
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedAlbums.remove(album);
                      } else {
                        _selectedAlbums.add(album);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      widget.member.copyWith(
                        role: _role,
                        access: _access,
                        selectedAlbums: _selectedAlbums.toList(),
                        status: _MemberStatus.active,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5544FF),
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegacySettingsSheet extends StatefulWidget {
  const _LegacySettingsSheet({
    required this.members,
    required this.initialConfig,
  });

  final List<_FamilyMember> members;
  final _LegacyConfig initialConfig;

  @override
  State<_LegacySettingsSheet> createState() => _LegacySettingsSheetState();
}

class _LegacySettingsSheetState extends State<_LegacySettingsSheet> {
  late String _selectedTrusteeId;
  late String _activationLabel;
  late bool _notificationsEnabled;

  @override
  void initState() {
    super.initState();
    _selectedTrusteeId = widget.initialConfig.trusteeMemberId;
    _activationLabel = widget.initialConfig.activationLabel;
    _notificationsEnabled = widget.initialConfig.notificationsEnabled;
  }

  @override
  Widget build(BuildContext context) {
    const activationOptions = [
      'After death verified',
      'Extended inactivity',
      'Manual unlock by trustee',
    ];

    return _BottomSheetShell(
      title: 'Legacy Access Settings',
      subtitle:
          'Choose a trusted custodian and define the rule that activates archive access.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trusted custodian',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.adaptiveTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...widget.members.map((member) {
            final selected = _selectedTrusteeId == member.id;
            return GestureDetector(
              onTap: () => setState(() => _selectedTrusteeId = member.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.adaptiveCardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF5544FF)
                        : AppTheme.adaptiveBorder,
                    width: selected ? 1.4 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: member.avatarColor,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        member.initials,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.adaptiveTextPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.adaptiveTextPrimary,
                            ),
                          ),
                          Text(
                            '${member.relationship} • ${member.role.label}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppTheme.adaptiveTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle, color: Color(0xFF5544FF)),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          Text(
            'Activation condition',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.adaptiveTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: activationOptions.map((option) {
              return _SelectionChip(
                label: option,
                selected: _activationLabel == option,
                onTap: () => setState(() => _activationLabel = option),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.adaptiveSoftSurface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inactivity notifications',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.adaptiveTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Notify you if the archive remains inactive for 30 days.',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.adaptiveTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) =>
                      setState(() => _notificationsEnabled = value),
                  activeThumbColor: const Color(0xFF5544FF),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      _LegacyConfig(
                        trusteeMemberId: _selectedTrusteeId,
                        activationLabel: _activationLabel,
                        notificationsEnabled: _notificationsEnabled,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5544FF),
                  ),
                  child: const Text('Save Settings'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SharedMemoriesSheet extends StatelessWidget {
  const _SharedMemoriesSheet({required this.member, required this.memories});

  final _FamilyMember member;
  final List<_SharedMemory> memories;

  @override
  Widget build(BuildContext context) {
    return _BottomSheetShell(
      title: 'Shared With ${member.name}',
      subtitle:
          'A quick view of the memories currently visible to this family member.',
      child: memories.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.adaptiveSoftSurface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'No memories are shared with ${member.name} yet.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppTheme.adaptiveTextSecondary,
                ),
              ),
            )
          : Column(
              children: memories.map((memory) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.adaptiveCardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.adaptiveBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        memory.title,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.adaptiveTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${memory.authorName} • ${memory.dateLabel}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.adaptiveTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        memory.snippet,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          height: 1.55,
                          color: AppTheme.adaptiveTextPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _BottomSheetShell extends StatelessWidget {
  const _BottomSheetShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.adaptiveCardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.adaptiveBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.adaptiveTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            height: 1.55,
                            color: AppTheme.adaptiveTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.adaptiveSoftSurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: AppTheme.adaptiveTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionChip extends StatelessWidget {
  const _SelectionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF5544FF)
              : AppTheme.adaptiveSoftSurface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppTheme.adaptiveTextPrimary,
          ),
        ),
      ),
    );
  }
}

enum _FamilyRole {
  viewer('Viewer', Color(0xFFF1F5F9), Color(0xFF334155)),
  contributor('Contributor', Color(0xFFEEF2FF), Color(0xFF4338CA)),
  legacyCustodian('Legacy Custodian', Color(0xFFE7F7EE), Color(0xFF166534));

  const _FamilyRole(this.label, this.badgeColor, this.badgeTextColor);

  final String label;
  final Color badgeColor;
  final Color badgeTextColor;
}

enum _FamilyAccess {
  privateOnly('Private Only', Color(0xFFFFF5D9), Color(0xFF9A6700)),
  selectedAlbums('Selected Albums', Color(0xFFEBF8FF), Color(0xFF1D4ED8)),
  fullCircle('Full Family Circle', Color(0xFFF3E8FF), Color(0xFF7C3AED));

  const _FamilyAccess(this.label, this.badgeColor, this.badgeTextColor);

  final String label;
  final Color badgeColor;
  final Color badgeTextColor;
}

enum _MemberStatus { active, pending }

class _FamilyMember {
  const _FamilyMember({
    required this.id,
    required this.name,
    required this.email,
    required this.relationship,
    required this.role,
    required this.access,
    required this.selectedAlbums,
    required this.sharedCount,
    required this.joinedLabel,
    required this.initials,
    required this.avatarColor,
    required this.status,
  });

  final String id;
  final String name;
  final String email;
  final String relationship;
  final _FamilyRole role;
  final _FamilyAccess access;
  final List<String> selectedAlbums;
  final int sharedCount;
  final String joinedLabel;
  final String initials;
  final Color avatarColor;
  final _MemberStatus status;

  _FamilyMember copyWith({
    _FamilyRole? role,
    _FamilyAccess? access,
    List<String>? selectedAlbums,
    _MemberStatus? status,
  }) {
    return _FamilyMember(
      id: id,
      name: name,
      email: email,
      relationship: relationship,
      role: role ?? this.role,
      access: access ?? this.access,
      selectedAlbums: selectedAlbums ?? this.selectedAlbums,
      sharedCount: sharedCount,
      joinedLabel: joinedLabel,
      initials: initials,
      avatarColor: avatarColor,
      status: status ?? this.status,
    );
  }
}

class _SharedMemory {
  const _SharedMemory({
    required this.id,
    required this.title,
    required this.authorName,
    required this.dateLabel,
    required this.snippet,
    required this.sharedWith,
  });

  final String id;
  final String title;
  final String authorName;
  final String dateLabel;
  final String snippet;
  final String sharedWith;
}

class _LegacyConfig {
  const _LegacyConfig({
    required this.trusteeMemberId,
    required this.activationLabel,
    required this.notificationsEnabled,
  });

  final String trusteeMemberId;
  final String activationLabel;
  final bool notificationsEnabled;

  _LegacyConfig copyWith({
    String? trusteeMemberId,
    String? activationLabel,
    bool? notificationsEnabled,
  }) {
    return _LegacyConfig(
      trusteeMemberId: trusteeMemberId ?? this.trusteeMemberId,
      activationLabel: activationLabel ?? this.activationLabel,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
