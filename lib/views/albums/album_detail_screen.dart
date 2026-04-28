import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../customWidgets/inline_memory_card.dart';
import '../../services/memory_service.dart';
import '../../theme/theme.dart';
import '../../utils/image_picker_helper.dart';
import '../memories/memory_detail_screen.dart';
import '../memories/record_story_screen.dart';
import '../memories/video_memory_screen.dart';
import '../memories/voice_memory_screen.dart';
import '../memories/text_memory_screen.dart';

class AlbumDetailScreen extends StatefulWidget {
  const AlbumDetailScreen({super.key, required this.album});

  final Map<String, dynamic> album;

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  final MemoryService _memoryService = MemoryService();

  late Map<String, dynamic> _album;
  bool _didChange = false;
  bool _isDeletingMemory = false;
  bool _isAddingMemory = false;
  DateTime? _selectedRecentDay;

  List<Map<String, dynamic>> get _memories =>
      ((_album['memories'] as List?) ?? const [])
          .whereType<Map>()
          .map((memory) => Map<String, dynamic>.from(memory))
          .toList()
        ..sort((a, b) {
          final aDate = _memoryDate(a);
          final bDate = _memoryDate(b);
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });

  List<Map<String, dynamic>> get _recentMemories => _memories;

  DateTime? _memoryDate(Map<String, dynamic> memory) {
    final candidates = [
      memory['date'], // Backend uses 'date'
      memory['dateRaw'],
      memory['occurredAt'],
      memory['createdAt'],
      memory['updatedAt'],
    ];

    for (final candidate in candidates) {
      final parsed = DateTime.tryParse(candidate?.toString() ?? '');
      if (parsed != null) return parsed.toLocal();
    }
    return null;
  }

  bool _isSameCalendarDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  List<Map<String, dynamic>> get _filteredVisualMemories {
    final selectedDay = _selectedRecentDay;
    if (selectedDay == null) return _recentMemories;

    return _recentMemories.where((memory) {
      final memoryDate = _memoryDate(memory);
      return memoryDate != null && _isSameCalendarDay(memoryDate, selectedDay);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _album = Map<String, dynamic>.from(widget.album);
  }

  Future<void> _closeWithResult() async {
    if (_didChange) {
      Get.back(result: {'action': 'updated', 'album': _album});
      return;
    }
    Get.back();
  }

  Future<void> _showAddMemorySheet() async {
    if (_isAddingMemory) return;

    final selectedFormat = await showModalBottomSheet<RecordStoryFormat>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _AddMemorySheet(albumTitle: _album['title']?.toString()),
    );

    if (selectedFormat == null || !mounted) return;

    if (selectedFormat == RecordStoryFormat.photoText) {
      await _addQuickPhotoMemory();
      return;
    }

    final result = await Get.to<Map<String, dynamic>>(
      () => switch (selectedFormat) {
        RecordStoryFormat.video => VideoMemoryScreen(
          albumId: _album['id']?.toString(),
        ),
        RecordStoryFormat.voice => VoiceMemoryScreen(
          albumId: _album['id']?.toString(),
        ),
        RecordStoryFormat.text => TextMemoryScreen(
          albumId: _album['id']?.toString(),
        ),
        _ => RecordStoryScreen(
          initialFormat: selectedFormat,
          initialAlbumId: _album['id']?.toString(),
        ),
      },
      transition: Transition.cupertino,
    );

    if (!mounted || result == null) return;

    final status = result['status']?.toString();
    final memoryRaw = result['memory'];
    if (memoryRaw is! Map) return;

    final memory = Map<String, dynamic>.from(memoryRaw);
    if (status != 'published') {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            'Draft saved.',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final updatedMemories = [
      memory,
      ..._memories.where(
        (existing) => existing['id']?.toString() != memory['id']?.toString(),
      ),
    ];

    setState(() {
      _album = {
        ..._album,
        'memories': updatedMemories,
        'entries': updatedMemories.length,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      _didChange = true;
    });

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          'Memory added.',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _addQuickPhotoMemory() async {
    final photoFile = await ImagePickerHelper.pickWithSourceSheet(context);
    if (photoFile == null || !mounted) return;

    final draft = await showModalBottomSheet<_QuickPhotoMemoryDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuickPhotoMemorySheet(
        photoFile: photoFile,
        albumTitle: _album['title']?.toString(),
      ),
    );

    if (draft == null || !mounted) return;

    setState(() {
      _isAddingMemory = true;
    });

    try {
      final memory = await _memoryService.createMemory(
        title: draft.title,
        description: draft.description,
        tags: const [],
        mood: 'Reflective',
        privacy: 'Private',
        type: 'Photo',
        publish: true,
        occurredAt: DateTime.now(),
        albumId: _album['id']?.toString(),
        mediaFile: photoFile,
      );

      if (!mounted) return;
      final updatedMemories = [
        memory,
        ..._memories.where(
          (existing) => existing['id']?.toString() != memory['id']?.toString(),
        ),
      ];

      setState(() {
        _album = {
          ..._album,
          'memories': updatedMemories,
          'entries': updatedMemories.length,
          'updatedAt': DateTime.now().toIso8601String(),
        };
        _didChange = true;
        _isAddingMemory = false;
      });

      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            'Photo added.',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isAddingMemory = false;
      });
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool> _performDeleteMemory(Map<String, dynamic> memory) async {
    setState(() {
      _isDeletingMemory = true;
    });

    try {
      await _memoryService.deleteMemory(memory['id']?.toString() ?? '');
      final updatedMemories = _memories
          .where((item) => item['id']?.toString() != memory['id']?.toString())
          .toList();

      if (!mounted) return false;
      setState(() {
        _album = {
          ..._album,
          'memories': updatedMemories,
          'entries': updatedMemories.length,
          'updatedAt': DateTime.now().toIso8601String(),
        };
        _didChange = true;
        _isDeletingMemory = false;
      });

      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            'Memory deleted.',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return true;
    } catch (error) {
      if (!mounted) return false;
      setState(() {
        _isDeletingMemory = false;
      });
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }

  Future<void> _deleteMemoryFromDetail(Map<String, dynamic> memory) async {
    await _performDeleteMemory(memory);
  }

  void _applyUpdatedMemory(Map<String, dynamic> updatedMemory) {
    final updatedMemories =
        [
          updatedMemory,
          ..._memories.where(
            (memory) =>
                memory['id']?.toString() != updatedMemory['id']?.toString(),
          ),
        ]..sort((a, b) {
          final aDate = DateTime.tryParse(a['dateRaw']?.toString() ?? '');
          final bDate = DateTime.tryParse(b['dateRaw']?.toString() ?? '');
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });

    setState(() {
      _album = {
        ..._album,
        'memories': updatedMemories,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      _didChange = true;
    });
  }

  Future<void> _openMemoryDetail(Map<String, dynamic> memory) async {
    await Get.to<void>(
      () => MemoryDetailScreen(
        memory: memory,
        onDelete: () => _deleteMemoryFromDetail(memory),
        onUpdated: _applyUpdatedMemory,
      ),
      transition: Transition.cupertino,
    );
  }

  Future<void> _showRecentFilterSheet() async {
    final selected = await showModalBottomSheet<_RecentFilterSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RecentFilterSheet(
        memories: _recentMemories,
        selectedDay: _selectedRecentDay,
      ),
    );

    if (selected != null && mounted) {
      setState(() => _selectedRecentDay = selected.day);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _closeWithResult();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        floatingActionButton: FloatingActionButton(
          onPressed: _isAddingMemory || _isDeletingMemory
              ? null
              : _showAddMemorySheet,
          backgroundColor: const Color(0xFF5D5FEF),
          foregroundColor: Colors.white,
          elevation: 2,
          child: _isAddingMemory || _isDeletingMemory
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.add_rounded),
        ),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              leading: IconButton(
                onPressed: _closeWithResult,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: _buildAlbumHeader(),
              ),
            ),
            if (_memories.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.adaptiveCardBg,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppTheme.adaptiveBorder),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(
                              0xFF5D5FEF,
                            ).withValues(alpha: 0.08),
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate_outlined,
                            color: Color(0xFF5D5FEF),
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Start filling this album',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.adaptiveTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Use the add button below to drop in photos, videos, voice notes, or text memories.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            height: 1.55,
                            color: AppTheme.adaptiveTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Recent',
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.adaptiveTextPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _showRecentFilterSheet,
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.adaptiveSoftSurface,
                            ),
                            icon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_month_rounded,
                                  size: 18,
                                  color: AppTheme.adaptiveTextPrimary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _selectedRecentDay == null
                                      ? 'All'
                                      : DateFormat(
                                          'MMM d',
                                        ).format(_selectedRecentDay!),
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.adaptiveTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                            tooltip: 'Filter recent memories',
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (_filteredVisualMemories.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.adaptiveCardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.adaptiveBorder),
                          ),
                          child: Text(
                            _selectedRecentDay == null
                                ? 'No memories in this album yet.'
                                : 'No memories on ${DateFormat('MMM d, y').format(_selectedRecentDay!)}.',
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              color: AppTheme.adaptiveTextSecondary,
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredVisualMemories.length,
                          itemBuilder: (context, index) {
                            final memory = _filteredVisualMemories[index];
                            return InlineMemoryCard(
                              memory: memory,
                              onTap: () => _openMemoryDetail(memory),
                              memoryDate: _memoryDate(memory),
                            );
                          },
                          separatorBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Divider(
                                color: Colors.grey.withValues(alpha: 0.35),
                                height: 1,
                                thickness: 1.5,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumHeader() {
    final coverImageUrl = _album['coverImageUrl']?.toString();
    final title = _album['title']?.toString() ?? 'Album';
    final subtitle = _album['subtitle']?.toString().trim().isNotEmpty == true
        ? _album['subtitle'].toString()
        : 'A gallery of moments collected inside one memory chapter.';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            width: 160,
            height: 180,
            child: coverImageUrl != null && coverImageUrl.isNotEmpty
                ? Image.network(
                    coverImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildFallbackCover(),
                  )
                : _buildFallbackCover(),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.adaptiveTextPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  height: 1.4,
                  color: AppTheme.adaptiveTextSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Divider(color: AppTheme.adaptiveDivider, height: 1),
              const SizedBox(height: 12),
              _buildHeaderPill(
                icon: Icons.collections_bookmark_rounded,
                label: '${_memories.length} memories',
              ),
              const SizedBox(height: 8),
              _buildHeaderPill(
                icon: Icons.schedule_rounded,
                label: _albumDateLabel(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackCover() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111827), Color(0xFF1F2937), Color(0xFF4B5563)],
        ),
      ),
    );
  }

  Widget _buildHeaderPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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

  String _albumDateLabel() {
    final dateRaw =
        _album['createdAt']?.toString() ??
        _album['updatedAt']?.toString() ??
        '';
    try {
      if (dateRaw.isNotEmpty) {
        final parsed = DateTime.parse(dateRaw).toLocal();
        return DateFormat('MMM d, yyyy').format(parsed);
      }
    } catch (_) {}
    return 'Recently';
  }
}

class _AddMemorySheet extends StatelessWidget {
  const _AddMemorySheet({this.albumTitle});

  final String? albumTitle;

  @override
  Widget build(BuildContext context) {
    final options = [
      (
        format: RecordStoryFormat.photoText,
        icon: Icons.photo_library_outlined,
        title: 'Photo memory',
        subtitle: 'Add an image with context and keep the moment anchored.',
      ),
      (
        format: RecordStoryFormat.video,
        icon: Icons.videocam_outlined,
        title: 'Video memory',
        subtitle: 'Keep movement, presence, and atmosphere together.',
      ),
      (
        format: RecordStoryFormat.voice,
        icon: Icons.mic_none_rounded,
        title: 'Voice memory',
        subtitle: 'Capture how it sounded and how it felt.',
      ),
      (
        format: RecordStoryFormat.text,
        icon: Icons.edit_note_rounded,
        title: 'Text memory',
        subtitle: 'Write the details when words matter most.',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.adaptiveDivider,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Add memory',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.adaptiveTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  albumTitle?.trim().isNotEmpty == true
                      ? 'Choose a format for ${albumTitle!.trim()}.'
                      : 'Choose a format to continue.',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    height: 1.5,
                    color: AppTheme.adaptiveTextSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompactLayout = constraints.maxWidth < 380;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: options.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        mainAxisExtent: isCompactLayout ? 84 : 104,
                      ),
                      itemBuilder: (context, index) {
                        final option = options[index];
                        return InkWell(
                          onTap: () => Navigator.of(context).pop(option.format),
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            padding: EdgeInsets.fromLTRB(
                              isCompactLayout ? 10 : 12,
                              isCompactLayout ? 10 : 12,
                              isCompactLayout ? 10 : 12,
                              isCompactLayout ? 8 : 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.adaptiveCardBg,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: AppTheme.adaptiveBorder,
                              ),
                            ),
                            child: isCompactLayout
                                ? Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF5D5FEF,
                                          ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          option.icon,
                                          color: const Color(0xFF5D5FEF),
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          option.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            height: 1.15,
                                            color: AppTheme.adaptiveTextPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF5D5FEF,
                                          ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          option.icon,
                                          color: const Color(0xFF5D5FEF),
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        option.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.adaptiveTextPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        option.subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          height: 1.2,
                                          color: AppTheme.adaptiveTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentFilterSelection {
  const _RecentFilterSelection(this.day);

  final DateTime? day;
}

class _RecentFilterSheet extends StatelessWidget {
  const _RecentFilterSheet({required this.memories, required this.selectedDay});

  final List<Map<String, dynamic>> memories;
  final DateTime? selectedDay;

  DateTime? _resolveDate(Map<String, dynamic> memory) {
    final candidates = [
      memory['date'], // Backend uses 'date'
      memory['dateRaw'],
      memory['occurredAt'],
      memory['createdAt'],
      memory['updatedAt'],
    ];

    for (final candidate in candidates) {
      final parsed = DateTime.tryParse(candidate?.toString() ?? '');
      if (parsed != null) return parsed.toLocal();
    }
    return null;
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  List<_RecentCalendarMonth> _buildMonths() {
    final buckets = <DateTime, Map<int, Map<String, dynamic>>>{};

    for (final memory in memories) {
      final date = _resolveDate(memory);
      if (date == null) continue;

      final monthKey = DateTime(date.year, date.month);
      final dayMap = buckets.putIfAbsent(
        monthKey,
        () => <int, Map<String, dynamic>>{},
      );
      dayMap.putIfAbsent(date.day, () => memory);
    }

    final entries = buckets.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return entries
        .map(
          (entry) => _RecentCalendarMonth(
            month: entry.key,
            memoriesByDay: entry.value,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final months = _buildMonths();
    const weekLabels = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    return FractionallySizedBox(
      heightFactor: 0.86,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.adaptiveDivider,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Filter recent',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.adaptiveTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pick a day from your album calendar to narrow the recent grid.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    height: 1.35,
                    color: AppTheme.adaptiveTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(const _RecentFilterSelection(null)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.adaptiveTextPrimary,
                      backgroundColor: AppTheme.adaptiveSoftSurface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    icon: const Icon(Icons.grid_view_rounded, size: 16),
                    label: Text(
                      'Show all',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: months.isEmpty
                        ? Text(
                            'No calendar memories available yet.',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppTheme.adaptiveTextSecondary,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: months.map((monthData) {
                              final daysInMonth = DateUtils.getDaysInMonth(
                                monthData.month.year,
                                monthData.month.month,
                              );
                              final firstDay = DateTime(
                                monthData.month.year,
                                monthData.month.month,
                                1,
                              );
                              final leadingEmpty = firstDay.weekday % 7;
                              final totalCells = leadingEmpty + daysInMonth;
                              final paddedCells = ((totalCells + 6) ~/ 7) * 7;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat(
                                        'MMMM y',
                                      ).format(monthData.month),
                                      style: GoogleFonts.outfit(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.adaptiveTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: weekLabels
                                          .map(
                                            (label) => Expanded(
                                              child: Center(
                                                child: Text(
                                                  label,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme
                                                        .adaptiveTextSecondary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                    const SizedBox(height: 10),
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: paddedCells,
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 7,
                                            crossAxisSpacing: 8,
                                            mainAxisSpacing: 10,
                                            mainAxisExtent: 42,
                                          ),
                                      itemBuilder: (context, index) {
                                        final dayNumber =
                                            index - leadingEmpty + 1;
                                        if (dayNumber < 1 ||
                                            dayNumber > daysInMonth) {
                                          return const SizedBox.shrink();
                                        }

                                        final memory =
                                            monthData.memoriesByDay[dayNumber];
                                        final thisDay = DateTime(
                                          monthData.month.year,
                                          monthData.month.month,
                                          dayNumber,
                                        );
                                        final isSelected =
                                            selectedDay != null &&
                                            _isSameDay(selectedDay!, thisDay);

                                        if (memory == null) {
                                          return InkWell(
                                            onTap: () =>
                                                Navigator.of(context).pop(
                                                  _RecentFilterSelection(
                                                    thisDay,
                                                  ),
                                                ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: isSelected
                                                    ? Border.all(
                                                        color: const Color(
                                                          0xFF63E6E2,
                                                        ),
                                                        width: 1.5,
                                                      )
                                                    : null,
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                '$dayNumber',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme
                                                      .adaptiveTextSecondary,
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        final mediaUrl =
                                            memory['mediaUrl']?.toString() ??
                                            '';
                                        return InkWell(
                                          onTap: () =>
                                              Navigator.of(context).pop(
                                                _RecentFilterSelection(thisDay),
                                              ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isSelected
                                                    ? const Color(0xFF63E6E2)
                                                    : Colors.transparent,
                                                width: 2,
                                              ),
                                            ),
                                            padding: const EdgeInsets.all(2),
                                            child: ClipOval(
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  if (mediaUrl.isNotEmpty)
                                                    Image.network(
                                                      mediaUrl,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) => Container(
                                                            color: AppTheme
                                                                .adaptiveCardBg,
                                                          ),
                                                    )
                                                  else
                                                    Container(
                                                      color: AppTheme
                                                          .adaptiveCardBg,
                                                    ),
                                                  DecoratedBox(
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.18,
                                                          ),
                                                    ),
                                                  ),
                                                  Center(
                                                    child: Text(
                                                      '$dayNumber',
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentCalendarMonth {
  const _RecentCalendarMonth({
    required this.month,
    required this.memoriesByDay,
  });

  final DateTime month;
  final Map<int, Map<String, dynamic>> memoriesByDay;
}

class _QuickPhotoMemoryDraft {
  const _QuickPhotoMemoryDraft({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}

class _QuickPhotoMemorySheet extends StatefulWidget {
  const _QuickPhotoMemorySheet({required this.photoFile, this.albumTitle});

  final File photoFile;
  final String? albumTitle;

  @override
  State<_QuickPhotoMemorySheet> createState() => _QuickPhotoMemorySheetState();
}

class _QuickPhotoMemorySheetState extends State<_QuickPhotoMemorySheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Photo memory';
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
      _QuickPhotoMemoryDraft(
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
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.adaptiveDivider,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Finish photo memory',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.adaptiveTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.albumTitle?.trim().isNotEmpty == true
                        ? 'Give this photo a title and a short note for ${widget.albumTitle!.trim()}.'
                        : 'Add a title and a short note, then save it straight into the album.',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      height: 1.35,
                      color: AppTheme.adaptiveTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Image.file(widget.photoFile, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                    maxLines: 2,
                    minLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Short note',
                      hintText: 'What makes this worth keeping?',
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
                        'Add memory',
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
