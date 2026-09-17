import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/media_url_formatter.dart';
import '../../domain/entities/story_layer_entity.dart';
import '../../domain/repositories/memories_repository.dart';

class StoryLayersSection extends StatefulWidget {
  final String memoryId;

  const StoryLayersSection({super.key, required this.memoryId});

  @override
  State<StoryLayersSection> createState() => _StoryLayersSectionState();
}

class _StoryLayersSectionState extends State<StoryLayersSection> {
  // Static memory cache for instant loading without jitter/flashing
  static final Map<String, List<StoryLayerEntity>> _storyLayersCache = {};

  final _repository = sl<MemoriesRepository>();
  List<StoryLayerEntity> _layers = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (_storyLayersCache.containsKey(widget.memoryId)) {
      _layers = List.from(_storyLayersCache[widget.memoryId]!);
      _isLoading = false;
      _loadLayers(silent: true);
    } else {
      _loadLayers(silent: false);
    }
  }

  @override
  void didUpdateWidget(covariant StoryLayersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.memoryId != widget.memoryId) {
      if (_storyLayersCache.containsKey(widget.memoryId)) {
        setState(() {
          _layers = List.from(_storyLayersCache[widget.memoryId]!);
          _isLoading = false;
        });
        _loadLayers(silent: true);
      } else {
        setState(() {
          _layers = [];
          _isLoading = true;
        });
        _loadLayers(silent: false);
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadLayers({bool silent = false}) async {
    if (!silent && _layers.isEmpty && mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final layers = await _repository.getStoryLayers(widget.memoryId);
      _storyLayersCache[widget.memoryId] = layers;
      if (mounted) {
        setState(() {
          _layers = layers;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddPerspectiveModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add Family Perspective',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Share your personal memory or perspective on this family story.',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _textController,
                    maxLines: 3,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Write your story perspective...',
                      hintStyle: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.borderLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        _isSubmitting ? 'Saving...' : 'Add Perspective',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              final text = _textController.text.trim();
                              if (text.isNotEmpty) {
                                setModalState(() => _isSubmitting = true);
                                try {
                                  final newLayer = await _repository
                                      .addStoryLayer(
                                        widget.memoryId,
                                        text: text,
                                      );
                                  _textController.clear();
                                  if (mounted) {
                                    setState(() {
                                      _layers.add(newLayer);
                                      _storyLayersCache[widget.memoryId] =
                                          _layers;
                                    });
                                  }
                                  if (modalContext.mounted) {
                                    Navigator.pop(modalContext);
                                  }
                                } catch (e) {
                                  if (modalContext.mounted) {
                                    setModalState(() => _isSubmitting = false);
                                    ScaffoldMessenger.of(
                                      modalContext,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to add perspective: $e',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Responsive Header Row (Never overflows)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.layers_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Family Story Layers (${_layers.length})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(
                'Add Layer',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: _showAddPerspectiveModal,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
          )
        else if (_layers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.record_voice_over_outlined,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No multi-voice perspectives yet',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Family members can add their own perspective to this memory!',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ..._layers.map((layer) => _buildLayerItem(layer)),
      ],
    );
  }

  Widget _buildLayerItem(StoryLayerEntity layer) {
    final avatar = MediaUrlFormatter.format(layer.author?.avatarUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? Text(
                        layer.author?.name?.isNotEmpty == true
                            ? layer.author!.name![0].toUpperCase()
                            : 'F',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  layer.author?.name ?? 'Family Member',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Perspective',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            layer.text,
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
