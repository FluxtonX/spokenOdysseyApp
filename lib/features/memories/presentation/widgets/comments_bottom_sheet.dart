// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/media_url_formatter.dart';
import '../../domain/entities/comment_entity.dart';
import '../cubits/memory_detail_cubit.dart';

class CommentsBottomSheet extends StatefulWidget {
  final String memoryId;
  final Function(int count)? onCommentsUpdated;

  const CommentsBottomSheet({
    super.key,
    required this.memoryId,
    this.onCommentsUpdated,
  });

  static void show(
    BuildContext context,
    String memoryId, {
    Function(int count)? onCommentsUpdated,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider<MemoryDetailCubit>(
        create: (_) => sl<MemoryDetailCubit>()..loadMemoryDetails(memoryId),
        child: CommentsBottomSheet(
          memoryId: memoryId,
          onCommentsUpdated: onCommentsUpdated,
        ),
      ),
    );
  }

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  String? _replyToCommentId;
  String? _replyToAuthorName;

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<MemoryDetailCubit, MemoryDetailState>(
      listener: (context, state) {
        if (state is MemoryDetailLoaded && widget.onCommentsUpdated != null) {
          widget.onCommentsUpdated!(state.comments.length);
        }
      },
      child: AnimatedPadding(
        padding: EdgeInsets.only(bottom: keyboardHeight),
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: screenHeight * 0.70,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Top Drag Handle
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),

              // Header Bar
              BlocBuilder<MemoryDetailCubit, MemoryDetailState>(
                builder: (context, state) {
                  int count = 0;
                  if (state is MemoryDetailLoaded) {
                    count = state.comments.length;
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Comments ($count)',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(height: 1),

              // Comments List
              Expanded(
                child: BlocBuilder<MemoryDetailCubit, MemoryDetailState>(
                  builder: (context, state) {
                    if (state is MemoryDetailLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is MemoryDetailLoaded) {
                      if (state.comments.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 48,
                                color: AppColors.textLight,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No comments yet',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Be the first to share your thoughts!',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: state.comments.length,
                        itemBuilder: (context, index) {
                          return _buildCommentItem(
                            context,
                            state.comments[index],
                          );
                        },
                      );
                    } else if (state is MemoryDetailError) {
                      return Center(
                        child: Text(
                          state.message,
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),

              // Facebook-style Comment Input Box
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
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
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() {
                              _replyToCommentId = null;
                              _replyToAuthorName = null;
                            }),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            'U',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: _replyToCommentId != null
                                  ? 'Write a reply...'
                                  : 'Write a comment...',
                              hintStyle: GoogleFonts.outfit(
                                color: AppColors.textLight,
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: AppColors.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.send_rounded,
                            color: AppColors.primary,
                          ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildCommentItem(
    BuildContext context,
    CommentEntity comment, {
    bool isReply = false,
  }) {
    final avatar = MediaUrlFormatter.format(comment.author?.avatarUrl);

    return Container(
      margin: EdgeInsets.only(left: isReply ? 36 : 0, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            backgroundImage: avatar != null ? NetworkImage(avatar) : null,
            child: avatar == null
                ? Text(
                    comment.author?.name?.isNotEmpty == true
                        ? comment.author!.name![0].toUpperCase()
                        : 'U',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.author?.name ?? 'User',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comment.text,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _replyToCommentId = comment.id;
                            _replyToAuthorName = comment.author?.name ?? 'User';
                          });
                        },
                        child: Text(
                          'Reply',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (comment.replies.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...comment.replies.map(
                    (r) => _buildCommentItem(context, r, isReply: true),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
