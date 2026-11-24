import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../cubit/glasses_cubit.dart';
import '../cubit/glasses_state.dart';
import '../pages/smart_glasses_media_viewer.dart';
import '../../domain/entities/glasses_media_item.dart';
import 'glasses_import_loader.dart';
import 'glasses_media_tile.dart';
import 'glasses_wifi_disconnect_card.dart';

/// Live status of a media import from the glasses (progress, success, failure).
class GlassesImportBanner extends StatelessWidget {
  final EdgeInsetsGeometry margin;

  const GlassesImportBanner({super.key, this.margin = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GlassesCubit, GlassesState>(
      buildWhen: (a, b) =>
          a.importPhase != b.importPhase ||
          a.importStatusText != b.importStatusText ||
          a.importFileProgress != b.importFileProgress ||
          a.importIndex != b.importIndex ||
          a.importTotal != b.importTotal ||
          a.wifiSpeed != b.wifiSpeed ||
          a.importSessionCount != b.importSessionCount ||
          a.importSkippedCount != b.importSkippedCount ||
          a.importNeedsWifiDisconnect != b.importNeedsWifiDisconnect ||
          a.recentImports != b.recentImports,
      builder: (context, state) {
        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: state.importPhase == GlassesImportPhase.idle
                ? const SizedBox(width: double.infinity, key: ValueKey('idle'))
                : Padding(
                    key: ValueKey(
                      '${state.importPhase}-${state.importNeedsWifiDisconnect}',
                    ),
                    padding: margin,
                    child: _content(context, state),
                  ),
          ),
        );
      },
    );
  }

  Widget _content(BuildContext context, GlassesState state) {
    final cubit = context.read<GlassesCubit>();
    switch (state.importPhase) {
      case GlassesImportPhase.connecting:
      case GlassesImportPhase.downloading:
        if (state.importNeedsWifiDisconnect) {
          return GlassesWifiDisconnectCard(onStop: () => _confirmStop(context));
        }
        return GlassesImportLoader(
          state: state,
          onStop: () => _confirmStop(context),
        );
      case GlassesImportPhase.completed:
        // Count from what was actually saved so the title always matches the thumbnails.
        final saved = state.recentImports.length;
        final skipped = state.importSkippedCount;
        final doneTitle = saved > 0
            ? 'Imported $saved new ${saved == 1 ? 'item' : 'items'}'
                  '${skipped > 0 ? ' · $skipped couldn\'t be saved' : ''}'
            : state.importStatusText;
        return _ResultCard(
          color: AppColors.success,
          icon: Icons.check_circle_rounded,
          title: doneTitle,
          subtitle: state.recentImports.isEmpty
              ? 'Your Glasses library is up to date'
              : 'Saved on this phone · tap to view',
          actionLabel: 'Done',
          onAction: cubit.resetImportStatus,
          footer: state.recentImports.isEmpty
              ? null
              : _RecentImportsStrip(items: state.recentImports),
        );
      case GlassesImportPhase.failed:
        return _ResultCard(
          color: AppColors.error,
          icon: Icons.error_rounded,
          title: 'Import didn\'t finish',
          subtitle: state.importStatusText,
          actionLabel: 'Retry',
          onAction: cubit.importAlbum,
          onDismiss: cubit.resetImportStatus,
        );
      case GlassesImportPhase.idle:
        return const SizedBox.shrink();
    }
  }
}

Future<void> _confirmStop(BuildContext context) async {
  final cubit = context.read<GlassesCubit>();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Stop importing?',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
      ),
      content: Text(
        'Items already downloaded stay on this phone. The rest stay on your glasses for next time.',
        style: GoogleFonts.outfit(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'Keep going',
            style: GoogleFonts.outfit(color: AppColors.textSecondary),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text(
            'Stop',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
  if (ok == true) cubit.cancelImport();
}

class _ResultCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback? onDismiss;
  final Widget? footer;

  const _ResultCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    this.onDismiss,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.3, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (_, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(foregroundColor: color),
                child: Text(
                  actionLabel,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  tooltip: 'Dismiss',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDismiss,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: 12),
            Padding(padding: const EdgeInsets.only(right: 6), child: footer!),
          ],
        ],
      ),
    );
  }
}

/// Thumbnails of what the last import brought in; tap one to open it.
class _RecentImportsStrip extends StatelessWidget {
  final List<GlassesMediaItem> items;

  const _RecentImportsStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    final media = items;
    const maxShown = 5;
    final shown = media.take(maxShown).toList();
    final extra = media.length - shown.length;
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          for (int i = 0; i < shown.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GlassesMediaTile(
                    item: shown[i],
                    radius: 12,
                    onTap: () => SmartGlassesMediaViewer.open(
                      context,
                      items: media,
                      initialIndex: i,
                    ),
                  ),
                  if (i == shown.length - 1 && extra > 0)
                    IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '+$extra',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
