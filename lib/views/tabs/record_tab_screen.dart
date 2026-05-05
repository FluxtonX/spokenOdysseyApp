import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/memory_service.dart';
import '../../theme/theme.dart';
import '../memories/record_story_screen.dart';

class RecordTabScreen extends StatefulWidget {
  const RecordTabScreen({super.key});

  @override
  State<RecordTabScreen> createState() => _RecordTabScreenState();
}

class _RecordTabScreenState extends State<RecordTabScreen>
    with SingleTickerProviderStateMixin {
  final MemoryService _memoryService = MemoryService();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _lastDraft;
  int _publishedCount = 0;
  int _draftCount = 0;

  late final AnimationController _animController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
    _loadRecordHub();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadRecordHub({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final memories = await _memoryService.fetchMemories(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;

      final drafts = memories.where((memory) => memory['status'] == 'draft');
      final published = memories.where(
        (memory) => memory['status'] == 'published',
      );

      setState(() {
        _lastDraft = drafts.isNotEmpty ? drafts.first : null;
        _draftCount = drafts.length;
        _publishedCount = published.length;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _openComposer({
    RecordStoryFormat? initialFormat,
    Map<String, dynamic>? initialDraft,
  }) async {
    await Get.to(
      () => RecordStoryScreen(
        initialFormat: initialFormat,
        initialDraft: initialDraft,
      ),
    );
    await _loadRecordHub();
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.adaptiveScaffoldBg,
      body: RefreshIndicator(
        onRefresh: () => _loadRecordHub(forceRefresh: true),
        color: const Color(0xFF5544FF),
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (canPop) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Get.back(),
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.adaptiveCardBg,
                              foregroundColor: AppTheme.adaptiveTextPrimary,
                              side: BorderSide(color: AppTheme.adaptiveBorder),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                size: 18),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildHero(isDark),
                      const SizedBox(height: 28),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 64),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF5544FF),
                            ),
                          ),
                        )
                      else ...[
                        _buildStatsRow(isDark),
                        const SizedBox(height: 28),
                        _buildDraftCard(isDark),
                        const SizedBox(height: 36),
                        _buildSectionHeader(
                          title: 'Choose your format',
                          subtitle:
                              'Pick the shape that fits the memory, not the other way around.',
                          icon: Icons.dashboard_customize_outlined,
                          color: const Color(0xFF5ABA82),
                        ),
                        const SizedBox(height: 18),
                        _buildFormatGrid(isDark),
                        const SizedBox(height: 36),
                        _buildSectionHeader(
                          title: 'Keep the flow simple',
                          subtitle:
                              'Capture first, refine later, and let albums organize the archive once the memory is safe.',
                          icon: Icons.auto_awesome_outlined,
                          color: const Color(0xFFE2923A),
                        ),
                        const SizedBox(height: 18),
                        _buildWorkflowCard(isDark),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1D2740),
                  const Color(0xFF332F85),
                  const Color(0xFF7A4A20),
                ]
              : [
                  const Color(0xFF2B3A55),
                  const Color(0xFF4F46E5),
                  const Color(0xFFE2923A),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: isDark ? 0.2 : 0.25),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.mic_none_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Record',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Capture the memory while it still feels honest.',
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Voice, text, photo, or video. Start with the format that feels most natural and let the archive grow from there.',
            style: GoogleFonts.outfit(
              fontSize: 15,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _openComposer(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2F2E76),
                elevation: 0,
                minimumSize: const Size(0, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Start Recording',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Drafts waiting',
            value: '$_draftCount',
            accent: const Color(0xFF5544FF),
            icon: Icons.edit_note_rounded,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            label: 'Published',
            value: '$_publishedCount',
            accent: const Color(0xFF5ABA82),
            icon: Icons.check_circle_outline_rounded,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color accent,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.adaptiveCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.adaptiveBorder),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black12)
                .withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppTheme.adaptiveTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.adaptiveTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftCard(bool isDark) {
    if (_error != null) {
      return _buildErrorCard(isDark);
    }

    if (_lastDraft == null) {
      return _buildEmptyDraftCard(isDark);
    }

    final draft = _lastDraft!;
    final accent = const Color(0xFF5544FF);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Continue last draft',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                draft['icon'] as IconData? ?? Icons.edit_note_rounded,
                color: accent,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            draft['title']?.toString().isNotEmpty == true
                ? draft['title'].toString()
                : 'Untitled draft',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.adaptiveTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            draft['description']?.toString().isNotEmpty == true
                ? draft['description'].toString()
                : 'This draft is ready to pick up from where you left it.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 14.5,
              height: 1.5,
              color: AppTheme.adaptiveTextSecondary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _openComposer(
                initialDraft: draft,
                initialFormat: _formatFromType(draft['type']?.toString()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Resume Draft',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.adaptiveCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.red[400]),
              const SizedBox(width: 10),
              Text(
                'Could not load drafts',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.adaptiveTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _error!,
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.5,
              color: AppTheme.adaptiveTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDraftCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.adaptiveCardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.adaptiveBorder),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black12)
                .withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF5544FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.post_add_rounded,
              color: Color(0xFF5544FF),
              size: 28,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No drafts in progress',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.adaptiveTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Unfinished memories will live here.',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    height: 1.5,
                    color: AppTheme.adaptiveTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.adaptiveTextPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: GoogleFonts.outfit(
            fontSize: 14.5,
            height: 1.55,
            color: AppTheme.adaptiveTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFormatGrid(bool isDark) {
    final formats = RecordStoryFormat.values;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 720 ? 4 : 2;
        final mainAxisExtent = constraints.maxWidth >= 720 ? 210.0 : 190.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: formats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: mainAxisExtent,
          ),
          itemBuilder: (context, index) {
            final format = formats[index];
            return _RecordFormatCard(
              format: format,
              isDark: isDark,
              onTap: () => _openComposer(initialFormat: format),
            );
          },
        );
      },
    );
  }

  Widget _buildWorkflowCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.adaptiveCardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.adaptiveBorder),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black12)
                .withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWorkflowStep(
            '1',
            'Capture',
            'Start with voice, text, photo, or video.',
            isLast: false,
          ),
          _buildWorkflowStep(
            '2',
            'Shape',
            'Add title, mood, tags, and privacy once the memory is safe.',
            isLast: false,
          ),
          _buildWorkflowStep(
            '3',
            'Place',
            'Save as draft or publish it into the right album.',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowStep(String index, String title, String subtitle,
      {required bool isLast}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2923A).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  index,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE2923A),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.adaptiveBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.adaptiveTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      height: 1.5,
                      color: AppTheme.adaptiveTextSecondary,
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

  RecordStoryFormat? _formatFromType(String? rawType) {
    final type = rawType?.toLowerCase() ?? '';
    if (type.contains('voice')) return RecordStoryFormat.voice;
    if (type.contains('photo')) return RecordStoryFormat.photoText;
    if (type.contains('video')) return RecordStoryFormat.video;
    if (type.contains('text')) return RecordStoryFormat.text;
    return null;
  }
}

class _RecordFormatCard extends StatelessWidget {
  const _RecordFormatCard({required this.format, required this.isDark, required this.onTap});

  final RecordStoryFormat format;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = format.accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.adaptiveCardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.adaptiveBorder),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : Colors.black12)
                    .withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    format.icon,
                    color: accent,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  format.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.adaptiveTextPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    format.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      height: 1.45,
                      color: AppTheme.adaptiveTextSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Compose',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: accent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
