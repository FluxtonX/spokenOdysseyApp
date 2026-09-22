import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_url_formatter.dart';
import '../../domain/entities/family_prompt_entity.dart';
import '../cubits/family_cubit.dart';

class FamilyPromptsWidget extends StatefulWidget {
  final List<FamilyPromptEntity> prompts;

  const FamilyPromptsWidget({super.key, required this.prompts});

  @override
  State<FamilyPromptsWidget> createState() => _FamilyPromptsWidgetState();
}

class _FamilyPromptsWidgetState extends State<FamilyPromptsWidget> {
  String _selectedCategory = 'All';
  final Map<String, TextEditingController> _replyControllers = {};
  final Set<String> _activeReplyingPromptIds = {};

  static const List<String> _categories = [
    'All',
    'Heritage',
    'Childhood',
    'Wisdom',
    'Love & Family',
    'Milestones',
  ];

  static const List<Map<String, String>> _suggestedPrompts = [
    {
      'question':
          'What is the earliest family story or tradition you remember?',
      'category': 'Heritage',
    },
    {
      'question': 'What was your childhood home like, and who lived there?',
      'category': 'Childhood',
    },
    {
      'question':
          'What is the most valuable piece of advice your parents gave you?',
      'category': 'Wisdom',
    },
    {
      'question': 'How did you and your partner first meet and fall in love?',
      'category': 'Love & Family',
    },
  ];

  @override
  void dispose() {
    for (final c in _replyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _openCreatePromptModal(BuildContext context) {
    final questionController = TextEditingController();
    String chosenCategory = 'Heritage';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ask Your Family',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Prompt elders, parents, or siblings to share a cherished memory.',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Category',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.where((c) => c != 'All').map((cat) {
                      final isSel = chosenCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSel,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() => chosenCategory = cat);
                          }
                        },
                        selectedColor: AppColors.primary.withValues(
                          alpha: 0.15,
                        ),
                        labelStyle: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          color: isSel
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSel
                                ? AppColors.primary
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your Question',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: questionController,
                    maxLines: 3,
                    style: GoogleFonts.outfit(fontSize: 14),
                    decoration: InputDecoration(
                      hintText:
                          'e.g. What was dinner time like when you were growing up?',
                      hintStyle: GoogleFonts.outfit(
                        fontSize: 14,
                        color: const Color(0xFF9CA3AF),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final text = questionController.text.trim();
                        if (text.isEmpty) return;
                        Navigator.pop(modalCtx);
                        final cubit = context.read<FamilyCubit>();
                        final success = await cubit.createPrompt(
                          question: text,
                          category: chosenCategory,
                        );
                        if (mounted && success) {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Prompt posted to your family!'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Post Prompt',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.prompts.where((p) {
      if (_selectedCategory == 'All') return true;
      return p.category.toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<FamilyCubit>().loadPrompts(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // Top action row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Family Prompts',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Spark timeless oral conversations',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _openCreatePromptModal(context),
                icon: const Icon(Icons.add_comment_rounded, size: 16),
                label: const Text('Ask Question'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Category filter pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSel = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSel,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFFEFF0FF),
                    labelStyle: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel
                          ? AppColors.primary
                          : const Color(0xFF6B7280),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: isSel
                            ? AppColors.primary
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Prompts list or empty state
          if (filtered.isEmpty) ...[
            _buildEmptyState(context),
          ] else ...[
            ...filtered.map((prompt) => _buildPromptCard(context, prompt)),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECEEF2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF0FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.question_answer_rounded,
              color: AppColors.primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No family questions yet',
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ask a question or tap a starter below to get your family sharing their cherished memories.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Quick Starter Ideas:',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ..._suggestedPrompts.map((idea) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                title: Text(
                  idea['question']!,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
                trailing: TextButton(
                  onPressed: () {
                    context.read<FamilyCubit>().createPrompt(
                      question: idea['question']!,
                      category: idea['category']!,
                    );
                  },
                  child: Text(
                    'Ask',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPromptCard(BuildContext context, FamilyPromptEntity prompt) {
    final isReplying = _activeReplyingPromptIds.contains(prompt.id);
    final controller = _replyControllers.putIfAbsent(
      prompt.id,
      () => TextEditingController(),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECEEF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Creator info + Category
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF4A3AFF),
                backgroundImage:
                    prompt.creatorAvatar != null &&
                        prompt.creatorAvatar!.isNotEmpty
                    ? NetworkImage(
                        MediaUrlFormatter.format(prompt.creatorAvatar!) ?? '',
                      )
                    : null,
                child:
                    prompt.creatorAvatar == null ||
                        prompt.creatorAvatar!.isEmpty
                    ? Text(
                        prompt.creatorName?.isNotEmpty == true
                            ? prompt.creatorName![0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prompt.creatorName ?? 'Family Member',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (prompt.createdAt != null)
                      Text(
                        'Asked ${DateFormat.yMMMd().format(prompt.createdAt!)}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  prompt.category,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4A3AFF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Question Text
          Text(
            '“${prompt.question}”',
            style: GoogleFonts.newsreader(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 14),

          // Responses count / list
          if (prompt.responses.isNotEmpty) ...[
            Text(
              '${prompt.responses.length} ${prompt.responses.length == 1 ? "Response" : "Responses"}',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            ...prompt.responses.map((resp) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFF10B981),
                          backgroundImage:
                              resp.userAvatar != null &&
                                  resp.userAvatar!.isNotEmpty
                              ? NetworkImage(
                                  MediaUrlFormatter.format(resp.userAvatar!) ??
                                      '',
                                )
                              : null,
                          child:
                              resp.userAvatar == null ||
                                  resp.userAvatar!.isEmpty
                              ? Text(
                                  resp.userName?.isNotEmpty == true
                                      ? resp.userName![0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          resp.userName ?? 'Family Member',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (resp.text != null && resp.text!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        resp.text!,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: const Color(0xFF374151),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],

          // Reply field
          if (isReplying) ...[
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 2,
              autofocus: true,
              style: GoogleFonts.outfit(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Share your memory or answer...',
                hintStyle: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFF9CA3AF),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _activeReplyingPromptIds.remove(prompt.id);
                    });
                  },
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(color: const Color(0xFF6B7280)),
                  ),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  onPressed: () async {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    final ok = await context
                        .read<FamilyCubit>()
                        .respondToPrompt(promptId: prompt.id, text: text);
                    if (mounted && ok) {
                      controller.clear();
                      setState(() {
                        _activeReplyingPromptIds.remove(prompt.id);
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Send Answer'),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _activeReplyingPromptIds.add(prompt.id);
                  });
                },
                icon: const Icon(Icons.reply_rounded, size: 16),
                label: const Text('Answer this Prompt'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
