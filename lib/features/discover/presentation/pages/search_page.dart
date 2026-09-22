import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/media_url_formatter.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../memories/domain/entities/memory_entity.dart';
import '../../../albums/domain/entities/album_entity.dart';
import '../../../memories/presentation/pages/memory_detail_page.dart';
import '../../../albums/presentation/pages/album_detail_page.dart';
import '../../../profile/presentation/pages/public_profile_page.dart';
import '../cubits/search_cubit.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SearchCubit>(
      create: (_) => sl<SearchCubit>(),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFFFAF9FD),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            titleSpacing: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: _SearchBar(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: (q) => context.read<SearchCubit>().search(q),
            ),
          ),
          body: BlocBuilder<SearchCubit, SearchState>(
            builder: (context, state) {
              if (state is SearchInitial) {
                return _EmptyHint();
              }
              if (state is SearchLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (state is SearchError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      state.message,
                      style: GoogleFonts.outfit(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (state is SearchLoaded) {
                return Column(
                  children: [
                    _TabBar(
                      activeTab: state.activeTab,
                      onTabChanged: (t) =>
                          context.read<SearchCubit>().setTab(t),
                      totalCount: state.totalCount,
                    ),
                    Expanded(
                      child: _SearchResults(
                        state: state,
                        query: _searchController.text,
                        onToggleFollow: (u) =>
                            context.read<SearchCubit>().toggleFollow(u),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

// ── Search Bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        style: GoogleFonts.outfit(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: 'Search memories, albums, people…',
          hintStyle: GoogleFonts.outfit(
            color: AppColors.textLight,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textLight,
            size: 22,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textLight,
                    size: 20,
                  ),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF3F0FF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

// ── Tab Bar ───────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onTabChanged;
  final int totalCount;

  const _TabBar({
    required this.activeTab,
    required this.onTabChanged,
    required this.totalCount,
  });

  static const _tabs = ['All', 'Memories', 'Albums', 'People'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              '$totalCount matching items',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: _tabs.map((tab) {
                final isActive = activeTab == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onTabChanged(tab),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tab,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isActive ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),
        ],
      ),
    );
  }
}

// ── Search Results ────────────────────────────────────────────────────────────

class _SearchResults extends StatelessWidget {
  final SearchLoaded state;
  final String query;
  final ValueChanged<User> onToggleFollow;

  const _SearchResults({
    required this.state,
    required this.query,
    required this.onToggleFollow,
  });

  @override
  Widget build(BuildContext context) {
    final showMemories =
        state.activeTab == 'All' || state.activeTab == 'Memories';
    final showAlbums = state.activeTab == 'All' || state.activeTab == 'Albums';
    final showPeople = state.activeTab == 'All' || state.activeTab == 'People';

    final memoriesToShow = showMemories ? state.memories : <MemoryEntity>[];
    final albumsToShow = showAlbums ? state.albums : <AlbumEntity>[];
    final peopleToShow = showPeople ? state.people : <User>[];

    if (memoriesToShow.isEmpty &&
        albumsToShow.isEmpty &&
        peopleToShow.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords or adjust filters.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Memories Section
        if (memoriesToShow.isNotEmpty) ...[
          _SectionHeader(
            title: 'Memories',
            count: memoriesToShow.length,
            icon: Icons.mic_rounded,
          ),
          const SizedBox(height: 10),
          ...memoriesToShow.map(
            (m) => _MemoryResultCard(
              memory: m,
              query: query,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MemoryDetailPage(memoryId: m.id),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Albums Section
        if (albumsToShow.isNotEmpty) ...[
          _SectionHeader(
            title: 'Albums',
            count: albumsToShow.length,
            icon: Icons.photo_album_rounded,
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: albumsToShow.length,
            itemBuilder: (context, i) => _AlbumResultCard(
              album: albumsToShow[i],
              query: query,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlbumDetailPage(albumId: albumsToShow[i].id),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // People Section
        if (peopleToShow.isNotEmpty) ...[
          _SectionHeader(
            title: 'People',
            count: peopleToShow.length,
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 10),
          ...peopleToShow.map(
            (person) => _PersonResultCard(
              person: person,
              query: query,
              onToggleFollow: () => onToggleFollow(person),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PublicProfilePage(person: person),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Memory Result Card ────────────────────────────────────────────────────────

class _MemoryResultCard extends StatelessWidget {
  final MemoryEntity memory;
  final String query;
  final VoidCallback onTap;

  const _MemoryResultCard({
    required this.memory,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = MediaUrlFormatter.format(memory.mediaUrl);
    final date = memory.createdAt != null
        ? _formatDate(memory.createdAt!)
        : 'Recent';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderThumb(),
                    )
                  : _placeholderThumb(),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 11,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          date,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _HighlightText(
                      text: memory.title,
                      query: query,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (memory.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 3),
                      _HighlightText(
                        text: memory.description!,
                        query: query,
                        maxLines: 2,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textLight,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderThumb() => Container(
    width: 80,
    height: 80,
    color: AppColors.primary.withValues(alpha: 0.08),
    child: const Icon(Icons.mic_rounded, color: AppColors.primary, size: 28),
  );

  String _formatDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      final now = DateTime.now();
      final diff = now.difference(d).inDays;
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Yesterday';
      if (diff < 7) return '$diff days ago';
      if (diff < 30) return '${diff ~/ 7} weeks ago';
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return raw;
    }
  }
}

// ── Album Result Card ─────────────────────────────────────────────────────────

class _AlbumResultCard extends StatelessWidget {
  final AlbumEntity album;
  final String query;
  final VoidCallback onTap;

  const _AlbumResultCard({
    required this.album,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cover = MediaUrlFormatter.format(album.coverPhotoUrl);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: cover != null
                    ? Image.network(
                        cover,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HighlightText(
                    text: album.title,
                    query: query,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                  ),
                  Text(
                    '${album.memoriesCount} memories',
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
      ),
    );
  }

  Widget _placeholder() => Container(
    color: AppColors.primary.withValues(alpha: 0.08),
    child: const Center(
      child: Icon(
        Icons.photo_album_rounded,
        color: AppColors.primary,
        size: 32,
      ),
    ),
  );
}

// ── Person Result Card ────────────────────────────────────────────────────────

class _PersonResultCard extends StatelessWidget {
  final User person;
  final String query;
  final VoidCallback onToggleFollow;
  final VoidCallback onTap;

  const _PersonResultCard({
    required this.person,
    required this.query,
    required this.onToggleFollow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = MediaUrlFormatter.format(person.avatarUrl);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              backgroundImage: avatar != null ? NetworkImage(avatar) : null,
              child: avatar == null
                  ? Text(
                      (person.name?.isNotEmpty == true
                              ? person.name!
                              : person.email)
                          .substring(0, 1)
                          .toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HighlightText(
                    text: person.name ?? person.email,
                    query: query,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                  ),
                  if (person.location?.isNotEmpty == true)
                    Text(
                      person.location!,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            // Follow button
            GestureDetector(
              onTap: onToggleFollow,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: person.isFollowing
                      ? AppColors.borderLight
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  person.isFollowing ? 'Following' : 'Follow',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: person.isFollowing
                        ? AppColors.textPrimary
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty Hint ────────────────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_rounded,
            size: 72,
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Search your archive',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find memories, albums, and people',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Highlight Text ────────────────────────────────────────────────────────────

class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;
  final int maxLines;

  const _HighlightText({
    required this.text,
    required this.query,
    required this.style,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lowerText.indexOf(lowerQuery, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(
        TextSpan(
          text: text.substring(idx, idx + query.length),
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          ),
        ),
      );
      start = idx + query.length;
    }

    return RichText(
      text: TextSpan(style: style, children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
