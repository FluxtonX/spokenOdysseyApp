import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/album_service.dart';
import '../../services/memory_service.dart';
import '../../theme/theme.dart';
import '../albums/album_detail_screen.dart';
import '../memories/memory_detail_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key, required this.initialQuery});

  final String initialQuery;

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> with SingleTickerProviderStateMixin {
  final MemoryService _memoryService = MemoryService();
  final AlbumService _albumService = AlbumService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  List<Map<String, dynamic>> _memories = [];
  List<Map<String, dynamic>> _albums = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.text = widget.initialQuery;
    _performSearch(widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _memoryService.searchMemories(query),
        _albumService.searchAlbums(query),
      ]);

      if (mounted) {
        setState(() {
          _memories = results[0];
          _albums = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.adaptiveTextPrimary),
          onPressed: () => Get.back(),
        ),
        title: _buildSearchField(),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF5544FF),
          unselectedLabelColor: AppTheme.adaptiveTextSecondary,
          indicatorColor: const Color(0xFF5544FF),
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Memories'),
            Tab(text: 'Albums'),
          ],
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF5544FF)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAllResults(),
                _buildMemoriesList(),
                _buildAlbumsList(),
              ],
            ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: AppTheme.adaptiveSoftSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: false,
        textInputAction: TextInputAction.search,
        onSubmitted: _performSearch,
        decoration: InputDecoration(
          hintText: 'Search memories and albums...',
          hintStyle: GoogleFonts.outfit(color: AppTheme.adaptiveTextSecondary, fontSize: 14),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search_rounded, color: AppTheme.adaptiveTextSecondary, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, color: AppTheme.adaptiveTextSecondary, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: (val) => setState(() {}),
        style: GoogleFonts.outfit(color: AppTheme.adaptiveTextPrimary, fontSize: 14),
      ),
    );
  }

  Widget _buildAllResults() {
    if (_memories.isEmpty && _albums.isEmpty) return _buildEmptyState();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_memories.isNotEmpty) ...[
          _buildSectionHeader('Memories', _memories.length),
          ..._memories.take(3).map(_buildMemoryResultCard),
          if (_memories.length > 3)
            TextButton(
              onPressed: () => _tabController.animateTo(1),
              child: Text('View all memories', style: GoogleFonts.outfit(color: const Color(0xFF5544FF))),
            ),
          const SizedBox(height: 24),
        ],
        if (_albums.isNotEmpty) ...[
          _buildSectionHeader('Albums', _albums.length),
          ..._albums.take(3).map(_buildAlbumResultCard),
          if (_albums.length > 3)
            TextButton(
              onPressed: () => _tabController.animateTo(2),
              child: Text('View all albums', style: GoogleFonts.outfit(color: const Color(0xFF5544FF))),
            ),
        ],
      ],
    );
  }

  Widget _buildMemoriesList() {
    if (_memories.isEmpty) return _buildEmptyState();
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _memories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildMemoryResultCard(_memories[index]),
    );
  }

  Widget _buildAlbumsList() {
    if (_albums.isEmpty) return _buildEmptyState();
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _albums.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildAlbumResultCard(_albums[index]),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.adaptiveTextPrimary),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFF5544FF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(count.toString(), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF5544FF))),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryResultCard(Map<String, dynamic> memory) {
    final type = (memory['type'] ?? '').toLowerCase();
    final thumbnailUrl = memory['thumbnailUrl']?.toString() ?? '';
    final hasThumbnail = thumbnailUrl.isNotEmpty && (type == 'photo' || type == 'video');

    return GestureDetector(
      onTap: () => Get.to(() => MemoryDetailScreen(memory: memory)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.adaptiveCardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.adaptiveBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Row(
            children: [
              if (hasThumbnail)
                SizedBox(
                  width: 90,
                  height: 90,
                  child: Image.network(thumbnailUrl, fit: BoxFit.cover),
                )
              else
                Container(
                  width: 90,
                  height: 90,
                  color: const Color(0xFF5544FF).withValues(alpha: 0.08),
                  child: Icon(_getMemoryIcon(memory['type']), color: const Color(0xFF5544FF), size: 28),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        memory['title'] ?? 'Untitled',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.adaptiveTextPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        memory['description'] ?? 'No description',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.adaptiveTextSecondary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 12, color: AppTheme.adaptiveTextSecondary.withValues(alpha: 0.6)),
                          const SizedBox(width: 4),
                          Text(
                            memory['date'] ?? 'Recent',
                            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.adaptiveTextSecondary.withValues(alpha: 0.6)),
                          ),
                          const SizedBox(width: 12),
                          if (memory['albumTitle'] != null) ...[
                            Icon(Icons.collections_bookmark_rounded, size: 12, color: const Color(0xFF5ABA82)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                memory['albumTitle'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF5ABA82)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppTheme.adaptiveTextSecondary.withValues(alpha: 0.4)),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumResultCard(Map<String, dynamic> album) {
    final coverUrl = album['coverImageUrl']?.toString() ?? '';
    final hasCover = coverUrl.isNotEmpty;

    return GestureDetector(
      onTap: () => Get.to(() => AlbumDetailScreen(album: album)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.adaptiveCardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.adaptiveBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Row(
            children: [
              if (hasCover)
                SizedBox(
                  width: 90,
                  height: 90,
                  child: Image.network(coverUrl, fit: BoxFit.cover),
                )
              else
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF5ABA82).withValues(alpha: 0.2), const Color(0xFF5ABA82).withValues(alpha: 0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.collections_bookmark_rounded, color: Color(0xFF5ABA82), size: 28),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album['title'] ?? 'Untitled Album',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.adaptiveTextPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        album['subtitle'] ?? 'Archive chapter',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.adaptiveTextSecondary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.photo_library_outlined, size: 12, color: AppTheme.adaptiveTextSecondary.withValues(alpha: 0.6)),
                          const SizedBox(width: 4),
                          Text(
                            '${album['entries'] ?? 0} memories',
                            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.adaptiveTextSecondary.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppTheme.adaptiveTextSecondary.withValues(alpha: 0.4)),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: AppTheme.adaptiveTextSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.adaptiveTextPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords or check for typos.',
            style: GoogleFonts.outfit(color: AppTheme.adaptiveTextSecondary),
          ),
        ],
      ),
    );
  }

  IconData _getMemoryIcon(String? type) {
    final t = (type ?? '').toLowerCase();
    if (t.contains('voice')) return Icons.mic_none_rounded;
    if (t.contains('video')) return Icons.videocam_outlined;
    if (t.contains('photo')) return Icons.image_outlined;
    return Icons.notes_rounded;
  }
}
