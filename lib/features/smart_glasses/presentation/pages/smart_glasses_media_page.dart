import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/glasses_media_item.dart';
import '../cubit/glasses_cubit.dart';
import '../cubit/glasses_state.dart';
import '../widgets/glasses_import_banner.dart';
import '../widgets/glasses_media_tile.dart';
import '../widgets/glasses_visuals.dart';
import 'smart_glasses_media_viewer.dart';

enum _MediaFilter { all, photos, videos, audio }

/// Library of everything imported from the smart glasses (saved on this phone).
class SmartGlassesMediaPage extends StatelessWidget {
  final bool startImport;

  const SmartGlassesMediaPage({super.key, this.startImport = false});

  static Future<void> open(BuildContext context, {bool startImport = false}) {
    final cubit = context.read<GlassesCubit>();
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: SmartGlassesMediaPage(startImport: startImport),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _MediaPageBody(startImport: startImport);
  }
}

class _MediaPageBody extends StatefulWidget {
  final bool startImport;

  const _MediaPageBody({required this.startImport});

  @override
  State<_MediaPageBody> createState() => _MediaPageBodyState();
}

class _MediaPageBodyState extends State<_MediaPageBody> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<GlassesCubit>();
    cubit.loadLocalMedia();
    if (widget.startImport) {
      WidgetsBinding.instance.addPostFrameCallback((_) => cubit.importAlbum());
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _MediaFilter.values.length,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: BlocConsumer<GlassesCubit, GlassesState>(
          listenWhen: (a, b) => a.noticeId != b.noticeId,
          listener: (context, state) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.notice)));
          },
          builder: (context, state) {
            final media = state.importedMedia;
            return NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppColors.surface,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    tooltip: 'Back',
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  titleSpacing: 0,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Glasses Library',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${media.length} ${media.length == 1 ? 'item' : 'items'} saved on this phone',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: FilledButton.icon(
                        onPressed: state.isConnected && !state.isImporting
                            ? context.read<GlassesCubit>().importAlbum
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.indicatorInactive,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          minimumSize: const Size(0, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: Text(
                          'Import',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(58),
                    child: _FilterTabs(state: state),
                  ),
                ),
              ],
              body: Column(
                children: [
                  const GlassesImportBanner(
                    margin: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  ),
                  if (!state.isConnected && media.isNotEmpty)
                    const _OfflineHint(),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _MediaGrid(
                          items: media,
                          filter: _MediaFilter.all,
                          state: state,
                        ),
                        _MediaGrid(
                          items: state.photos,
                          filter: _MediaFilter.photos,
                          state: state,
                        ),
                        _MediaGrid(
                          items: state.videos,
                          filter: _MediaFilter.videos,
                          state: state,
                        ),
                        _MediaGrid(
                          items: state.audios,
                          filter: _MediaFilter.audio,
                          state: state,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  final GlassesState state;

  const _FilterTabs({required this.state});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('All', state.importedMedia.length),
      ('Photos', state.photos.length),
      ('Videos', state.videos.length),
      ('Audio', state.audios.length),
    ];
    return Container(
      height: 46,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEAFB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A1B0F5C),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
        ),
        unselectedLabelStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
        ),
        labelPadding: EdgeInsets.zero,
        splashBorderRadius: BorderRadius.circular(11),
        tabs: [
          for (final (label, count) in tabs)
            Tab(
              height: 38,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label),
                    if (count > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '$count',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OfflineHint extends StatelessWidget {
  const _OfflineHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          const Icon(
            Icons.offline_pin_rounded,
            size: 16,
            color: AppColors.success,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Glasses not connected — your saved media is still available.',
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaGrid extends StatelessWidget {
  final List<GlassesMediaItem> items;
  final _MediaFilter filter;
  final GlassesState state;

  const _MediaGrid({
    required this.items,
    required this.filter,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GlassesCubit>();

    if (items.isEmpty) {
      if (state.isMediaLoading) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: cubit.loadLocalMedia,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [_EmptyState(filter: filter, state: state)],
        ),
      );
    }

    final groups = _groupByDay(items);
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: cubit.loadLocalMedia,
      child: CustomScrollView(
        key: PageStorageKey('glasses-media-${filter.name}'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          for (final group in groups) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text(
                      group.label,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${group.items.length}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (filter == _MediaFilter.audio)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: group.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _AudioRow(
                    item: group.items[i],
                    onTap: () => _openViewer(context, group.items[i]),
                    onLongPress: () =>
                        _showItemActions(context, group.items[i]),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemCount: group.items.length,
                  itemBuilder: (context, i) => GlassesMediaTile(
                    item: group.items[i],
                    onTap: () => _openViewer(context, group.items[i]),
                    onLongPress: () =>
                        _showItemActions(context, group.items[i]),
                  ),
                ),
              ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  void _openViewer(BuildContext context, GlassesMediaItem item) {
    SmartGlassesMediaViewer.open(
      context,
      items: items,
      initialIndex: items.indexOf(item),
    );
  }

  void _showItemActions(BuildContext context, GlassesMediaItem item) {
    final cubit = context.read<GlassesCubit>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.open_in_full_rounded,
                  color: AppColors.primary,
                ),
                title: Text(
                  'Open',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openViewer(context, item);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
                title: Text(
                  'Delete from this phone',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  if (await confirmGlassesMediaDelete(context)) {
                    cubit.deleteMedia(item);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioRow extends StatelessWidget {
  final GlassesMediaItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _AudioRow({
    required this.item,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEBFA)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice note',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, h:mm a').format(item.displayDate),
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  formatGlassesDuration(item.durationSeconds),
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final _MediaFilter filter;
  final GlassesState state;

  const _EmptyState({required this.filter, required this.state});

  @override
  Widget build(BuildContext context) {
    final (icon, title, body) = switch (filter) {
      _MediaFilter.all => (
        Icons.photo_library_outlined,
        'No media yet',
        'Photos, videos and voice notes you capture with your glasses will appear here after you import them.',
      ),
      _MediaFilter.photos => (
        Icons.photo_camera_outlined,
        'No photos yet',
        'Take a photo with your glasses, then import it to see it here.',
      ),
      _MediaFilter.videos => (
        Icons.videocam_outlined,
        'No videos yet',
        'Record a video with your glasses, then import it to watch it here.',
      ),
      _MediaFilter.audio => (
        Icons.mic_none_rounded,
        'No voice notes yet',
        'Record a voice note with your glasses, then import it to listen here.',
      ),
    };
    final cubit = context.read<GlassesCubit>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 56, 32, 32),
      child: Column(
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 46, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          if (state.isConnected)
            FilledButton.icon(
              onPressed: state.isImporting ? null : cubit.importAlbum,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(200, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.download_rounded),
              label: Text(
                'Import from glasses',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
            )
          else
            Text(
              'Connect your glasses to import media.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppColors.textLight,
              ),
            ),
        ],
      ),
    );
  }
}

class _DayGroup {
  final String label;
  final List<GlassesMediaItem> items;

  _DayGroup(this.label, this.items);
}

List<_DayGroup> _groupByDay(List<GlassesMediaItem> items) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final groups = <DateTime, List<GlassesMediaItem>>{};
  for (final item in items) {
    final d = item.displayDate;
    groups.putIfAbsent(DateTime(d.year, d.month, d.day), () => []).add(item);
  }
  final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final day in keys)
      _DayGroup(
        day == today
            ? 'Today'
            : day == today.subtract(const Duration(days: 1))
            ? 'Yesterday'
            : DateFormat(
                day.year == now.year ? 'EEE, d MMM' : 'd MMM yyyy',
              ).format(day),
        groups[day]!,
      ),
  ];
}

Future<bool> confirmGlassesMediaDelete(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Delete this item?',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
      ),
      content: Text(
        'It will be removed from this phone. This can\'t be undone.',
        style: GoogleFonts.outfit(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'Cancel',
            style: GoogleFonts.outfit(color: AppColors.textSecondary),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: Text(
            'Delete',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
