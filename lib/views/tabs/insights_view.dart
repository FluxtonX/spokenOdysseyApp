import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../theme/theme.dart';
import '../../theme/typography.dart';
import '../../controllers/settings_controller.dart';

class InsightsView extends StatelessWidget {
  final SettingsController controller = Get.find<SettingsController>();

  InsightsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSubTabSelector(),
        Expanded(
          child: Obx(() {
            switch (controller.insightsSubTabIndex.value) {
              case 0:
                return _buildOverviewSubTab();
              case 1:
                return _buildImpactSubTab();
              case 2:
                return _buildThemesSubTab();
              default:
                return const SizedBox();
            }
          }),
        ),
      ],
    );
  }

  Widget _buildSubTabSelector() {
    final tabs = ['Overview', 'Impact & Reach', 'Themes'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value;
          return Obx(() {
            final isSelected = controller.insightsSubTabIndex.value == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => controller.insightsSubTabIndex.value = index,
                child: Column(
                  children: [
                    Text(
                      label,
                      style: isSelected
                          ? AppTextStyles.labelBold.copyWith(
                              color: const Color(0xFF5D5FEF),
                            )
                          : AppTextStyles.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF5D5FEF)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        }).toList(),
      ),
    );
  }

  // --- OVERVIEW SUB-TAB ---
  Widget _buildOverviewSubTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildInsightStatCard(
                '127',
                'Total Memories',
                '+8 this month',
                Icons.book_outlined,
                const Color(0xFF5D5FEF),
              ),
              _buildInsightStatCard(
                '47.2K',
                'Total Views',
                '+18% this quarter',
                Icons.visibility_outlined,
                const Color(0xFF22C55E),
              ),
              _buildInsightStatCard(
                'Grateful',
                'Most Common Mood',
                '35% of entries',
                Icons.favorite_border,
                const Color(0xFFF59E0B),
              ),
              _buildInsightStatCard(
                '14 days',
                'Longest Streak',
                'Personal best',
                Icons.calendar_today_outlined,
                const Color(0xFF3B82F6),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildArchiveActivityCard(),
          const SizedBox(height: 32),
          _buildLifeChaptersCard(),
          const SizedBox(height: 32),
          _buildEmotionalLandscapeCard(),
          const SizedBox(height: 32),
          _buildRevisitCard(),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildInsightStatCard(
    String value,
    String label,
    String subtext,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.labelBold.copyWith(fontSize: 20),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppTheme.textHint),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: AppTextStyles.labelMedium.copyWith(
              fontSize: 11,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle, {
    bool isWhite = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.h3.copyWith(
            color: isWhite ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: isWhite
                ? Colors.white.withOpacity(0.7)
                : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildArchiveActivityCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Archive Activity — 2026',
            'Memories created and views generated per month',
          ),
          const SizedBox(height: 48),
          _buildArchiveActivityChart(),
          const SizedBox(height: 40),
          _buildChartLegend(
            ['Memories', 'Views (÷20)'],
            [const Color(0xFF5D5FEF), const Color(0xFF22C55E)],
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveActivityChart() {
    return Row(
      children: [
        // Y-Axis Labels
        SizedBox(
          height: 200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['32', '24', '16', '8', '0'].map((label) {
              return Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textHint,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 16),
        // Chart Area
        Expanded(
          child: Column(
            children: [
              SizedBox(
                height: 200,
                width: double.infinity,
                child: CustomPaint(painter: LineChartPainter()),
              ),
              const SizedBox(height: 16),
              // X-Axis Labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['Feb', 'Apr', 'Jun', 'Aug', 'Oct', 'Dec'].map((
                  label,
                ) {
                  return Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textHint,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLifeChaptersCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Life Chapters',
            'Where you\'ve focused your storytelling energy',
          ),
          const SizedBox(height: 48),
          _buildLifeChaptersChart(),
        ],
      ),
    );
  }

  Widget _buildEmotionalLandscapeCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Emotional Landscape',
            'Moods that color your memories most often',
          ),
          const SizedBox(height: 32),
          _buildEmotionalLandscapeChart(),
        ],
      ),
    );
  }

  Widget _buildRevisitCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 22,
                color: AppTheme.textPrimary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Memories Worth Revisiting',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'These stories haven\'t been opened in a while...',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          _buildRevisitList(),
        ],
      ),
    );
  }

  Widget _buildLifeChaptersChart() {
    final data = [
      {'label': 'Career', 'value': 45.0},
      {'label': 'Family', 'value': 60.0},
      {'label': '', 'value': 0.0}, // Separator space
      {'label': 'Personal', 'value': 40.0},
      {'label': 'Travel', 'value': 22.0},
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Y-Axis Labels
        SizedBox(
          height: 200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['60', '45', '30', '15', '0'].map((label) {
              return Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppTheme.textHint,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 20),
        // Bars Area
        Expanded(
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: data.map((item) {
                    final isSpace = item['label'] == '';
                    if (isSpace) return const SizedBox(width: 20);

                    final h =
                        (item['value'] as double) * 200 / 60; // Scale to 200
                    return Container(
                      width: 50,
                      height: h,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5D5FEF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              // X-Axis Labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: data.map((item) {
                  final isSpace = item['label'] == '';
                  if (isSpace) return const SizedBox(width: 20);
                  return SizedBox(
                    width: 50,
                    child: Center(
                      child: Text(
                        item['label'] as String,
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textHint,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmotionalLandscapeChart() {
    return Column(
      children: [
        Center(
          child: SizedBox(
            width: 220,
            height: 220,
            child: CustomPaint(painter: DonutChartPainter()),
          ),
        ),
        const SizedBox(height: 48),
        Column(
          children: [
            _buildMoodLegendItem('Grateful', '35%', const Color(0xFF5D5FEF)),
            _buildMoodLegendItem('Joyful', '28%', const Color(0xFF818CF8)),
            _buildMoodLegendItem('Reflective', '18%', const Color(0xFFC7D2FE)),
            _buildMoodLegendItem('Hopeful', '12%', const Color(0xFFE0E7FF)),
            _buildMoodLegendItem('Peaceful', '7%', const Color(0xFFF3F4F6)),
          ],
        ),
      ],
    );
  }

  Widget _buildMoodLegendItem(String label, String percent, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 16),
          Text(label, style: AppTextStyles.labelMedium),
          const Spacer(),
          Text(
            percent,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevisitList() {
    return Column(
      children: [
        _buildRevisitItem(
          'First Day at College',
          'August 24, 2005',
          '427 days ago',
        ),
        _buildRevisitItem(
          'Learning to Play Guitar',
          'June 12, 2010',
          '213 days ago',
        ),
        _buildRevisitItem(
          'Road Trip to Montana',
          'July 4, 2012',
          '356 days ago',
        ),
      ],
    );
  }

  Widget _buildRevisitItem(String title, String date, String timeAgo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h3),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(date, style: AppTextStyles.bodySmall),
                    const Spacer(),
                    Text(
                      timeAgo,
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textHint,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppTheme.textHint,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(List<String> labels, List<Color> colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: labels.asMap().entries.map((entry) {
        final i = entry.key;
        final label = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 7,
                decoration: BoxDecoration(
                  color: colors[i],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- IMPACT & REACH SUB-TAB ---
  Widget _buildImpactSubTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF334155)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COLLECTIVE IMPACT',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withOpacity(0.5),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '8,140',
                  style: AppTextStyles.h1.copyWith(
                    fontSize: 48,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'people meaningfully reached',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'across counseling, coaching, and support communities',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withOpacity(0.6),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildWhiteStat('47.2K', 'Total\nViews'),
                    _buildWhiteStat('6', 'Counseling\nTopics'),
                    _buildWhiteStat('+30%', '7-month\ngrowth'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader(
            'Impact Growth',
            'People helped per month across all counseling topics',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '+ 580% in 7 months',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF166534),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildImpactGrowthChart(),
          const SizedBox(height: 32),
          _buildSectionHeader(
            'Impact by Counseling Topic',
            'How your memories are being used to help others in guided counseling, coaching, and support context.',
          ),
          const SizedBox(height: 24),
          _buildTopicImpactList(),
          const SizedBox(height: 32),
          _buildSectionHeader(
            'Most Impactful Memories',
            'These entries have generated the most real-world impact across counseling and coaching topics.',
          ),
          const SizedBox(height: 24),
          _buildImpactfulMemoriesList(),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildWhiteStat(String val, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          val,
          style: AppTextStyles.labelBold.copyWith(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: Colors.white.withOpacity(0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildImpactGrowthChart() {
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: CustomPaint(painter: ImpactLinePainter()),
    );
  }

  Widget _buildTopicImpactList() {
    return Column(
      children: [
        _buildTopicItem(
          'Resilience & Setback',
          '1,842 helped',
          94,
          const Color(0xFF5D5FEF),
          '+18%',
        ),
        _buildTopicItem(
          'Parenting',
          '1,254 helped',
          82,
          const Color(0xFF22C55E),
          '+12%',
        ),
        _buildTopicItem(
          'Motivation & Purpose',
          '3,107 helped',
          87,
          const Color(0xFFF59E0B),
          '+31%',
        ),
        _buildTopicItem(
          'Sports & Achievement',
          '891 helped',
          75,
          const Color(0xFF3B82F6),
          '+8%',
        ),
      ],
    );
  }

  Widget _buildTopicItem(
    String title,
    String subtitle,
    int score,
    Color color,
    String growth,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.psychology_outlined, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.labelBold.copyWith(fontSize: 15),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            growth,
                            style: AppTextStyles.labelMedium.copyWith(
                              fontSize: 11,
                              color: const Color(0xFF166534),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Impact score',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  color: AppTheme.textHint,
                ),
              ),
              const Spacer(),
              Text(
                '$score/100',
                style: AppTextStyles.labelMedium.copyWith(
                  fontSize: 11,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: color.withOpacity(0.1),
              color: color,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactfulMemoriesList() {
    return Column(
      children: [
        _buildImpactfulItem(
          1,
          'Conquering My First Marathon',
          ['Motivation', 'Sports', 'Resilience'],
          '12,500',
          '3,107',
          const Color(0xFF5D5FEF),
        ),
        _buildImpactfulItem(
          2,
          'The Day I Started My Own Business',
          ['Motivation', 'Resilience', 'Settback'],
          '9,840',
          '2,401',
          const Color(0xFFF59E0B),
        ),
        _buildImpactfulItem(
          3,
          'Morning Coffee with Dad',
          ['Parenting', 'Healing', 'Connection'],
          '7,210',
          '1,832',
          const Color(0xFF22C55E),
        ),
      ],
    );
  }

  Widget _buildImpactfulItem(
    int rank,
    String title,
    List<String> tags,
    String views,
    String helped,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: AppTextStyles.labelBold.copyWith(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelBold.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: tags
                      .map(
                        (t) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            t,
                            style: AppTextStyles.labelMedium.copyWith(
                              fontSize: 10,
                              color: color,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.visibility_outlined,
                      size: 14,
                      color: AppTheme.textHint,
                    ),
                    const SizedBox(width: 4),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.favorite_border,
                      size: 14,
                      color: AppTheme.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      helped,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontSize: 12,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- THEMES SUB-TAB ---
  Widget _buildThemesSubTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Recurring Themes',
            'AI has detected these patterns across your memories, revealing the core threads of your life story.',
          ),
          const SizedBox(height: 24),
          _buildThemeItem('Resilience & Growth', 34, 0.85, [
            'strength',
            'perseverance',
            'learning',
            'courage',
          ], const Color(0xFF5D5FEF)),
          _buildThemeItem('Family & Connection', 42, 0.92, [
            'love',
            'support',
            'togetherness',
            'heritage',
          ], const Color(0xFF22C55E)),
          _buildThemeItem('Purpose & Impact', 28, 0.70, [
            'service',
            'contribution',
            'legacy',
            'meaning',
          ], const Color(0xFFF59E0B)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5D5FEF).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline,
                        size: 20,
                        color: Color(0xFF5D5FEF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'AI REFLECTION',
                      style: AppTextStyles.labelBold.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF5D5FEF),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'What Your Archive Says About You',
                  style: AppTextStyles.h3.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 16),
                Text(
                  '"Your story is one of continuous growth through connection. You\'ve documented not just events, but the emotional wisdom gained from each experience. The thread that ties your memories together is gratitude — not as passive acceptance, but as active recognition of life\'s lessons."',
                  style: AppTextStyles.bodyMedium.copyWith(
                    height: 1.6,
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildReflectionTag('Connection-oriented'),
                    _buildReflectionTag('Gratitude-led'),
                    _buildReflectionTag('Growth-centered'),
                    _buildReflectionTag('Legacy-conscious'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader(
            'Writing Cadence',
            'Your most active days and times for memory creation',
          ),
          const SizedBox(height: 24),
          _buildActivityHeatmap(),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildThemeItem(
    String title,
    int mentions,
    double progress,
    List<String> chips,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: AppTextStyles.labelBold),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$mentions mentions',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontSize: 11,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: color.withOpacity(0.1),
              color: color,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips
                .map(
                  (c) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(c, style: AppTextStyles.bodySmall),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReflectionTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelMedium.copyWith(
          fontSize: 12,
          color: const Color(0xFF4F46E5),
        ),
      ),
    );
  }

  Widget _buildActivityHeatmap() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: 28,
            itemBuilder: (context, index) {
              final intensities = [
                1,
                2,
                0,
                1,
                3,
                2,
                1,
                0,
                1,
                4,
                2,
                1,
                0,
                3,
                1,
                1,
                2,
                1,
                0,
                2,
                4,
                1,
                0,
                2,
                1,
                1,
                3,
                1,
              ];
              final level = intensities[index];
              Color c;
              switch (level) {
                case 1:
                  c = const Color(0xFFC7D2FE);
                  break;
                case 2:
                  c = const Color(0xFF818CF8);
                  break;
                case 3:
                  c = const Color(0xFF6366F1);
                  break;
                case 4:
                  c = const Color(0xFF4338CA);
                  break;
                default:
                  c = const Color(0xFFF3F4F6);
              }
              return Container(
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Less',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  color: AppTheme.textHint,
                ),
              ),
              const SizedBox(width: 8),
              _heatBox(const Color(0xFFF3F4F6)),
              _heatBox(const Color(0xFFC7D2FE)),
              _heatBox(const Color(0xFF818CF8)),
              _heatBox(const Color(0xFF6366F1)),
              _heatBox(const Color(0xFF4338CA)),
              const SizedBox(width: 8),
              Text(
                'More',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  color: AppTheme.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heatBox(Color c) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 2),
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
  );
}

class LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFF3F4F6)
      ..strokeWidth = 1;

    // Draw horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      double y = size.height - (i * size.height / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Mock data points (0.0 to 1.0 range)
    final points1 = [
      0.25,
      0.45,
      0.32,
      0.55,
      0.42,
      0.62,
      0.45,
      0.35,
      0.48,
      0.52,
      0.3,
    ]; // Purple
    final points2 = [
      0.2,
      0.55,
      0.45,
      0.75,
      0.62,
      0.95,
      0.72,
      0.55,
      0.78,
      0.82,
      0.45,
    ]; // Green

    _drawSmoothPath(canvas, size, points1, const Color(0xFF5D5FEF), true);
    _drawSmoothPath(canvas, size, points2, const Color(0xFF22C55E), false);
  }

  void _drawSmoothPath(
    Canvas canvas,
    Size size,
    List<double> values,
    Color color,
    bool fill,
  ) {
    if (values.isEmpty) return;

    final path = Path();
    final stepX = size.width / (values.length - 1);

    path.moveTo(0, size.height * (1 - values[0]));

    for (int i = 0; i < values.length - 1; i++) {
      final x1 = i * stepX;
      final y1 = size.height * (1 - values[i]);
      final x2 = (i + 1) * stepX;
      final y2 = size.height * (1 - values[i + 1]);

      final controlPoint1 = Offset(x1 + stepX / 2, y1);
      final controlPoint2 = Offset(x2 - stepX / 2, y2);

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        x2,
        y2,
      );
    }

    // Draw stroke
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaint);

    // Draw fill if enabled
    if (fill) {
      final fillPath = Path.from(path);
      fillPath.lineTo(size.width, size.height);
      fillPath.lineTo(0, size.height);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.15), color.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(fillPath, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5,
      2.2,
      false,
      paint..color = const Color(0xFF5D5FEF),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.8,
      1.5,
      false,
      paint..color = const Color(0xFF818CF8),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.4,
      1.0,
      false,
      paint..color = const Color(0xFFC7D2FE),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.5,
      0.7,
      false,
      paint..color = const Color(0xFFE0E7FF),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      4.3,
      0.4,
      false,
      paint..color = const Color(0xFFF3F4F6),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ImpactLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5D5FEF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.cubicTo(
      size.width * 0.4,
      size.height * 0.8,
      size.width * 0.6,
      size.height * 0.4,
      size.width,
      size.height * 0.2,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
