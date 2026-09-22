import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/media_url_formatter.dart';
import '../cubits/insights_cubit.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InsightsCubit>(
      create: (_) => sl<InsightsCubit>()..loadInsights(),
      child: const _InsightsView(),
    );
  }
}

class _InsightsView extends StatelessWidget {
  const _InsightsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Archive Insights',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Refresh Insights',
            onPressed: () => context.read<InsightsCubit>().loadInsights(),
          ),
        ],
      ),
      body: BlocBuilder<InsightsCubit, InsightsState>(
        builder: (context, state) {
          if (state is InsightsLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Analyzing archive & generating insights...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is InsightsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load insights',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.read<InsightsCubit>().loadInsights(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is InsightsLoaded) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => context.read<InsightsCubit>().loadInsights(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroBanner(legacyScore: state.legacyScore),
                    const SizedBox(height: 20),
                    _StatsGrid(stats: state.stats),
                    const SizedBox(height: 24),
                    _LifeSummaryCard(summary: state.lifeSummary),
                    const SizedBox(height: 24),
                    _LifeThemesCard(themes: state.lifeThemes),
                    const SizedBox(height: 24),
                    _EmotionalLandscapeCard(
                      landscape: state.emotionalLandscape,
                    ),
                    if (state.wordCloud.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _WordCloudCard(words: state.wordCloud),
                    ],
                    if (state.peopleInArchive.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _PeopleInArchiveCard(people: state.peopleInArchive),
                    ],
                    if (state.insights.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _ActionableInsightsCard(insights: state.insights),
                    ],
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Hero Banner with Legacy Score ─────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final int legacyScore;

  const _HeroBanner({required this.legacyScore});

  String get _legacyTitle {
    if (legacyScore >= 80) return 'Living Legend';
    if (legacyScore >= 60) return 'Master Storyteller';
    if (legacyScore >= 40) return 'Archive Keeper';
    if (legacyScore >= 20) return 'Memory Chronicler';
    return 'Archive Pioneer';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A3AFF), Color(0xFF6E62FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A3AFF).withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.amberAccent,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'AI ANALYTICS',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Legacy Score',
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _legacyTitle,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (legacyScore / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.amberAccent,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 2.5,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$legacyScore',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    '/ 100',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
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
}

// ── Stats Grid ────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final totalMemories = stats['totalMemories']?.toString() ?? '0';
    final voiceHours = stats['voiceHours']?.toString() ?? '0.0h';
    final wordsWritten = stats['wordsWritten']?.toString() ?? '0';
    final milestones = stats['milestones']?.toString() ?? '0';
    final yearsCovered = stats['yearsCovered']?.toString() ?? '0';

    final items = [
      _StatItem(
        label: 'Total Memories',
        value: totalMemories,
        icon: Icons.mic_rounded,
        color: const Color(0xFF4A3AFF),
        bgColor: const Color(0xFFEFF0FF),
      ),
      _StatItem(
        label: 'Voice Hours',
        value: voiceHours,
        icon: Icons.access_time_filled_rounded,
        color: const Color(0xFF10B981),
        bgColor: const Color(0xFFE8FDF5),
      ),
      _StatItem(
        label: 'Words Written',
        value: wordsWritten,
        icon: Icons.edit_note_rounded,
        color: const Color(0xFFF59E0B),
        bgColor: const Color(0xFFFFF7E6),
      ),
      _StatItem(
        label: 'Milestones',
        value: milestones,
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFF8B5CF6),
        bgColor: const Color(0xFFF5F0FF),
      ),
      _StatItem(
        label: 'Years Covered',
        value: yearsCovered,
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF06B6D4),
        bgColor: const Color(0xFFECFEFF),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Archive Overview',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            final cardWidth = (MediaQuery.of(context).size.width - 44) / 2;
            return SizedBox(
              width: cardWidth,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFECEEF2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: item.bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: item.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.value,
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

// ── AI Life Narrative Card ───────────────────────────────────────────────────

class _LifeSummaryCard extends StatelessWidget {
  final String summary;

  const _LifeSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECEEF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
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
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF7C3AED),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Narrative Synthesis',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Distilled from your voice & memories',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF3F4F6)),
            ),
            child: Text(
              '“$summary”',
              style: GoogleFonts.newsreader(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                height: 1.5,
                color: const Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Life Themes Card ─────────────────────────────────────────────────────────

class _LifeThemesCard extends StatelessWidget {
  final List<Map<String, dynamic>> themes;

  const _LifeThemesCard({required this.themes});

  Color _parseColor(String? hex) {
    if (hex == null || !hex.startsWith('#')) return const Color(0xFF4A3AFF);
    final hexCode = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    if (themes.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECEEF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Core Life Themes',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Distribution of stories across pivotal dimensions',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ...themes.map((theme) {
            final name = theme['name'] as String? ?? 'Other';
            final value = (theme['value'] as num?)?.toInt() ?? 0;
            final color = _parseColor(theme['color'] as String?);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$value%',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (value / 100).clamp(0.0, 1.0),
                      backgroundColor: const Color(0xFFF3F4F6),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Emotional Landscape Card ─────────────────────────────────────────────────

class _EmotionalLandscapeCard extends StatelessWidget {
  final Map<String, dynamic> landscape;

  const _EmotionalLandscapeCard({required this.landscape});

  @override
  Widget build(BuildContext context) {
    final joy = (landscape['joy'] as List?)?.whereType<num>().toList() ?? [];
    final reflection =
        (landscape['reflection'] as List?)?.whereType<num>().toList() ?? [];
    final gratitude =
        (landscape['gratitude'] as List?)?.whereType<num>().toList() ?? [];
    final melancholy =
        (landscape['melancholy'] as List?)?.whereType<num>().toList() ?? [];

    final joyTotal = joy.fold<num>(0, (a, b) => a + b);
    final reflectionTotal = reflection.fold<num>(0, (a, b) => a + b);
    final gratitudeTotal = gratitude.fold<num>(0, (a, b) => a + b);
    final melancholyTotal = melancholy.fold<num>(0, (a, b) => a + b);

    final total = joyTotal + reflectionTotal + gratitudeTotal + melancholyTotal;

    final moodPills = [
      {'name': 'Joy', 'color': const Color(0xFF10B981), 'count': joyTotal},
      {
        'name': 'Reflection',
        'color': const Color(0xFF6366F1),
        'count': reflectionTotal,
      },
      {
        'name': 'Gratitude',
        'color': const Color(0xFFF59E0B),
        'count': gratitudeTotal,
      },
      {
        'name': 'Melancholy',
        'color': const Color(0xFFEC4899),
        'count': melancholyTotal,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECEEF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emotional Landscape',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Emotional undertones woven through your recollections',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: moodPills.map((mood) {
              final color = mood['color'] as Color;
              final name = mood['name'] as String;
              final count = (mood['count'] as num).toInt();
              final pct = total > 0 ? ((count / total) * 100).round() : 25;

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$pct%',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      Text(
                        name,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Word Cloud Card ──────────────────────────────────────────────────────────

class _WordCloudCard extends StatelessWidget {
  final List<Map<String, dynamic>> words;

  const _WordCloudCard({required this.words});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECEEF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Archive Keywords & Topics',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Frequently spoken themes & recurrent reflections',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: words.map((w) {
              final text = w['text'] as String? ?? '';
              final weight = (w['weight'] as num?)?.toInt() ?? 10;
              final isProminent = weight >= 20;

              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isProminent ? 14 : 10,
                  vertical: isProminent ? 8 : 5,
                ),
                decoration: BoxDecoration(
                  color: isProminent
                      ? const Color(0xFF4A3AFF).withValues(alpha: 0.1)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isProminent
                        ? const Color(0xFF4A3AFF).withValues(alpha: 0.3)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Text(
                  text,
                  style: GoogleFonts.outfit(
                    fontSize: isProminent ? 14 : 12,
                    fontWeight: isProminent ? FontWeight.w700 : FontWeight.w500,
                    color: isProminent
                        ? const Color(0xFF4A3AFF)
                        : const Color(0xFF4B5563),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── People in Archive ─────────────────────────────────────────────────────────

class _PeopleInArchiveCard extends StatelessWidget {
  final List<Map<String, dynamic>> people;

  const _PeopleInArchiveCard({required this.people});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECEEF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'People in Your Archive',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Loved ones and family featured across your entries',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: people.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, idx) {
                final p = people[idx];
                final name = p['name'] as String? ?? 'Family Member';
                final avatar = p['avatar'] as String?;
                final count = p['count']?.toString() ?? 'Mentioned';

                return SizedBox(
                  width: 72,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF4A3AFF),
                        backgroundImage: avatar != null && avatar.isNotEmpty
                            ? NetworkImage(MediaUrlFormatter.format(avatar)!)
                            : null,
                        child: avatar == null || avatar.isEmpty
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        count,
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Actionable Archive Insights ──────────────────────────────────────────────

class _ActionableInsightsCard extends StatelessWidget {
  final List<Map<String, dynamic>> insights;

  const _ActionableInsightsCard({required this.insights});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Smart Suggestions',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...insights.map((item) {
          final title = item['title'] as String? ?? 'Archive Note';
          final desc = item['desc'] as String? ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFECEEF2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A3AFF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Color(0xFF4A3AFF),
                    size: 20,
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
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
