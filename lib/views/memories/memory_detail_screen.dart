import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

import '../../theme/theme.dart';
import '../../services/memory_service.dart';
import 'full_screen_video_player.dart';

class MemoryDetailScreen extends StatefulWidget {
  const MemoryDetailScreen({
    super.key,
    required this.memory,
    this.onDelete,
    this.onUpdated,
  });

  final Map<String, dynamic> memory;
  final Future<void> Function()? onDelete;
  final ValueChanged<Map<String, dynamic>>? onUpdated;

  @override
  State<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

enum _MemoryMenuAction { edit, share, delete }

class _MemoryDetailScreenState extends State<MemoryDetailScreen> {
  final MemoryService _memoryService = MemoryService();

  late Map<String, dynamic> _memory;
  bool _isSaving = false;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _memory = Map<String, dynamic>.from(widget.memory);
    
    if (_memory['type']?.toString().toLowerCase() == 'voice' && _memory['mediaUrl'] != null) {
      _initAudio();
    }
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setUrl(_memory['mediaUrl']);
      _audioPlayer.durationStream.listen((d) {
        if (mounted) setState(() => _duration = d ?? Duration.zero);
      });
      _audioPlayer.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            if (state.processingState == ProcessingState.completed) {
              _isPlaying = false;
              _audioPlayer.seek(Duration.zero);
              _audioPlayer.pause();
            }
          });
        }
      });
    } catch (e) {
      debugPrint("Audio init error: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Get.back(),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else ...[
            PopupMenuButton<_MemoryMenuAction>(
              color: AppTheme.adaptiveCardBg,
              icon: Icon(
                Icons.more_horiz_rounded,
                color: AppTheme.adaptiveTextPrimary,
              ),
              onSelected: (action) {
                switch (action) {
                  case _MemoryMenuAction.edit:
                    _showEditSheet();
                    break;
                  case _MemoryMenuAction.share:
                    _showShareSheet();
                    break;
                  case _MemoryMenuAction.delete:
                    _confirmDelete();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _MemoryMenuAction.edit,
                  child: Text(
                    'Edit memory',
                    style: GoogleFonts.outfit(
                      color: AppTheme.adaptiveTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: _MemoryMenuAction.share,
                  child: Text(
                    'Share options',
                    style: GoogleFonts.outfit(
                      color: AppTheme.adaptiveTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (widget.onDelete != null)
                  PopupMenuItem(
                    value: _MemoryMenuAction.delete,
                    child: Text(
                      'Delete image',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFE85D75),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMediaVisual(),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildPill(
                  Icons.calendar_today_rounded,
                  _memory['date']?.toString().isNotEmpty == true
                      ? _memory['date'].toString()
                      : 'Undated',
                ),
                _buildPill(
                  Icons.photo_library_outlined,
                  _memory['type']?.toString().isNotEmpty == true
                      ? _memory['type'].toString()
                      : 'Memory',
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              _memory['title']?.toString().trim().isNotEmpty == true
                  ? _memory['title'].toString()
                  : 'Untitled memory',
              style: GoogleFonts.playfairDisplay(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                height: 1.08,
                color: AppTheme.adaptiveTextPrimary,
              ),
            ),
            const SizedBox(height: 10),
            if (_memory['type']?.toString().toLowerCase() != 'text')
              Text(
                _memory['description']?.toString().trim().isNotEmpty == true
                    ? _memory['description'].toString()
                    : 'No description added yet.',
                style: GoogleFonts.outfit(
                  fontSize: 15.5,
                  height: 1.6,
                  color: AppTheme.adaptiveTextSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaVisual() {
    final mediaUrl = _memory['mediaUrl']?.toString() ?? '';
    final thumbnailUrl = _memory['thumbnailUrl']?.toString() ?? '';
    final type = _memory['type']?.toString().toLowerCase() ?? '';

    if (type == 'text') {
      final hexColor = _memory['color']?.toString() ?? '';
      final bgColor = _parseColor(hexColor);
      return Container(
        height: 350,
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Text(
              _memory['description']?.toString() ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 20,
                height: 1.6,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      );
    }

    final hasThumb = thumbnailUrl.isNotEmpty;
    final displayUrl = (type == 'video' && hasThumb) ? thumbnailUrl : mediaUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            displayUrl.isNotEmpty
                ? Image.network(
                    displayUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildVisualFallback(),
                  )
                : _buildVisualFallback(),
            if (type == 'video' || type == 'voice' || type == 'audio')
              Center(
                child: GestureDetector(
                  onTap: () {
                    if (type == 'video' && mediaUrl.isNotEmpty) {
                      Get.to(() => FullScreenVideoPlayer(videoUrl: mediaUrl));
                    } else {
                      _togglePlayback();
                    }
                  },
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: (type == 'video' ? const Color(0xFFE85D75) : const Color(0xFF5D5FEF)).withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Icon(
                      (type == 'video' ? Icons.play_arrow_rounded : (_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded)),
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _togglePlayback() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return const Color(0xFFEBF5FF);
    try {
      String cleanHex = hexColor.replaceAll('#', '');
      if (cleanHex.length == 6) cleanHex = 'FF$cleanHex';
      // If it's 8 chars (including alpha), parse it.
      return Color(int.parse(cleanHex, radix: 16));
    } catch (e) {
      return const Color(0xFFEBF5FF);
    }
  }

  Widget _buildVisualFallback() {
    final type = _memory['type']?.toString().toLowerCase() ?? '';
    final icon = switch (type) {
      'video' => Icons.videocam_rounded,
      'voice' => Icons.mic_rounded,
      'audio' => Icons.mic_rounded,
      'text' => Icons.edit_note_rounded,
      _ => Icons.photo_library_outlined,
    };

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111827), Color(0xFF1F2937), Color(0xFF374151)],
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 54,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  Widget _buildPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.adaptiveSoftSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.adaptiveTextSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.adaptiveTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showShareSheet() async {
    final shareText = [
      _memory['title']?.toString() ?? '',
      _memory['description']?.toString() ?? '',
    ].where((part) => part.trim().isNotEmpty).join('\n\n');

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(
            color: AppTheme.adaptiveCardBg,
            borderRadius: BorderRadius.circular(28),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.adaptiveDivider,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Share options',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.adaptiveTextPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSheetAction(
                  icon: Icons.copy_rounded,
                  title: 'Copy title',
                  subtitle: 'Copy only the memory title.',
                  onTap: () async {
                    Navigator.of(context).pop();
                    await Clipboard.setData(
                      ClipboardData(
                        text: _memory['title']?.toString() ?? '',
                      ),
                    );
                    if (mounted) {
                      _showSnack('Title copied.');
                    }
                  },
                ),
                const SizedBox(height: 10),
                _buildSheetAction(
                  icon: Icons.notes_rounded,
                  title: 'Copy details',
                  subtitle: 'Copy the title and description together.',
                  onTap: () async {
                    Navigator.of(context).pop();
                    await Clipboard.setData(ClipboardData(text: shareText));
                    if (mounted) {
                      _showSnack('Memory details copied.');
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.adaptiveSoftSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF5D5FEF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF5D5FEF), size: 20),
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
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      color: AppTheme.adaptiveTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    if (widget.onDelete == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.adaptiveCardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Delete image?',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.adaptiveTextPrimary,
            ),
          ),
          content: Text(
            'This memory will be removed from the album.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.5,
              color: AppTheme.adaptiveTextSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE85D75),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;
    await widget.onDelete!.call();
    if (mounted) {
      Get.back();
    }
  }

  Future<void> _showEditSheet() async {
    final draft = await showModalBottomSheet<_MemoryEditDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MemoryEditSheet(
        initialTitle: _memory['title']?.toString() ?? '',
        initialDescription: _memory['description']?.toString() ?? '',
      ),
    );

    if (draft == null || !mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedMemory = await _memoryService.updateMemory(
        memoryId: _memory['id']?.toString() ?? '',
        title: draft.title,
        description: draft.description,
      );

      if (!mounted) return;

      setState(() {
        _memory = updatedMemory;
        _isSaving = false;
      });
      widget.onUpdated?.call(updatedMemory);
      _showSnack('Memory updated.');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      _showSnack(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _MemoryEditDraft {
  const _MemoryEditDraft({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}

class _MemoryEditSheet extends StatefulWidget {
  const _MemoryEditSheet({
    required this.initialTitle,
    required this.initialDescription,
  });

  final String initialTitle;
  final String initialDescription;

  @override
  State<_MemoryEditSheet> createState() => _MemoryEditSheetState();
}

class _MemoryEditSheetState extends State<_MemoryEditSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    Navigator.of(context).pop(
      _MemoryEditDraft(
        title: title,
        description: _descriptionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomInset),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.adaptiveDivider,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Edit memory',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.adaptiveTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Update the title and description for this memory.',
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      height: 1.5,
                      color: AppTheme.adaptiveTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _descriptionFocusNode.requestFocus(),
                    decoration: InputDecoration(
                      labelText: 'Title',
                      filled: true,
                      fillColor: AppTheme.adaptiveCardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: AppTheme.adaptiveBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: AppTheme.adaptiveBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    focusNode: _descriptionFocusNode,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    maxLines: 4,
                    minLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Write a short description.',
                      filled: true,
                      fillColor: AppTheme.adaptiveCardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: AppTheme.adaptiveBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: AppTheme.adaptiveBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF5D5FEF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        'Save changes',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
