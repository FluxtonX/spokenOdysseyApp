import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/album_service.dart';
import '../../theme/theme.dart';
import '../../utils/image_picker_helper.dart';
import '../albums/album_detail_screen.dart';

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  final AlbumService _albumService = AlbumService();
  final List<Map<String, dynamic>> _albums = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAlbums();
    });
  }

  Future<void> _loadAlbums({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final albums = await _albumService.fetchAlbums(
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;

      albums.sort(
        (a, b) => (b['updatedAt']?.toString() ?? '').compareTo(
          a['updatedAt']?.toString() ?? '',
        ),
      );

      setState(() {
        _albums
          ..clear()
          ..addAll(albums);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _showCreateAlbumSheet() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final createdAlbum = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateAlbumSheet(onCreateAlbum: _createAlbum),
    );

    if (createdAlbum == null || !mounted) return;

    setState(() {
      _albums.removeWhere(
        (album) => album['id']?.toString() == createdAlbum['id']?.toString(),
      );
      _albums.insert(0, createdAlbum);
    });

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          createdAlbum['coverUploadWarning'] != null
              ? 'Album created. Cover could not be uploaded.'
              : 'Album created.',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: createdAlbum['coverUploadWarning'] != null
            ? const Color(0xFFE2923A)
            : const Color(0xFF5ABA82),
      ),
    );
  }

  Future<Map<String, dynamic>> _createAlbum({
    required String title,
    required String subtitle,
    File? coverImage,
  }) {
    return _albumService.createAlbum(
      title: title,
      subtitle: subtitle,
      coverImage: coverImage,
    );
  }

  Future<void> _openAlbum(Map<String, dynamic> album) async {
    final result = await Get.to<Map<String, dynamic>>(
      () => AlbumDetailScreen(album: album),
      transition: Transition.cupertino,
    );

    if (!mounted || result == null) return;

    final action = result['action']?.toString();
    final updatedAlbumRaw = result['album'];
    if (action == 'updated' && updatedAlbumRaw is Map) {
      final updatedAlbum = Map<String, dynamic>.from(updatedAlbumRaw);
      setState(() {
        final index = _albums.indexWhere(
          (item) => item['id']?.toString() == updatedAlbum['id']?.toString(),
        );
        if (index == -1) {
          _albums.insert(0, updatedAlbum);
        } else {
          _albums[index] = updatedAlbum;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadAlbums(forceRefresh: true),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
        children: [
          _buildHeroHeader(),
          const SizedBox(height: 24),
          ...List.generate(3, (_) => _buildLoadingCard()),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
        children: [
          _buildHeroHeader(),
          const SizedBox(height: 32),
          _buildFeedbackCard(
            title: 'We could not load your albums',
            subtitle: _errorMessage!,
            actionLabel: 'Try Again',
            onPressed: () => _loadAlbums(forceRefresh: true),
          ),
        ],
      );
    }

    if (_albums.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
        children: [
          _buildHeroHeader(),
          const SizedBox(height: 32),
          _buildFeedbackCard(
            title: 'No albums yet',
            subtitle:
                'Create your first album, give it a strong cover, and start collecting memories in one place.',
            actionLabel: 'Create Album',
            onPressed: _showCreateAlbumSheet,
          ),
        ],
      );
    }

    final groupedAlbums = _groupAlbumsByMonth(_albums);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: [
        _buildHeroHeader(),
        const SizedBox(height: 28),
        ...groupedAlbums.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.adaptiveTextPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                ...entry.value.map(
                  (album) => Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: _buildEditorialAlbumCard(album),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF111827),
            const Color(0xFF1F2937),
            const Color(0xFF0F172A).withValues(alpha: 0.96),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Albums',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Build visual chapters for the memories you want to keep close, revisit, and share with care.',
                      style: GoogleFonts.outfit(
                        fontSize: 14.5,
                        height: 1.55,
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              IconButton.filled(
                onPressed: _showCreateAlbumSheet,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF5D5FEF),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildHeroBadge(
                icon: Icons.cloud_done_rounded,
                label: 'Cloud only',
              ),
              _buildHeroBadge(
                icon: Icons.collections_bookmark_rounded,
                label: '${_albums.length} albums',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBadge({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorialAlbumCard(Map<String, dynamic> album) {
    final createdAt = DateTime.tryParse(
      album['createdAt']?.toString() ?? album['updatedAt']?.toString() ?? '',
    );
    final dayLabel = createdAt != null
        ? DateFormat('MMM d').format(createdAt).toUpperCase()
        : 'ARCHIVE';

    return GestureDetector(
      onTap: () => _openAlbum(album),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.adaptiveCardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(aspectRatio: 1.16, child: _buildAlbumCover(album)),
              Container(
                width: double.infinity,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF14161C)
                    : const Color(0xFF1B1B1F),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: Colors.white.withValues(alpha: 0.62),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      album['title']?.toString() ?? 'Untitled album',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      album['subtitle']?.toString().trim().isNotEmpty == true
                          ? album['subtitle'].toString()
                          : 'A curated group of moments held together in one archive chapter.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        height: 1.45,
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildMetaPill(
                          icon: Icons.photo_library_outlined,
                          label:
                              '${album['entries'] ?? (album['memories'] as List?)?.length ?? 0} memories',
                        ),
                        const SizedBox(width: 10),
                        _buildMetaPill(
                          icon: Icons.schedule_rounded,
                          label: _albumDateLabel(album),
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

  Widget _buildAlbumCover(Map<String, dynamic> album) {
    final coverImageUrl = album['coverImageUrl']?.toString();
    if (coverImageUrl != null && coverImageUrl.isNotEmpty) {
      return Image.network(
        coverImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackCover(album['title']?.toString()),
      );
    }

    return _buildFallbackCover(album['title']?.toString());
  }

  String _albumDateLabel(Map<String, dynamic> album) {
    final rawDate =
        album['updatedAt']?.toString() ?? album['createdAt']?.toString() ?? '';
    final parsedDate = DateTime.tryParse(rawDate);
    if (parsedDate == null) return 'Recent';
    return DateFormat('MMM d, y').format(parsedDate);
  }

  Widget _buildFallbackCover(String? title) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F2937), Color(0xFF374151), Color(0xFF6B7280)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -20,
            right: -8,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 18,
            left: 18,
            right: 18,
            child: Text(
              title?.isNotEmpty == true ? title! : 'New album',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard({
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.adaptiveCardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.adaptiveBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF5D5FEF).withValues(alpha: 0.08),
            ),
            child: const Icon(
              Icons.collections_bookmark_outlined,
              color: Color(0xFF5D5FEF),
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppTheme.adaptiveTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.55,
              color: AppTheme.adaptiveTextSecondary,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5D5FEF),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            child: Text(
              actionLabel,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: AppTheme.adaptiveCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.adaptiveBorder),
      ),
      child: Column(
        children: [
          Container(
            height: 280,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE8D7C2).withValues(alpha: 0.5),
                  const Color(0xFFC7D2FE).withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skeletonLine(widthFactor: 0.2),
                const SizedBox(height: 10),
                _skeletonLine(widthFactor: 0.5, height: 22),
                const SizedBox(height: 8),
                _skeletonLine(widthFactor: 0.8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonLine({required double widthFactor, double height = 14}) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.adaptiveDivider,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupAlbumsByMonth(
    List<Map<String, dynamic>> albums,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final album in albums) {
      final rawDate =
          album['createdAt']?.toString() ??
          album['updatedAt']?.toString() ??
          '';
      final parsedDate = DateTime.tryParse(rawDate);
      final key = parsedDate != null
          ? DateFormat('MMMM yyyy').format(parsedDate)
          : 'Recent';
      grouped.putIfAbsent(key, () => []).add(album);
    }

    return grouped;
  }
}

class _CreateAlbumSheet extends StatefulWidget {
  const _CreateAlbumSheet({required this.onCreateAlbum});

  final Future<Map<String, dynamic>> Function({
    required String title,
    required String subtitle,
    File? coverImage,
  })
  onCreateAlbum;

  @override
  State<_CreateAlbumSheet> createState() => _CreateAlbumSheetState();
}

class _CreateAlbumSheetState extends State<_CreateAlbumSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  File? _coverImage;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final image = await ImagePickerHelper.pickWithSourceSheet(
      context,
      imageQuality: 92,
      maxWidth: 2200,
    );

    if (image == null || !mounted) return;
    setState(() {
      _coverImage = image;
    });
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final album = await widget.onCreateAlbum(
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim(),
        coverImage: _coverImage,
      );

      if (!mounted) return;
      Navigator.of(context).pop(album);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.72,
        maxChildSize: 0.92,
        builder: (context, controller) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                child: Form(
                  key: _formKey,
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
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Create a new album',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 31,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.adaptiveTextPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Design a strong cover, name it beautifully, and start grouping memories in one place.',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          height: 1.55,
                          color: AppTheme.adaptiveTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 22),
                      AspectRatio(
                        aspectRatio: 1.08,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: _coverImage != null
                              ? Image.file(_coverImage!, fit: BoxFit.cover)
                              : Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF1F2937),
                                        Color(0xFF374151),
                                        Color(0xFF6B7280),
                                      ],
                                    ),
                                  ),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Positioned(
                                        top: 18,
                                        right: 18,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.16,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Text(
                                            'Cover Preview',
                                            style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 18,
                                        right: 18,
                                        bottom: 18,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Memory album',
                                              style:
                                                  GoogleFonts.playfairDisplay(
                                                    fontSize: 34,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Gather a chapter of images, voice notes, videos, and text in one place.',
                                              style: GoogleFonts.outfit(
                                                fontSize: 14,
                                                height: 1.45,
                                                color: Colors.white.withValues(
                                                  alpha: 0.8,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _pickCover,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(
                            _coverImage == null
                                ? 'Choose Cover'
                                : 'Change Cover',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Album title',
                          hintText: 'Wedding day',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an album title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _subtitleController,
                        textInputAction: TextInputAction.done,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText:
                              'A life-changing day filled with love, memory, and everyone who mattered.',
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5D5FEF),
                            minimumSize: const Size.fromHeight(56),
                          ),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome_rounded),
                          label: Text(
                            _isSaving ? 'Creating...' : 'Create Album',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
