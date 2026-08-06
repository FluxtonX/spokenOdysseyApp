import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/media_url_formatter.dart';
import '../../domain/entities/comment_entity.dart';
import '../cubits/memory_detail_cubit.dart';
import '../widgets/memory_card.dart';

class MemoryDetailPage extends StatefulWidget {
  final String memoryId;

  const MemoryDetailPage({super.key, required this.memoryId});

  @override
  State<MemoryDetailPage> createState() => _MemoryDetailPageState();
}

class _MemoryDetailPageState extends State<MemoryDetailPage> {
  final _commentController = TextEditingController();
  String? _replyToCommentId;
  String? _replyToAuthorName;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MemoryDetailCubit>(
      create: (context) => sl<MemoryDetailCubit>()..loadMemoryDetails(widget.memoryId),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Memory Details',
            style: GoogleFonts.outfit(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),
        body: BlocBuilder<MemoryDetailCubit, MemoryDetailState>(
          builder: (context, state) {
            if (state is MemoryDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is MemoryDetailLoaded) {
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MemoryCard(
                            memory: state.memory,
                            onTap: () {},
                            onReact: (type) {
                              context.read<MemoryDetailCubit>().reactToMemory(state.memory.id, type);
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Comments (${state.comments.length})',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (state.comments.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Text(
                                  'No comments yet. Be the first to share your thoughts!',
                                  style: GoogleFonts.outfit(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...state.comments.map((c) => _buildCommentItem(context, c)),
                        ],
                      ),
                    ),
                  ),

                  // Comment Input Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_replyToCommentId != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Replying to ${_replyToAuthorName ?? "comment"}',
                                style: GoogleFonts.outfit(fontSize: 12, color: AppColors.primary),
                              ),
                              GestureDetector(
                                onTap: () => setState(() {
                                  _replyToCommentId = null;
                                  _replyToAuthorName = null;
                                }),
                                child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: InputDecoration(
                                  hintText: 'Add a comment...',
                                  hintStyle: GoogleFonts.outfit(color: AppColors.textLight),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: const BorderSide(color: AppColors.borderLight),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                              onPressed: () {
                                final text = _commentController.text.trim();
                                if (text.isNotEmpty) {
                                  context.read<MemoryDetailCubit>().addComment(
                                        widget.memoryId,
                                        text,
                                        parentCommentId: _replyToCommentId,
                                      );
                                  _commentController.clear();
                                  setState(() {
                                    _replyToCommentId = null;
                                    _replyToAuthorName = null;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            } else if (state is MemoryDetailError) {
              return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildCommentItem(BuildContext context, CommentEntity comment, {bool isReply = false}) {
    final avatar = MediaUrlFormatter.format(comment.author?.avatarUrl);

    return Container(
      margin: EdgeInsets.only(left: isReply ? 36 : 0, bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? Text(
                        comment.author?.name?.isNotEmpty == true ? comment.author!.name![0] : 'U',
                        style: GoogleFonts.outfit(fontSize: 10, color: AppColors.primary),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  comment.author?.name ?? 'User',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _replyToCommentId = comment.id;
                    _replyToAuthorName = comment.author?.name ?? 'User';
                  });
                },
                child: Text(
                  'Reply',
                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comment.text,
            style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textPrimary),
          ),
          if (comment.replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...comment.replies.map((r) => _buildCommentItem(context, r, isReply: true)),
          ],
        ],
      ),
    );
  }
}
