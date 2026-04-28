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

class _RecordTabScreenState extends State<RecordTabScreen> {
  final MemoryService _memoryService = MemoryService();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _lastDraft;
  int _publishedCount = 0;
  int _draftCount = 0;

  @override
  void initState() {
    super.initState();
    _loadRecordHub();
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () => _loadRecordHub(forceRefresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            if (canPop) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Get.back(),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.adaptiveCardBg,
                    foregroundColor: AppTheme.adaptiveTextPrimary,
                    side: BorderSide(color: AppTheme.adaptiveBorder),
                  ),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _buildHero(),
            const SizedBox(height: 20),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _buildStatsRow(),
              const SizedBox(height: 20),
              _buildDraftCard(),
              const SizedBox(height: 24),
              _buildSectionHeader(
                title: 'Choose your format',
                subtitle:
                    'Pick the shape that fits the memory, not the other way around.',
              ),
              const SizedBox(height: 14),
              _buildFormatGrid(),
              const SizedBox(height: 24),
              _buildSectionHeader(
                title: 'Keep the flow simple',
                subtitle:
                    'Capture first, refine later, and let albums organize the archive once the memory is safe.',
              ),
              const SizedBox(height: 14),
              _buildWorkflowCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D2740), Color(0xFF4F46E5), Color(0xFFE2923A)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Record',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Capture the memory while it still feels honest.',
            style: GoogleFonts.playfairDisplay(
              fontSize: 29,
              height: 1.08,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Voice, text, photo, or video. Start with the format that feels most natural and let the archive grow from there.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.55,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _openComposer(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2F2E76),
              minimumSize: const Size(0, 50),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              'Start Recording',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Drafts waiting',
            value: '$_draftCount',
            accent: const Color(0xFF5544FF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: 'Published memories',
            value: '$_publishedCount',
            accent: const Color(0xFF5ABA82),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.adaptiveCardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.adaptiveBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.adaptiveTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftCard() {
    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.adaptiveCardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.adaptiveBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Could not load your draft state',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.adaptiveTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: GoogleFonts.outfit(
                fontSize: 13,
                height: 1.5,
                color: AppTheme.adaptiveTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_lastDraft == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.adaptiveCardBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.adaptiveBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No draft in progress',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF5544FF),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Start fresh from here and your unfinished memory will live in this tab until you are ready to finish it.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                height: 1.55,
                color: AppTheme.adaptiveTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final draft = _lastDraft!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.adaptiveCardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.adaptiveBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF5544FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Continue last draft',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5544FF),
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                draft['icon'] as IconData? ?? Icons.edit_note_rounded,
                color: const Color(0xFF5544FF),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 14),
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
              fontSize: 14,
              height: 1.55,
              color: AppTheme.adaptiveTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _openComposer(
              initialDraft: draft,
              initialFormat: _formatFromType(draft['type']?.toString()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5544FF),
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            child: Text(
              'Resume Draft',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.adaptiveTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.outfit(
            fontSize: 14,
            height: 1.55,
            color: AppTheme.adaptiveTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFormatGrid() {
    final formats = RecordStoryFormat.values;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 980
            ? 4
            : constraints.maxWidth >= 720
            ? 3
            : constraints.maxWidth >= 440
            ? 2
            : 1;
        final mainAxisExtent = constraints.maxWidth >= 720 ? 208.0 : 182.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: formats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: mainAxisExtent,
          ),
          itemBuilder: (context, index) {
            final format = formats[index];
            return _RecordFormatCard(
              format: format,
              onTap: () => _openComposer(initialFormat: format),
            );
          },
        );
      },
    );
  }

  Widget _buildWorkflowCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.adaptiveCardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.adaptiveBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWorkflowStep(
            '1',
            'Capture',
            'Start with voice, text, photo, or video.',
          ),
          const SizedBox(height: 12),
          _buildWorkflowStep(
            '2',
            'Shape',
            'Add title, mood, tags, and privacy once the memory is safe.',
          ),
          const SizedBox(height: 12),
          _buildWorkflowStep(
            '3',
            'Place',
            'Save as draft or publish it into the right album.',
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowStep(String index, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF5544FF).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            index,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF5544FF),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.adaptiveTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
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
  const _RecordFormatCard({required this.format, required this.onTap});

  final RecordStoryFormat format;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = format.accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.adaptiveCardBg,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppTheme.adaptiveBorder),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final ultraCompact =
                  constraints.maxWidth < 132 || constraints.maxHeight < 176;
              final compact =
                  ultraCompact ||
                  constraints.maxWidth < 156 ||
                  constraints.maxHeight < 188;

              return Padding(
                padding: EdgeInsets.all(
                  ultraCompact ? 12 : (compact ? 14 : 18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: ultraCompact ? 38 : (compact ? 44 : 52),
                      height: ultraCompact ? 38 : (compact ? 44 : 52),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          ultraCompact ? 12 : (compact ? 14 : 18),
                        ),
                      ),
                      child: Icon(
                        format.icon,
                        color: accent,
                        size: ultraCompact ? 19 : (compact ? 22 : 26),
                      ),
                    ),
                    SizedBox(height: ultraCompact ? 10 : (compact ? 12 : 18)),
                    Text(
                      format.label,
                      maxLines: ultraCompact ? 1 : (compact ? 2 : 2),
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: ultraCompact ? 16 : (compact ? 18 : 22),
                        fontWeight: FontWeight.w700,
                        color: AppTheme.adaptiveTextPrimary,
                        height: 1.05,
                      ),
                    ),
                    SizedBox(height: ultraCompact ? 4 : (compact ? 6 : 8)),
                    Expanded(
                      child: Text(
                        format.description,
                        maxLines: ultraCompact ? 2 : (compact ? 2 : 3),
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: ultraCompact ? 10.5 : (compact ? 11.5 : 13),
                          height: ultraCompact ? 1.3 : 1.4,
                          color: AppTheme.adaptiveTextSecondary,
                        ),
                      ),
                    ),
                    SizedBox(height: ultraCompact ? 8 : (compact ? 10 : 14)),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ultraCompact ? 'Compose' : 'Open composer',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: ultraCompact ? 10 : (compact ? 11 : 12),
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: ultraCompact ? 14 : (compact ? 16 : 18),
                          color: accent,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
