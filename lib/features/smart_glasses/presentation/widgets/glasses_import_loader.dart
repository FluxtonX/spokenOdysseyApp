import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../cubit/glasses_state.dart';
import 'glasses_visuals.dart';

/// Animated card shown while media is imported from the glasses:
/// a progress ring with ripples, a light sweep, and Connect → Transfer → Save steps.
class GlassesImportLoader extends StatefulWidget {
  final GlassesState state;
  final VoidCallback onStop;

  const GlassesImportLoader({
    super.key,
    required this.state,
    required this.onStop,
  });

  @override
  State<GlassesImportLoader> createState() => _GlassesImportLoaderState();
}

class _GlassesImportLoaderState extends State<GlassesImportLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// 0 = connecting, 1 = transferring, 2 = saving.
  int get _step {
    final s = widget.state;
    if (s.importPhase == GlassesImportPhase.connecting) return 0;
    if (s.importTotal > 0 &&
        s.importIndex >= s.importTotal &&
        s.importFileProgress >= 1) {
      return 2;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final progress = s.importOverallProgress;
    final step = _step;
    final percent = progress == null ? null : (progress * 100).round();

    final title = switch (step) {
      0 => 'Connecting to your glasses',
      1 => 'Importing your media',
      _ => 'Saving to your phone',
    };
    final subtitle = switch (step) {
      0 => 'Opening a private Wi‑Fi link…',
      1 =>
        s.importTotal > 0
            ? 'File ${s.importIndex.clamp(1, s.importTotal)} of ${s.importTotal}'
            : 'Preparing your files…',
      _ => 'Almost done',
    };

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B4AFF), Color(0xFF4825E2), Color(0xFF2C0FBB)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.32),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Moving light sweep.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, _) => LayoutBuilder(
                  builder: (_, box) {
                    final w = box.maxWidth;
                    final x = -w * 0.6 + _c.value * w * 2.2;
                    return Stack(
                      children: [
                        Positioned(
                          left: x,
                          top: -20,
                          bottom: -20,
                          width: w * 0.5,
                          child: Transform.rotate(
                            angle: 0.35,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0),
                                    Colors.white.withValues(alpha: 0.09),
                                    Colors.white.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: AnimatedBuilder(
                        animation: _c,
                        builder: (_, _) => CustomPaint(
                          painter: _RingPainter(
                            t: _c.value,
                            progress: step == 0 ? null : progress,
                          ),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: percent != null && step != 0
                                  ? Text(
                                      '$percent%',
                                      key: const ValueKey('pct'),
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    )
                                  : Transform.scale(
                                      key: const ValueKey('glyph'),
                                      scale:
                                          1 +
                                          0.06 *
                                              math.sin(_c.value * 2 * math.pi),
                                      child: const GlassesGlyph(size: 42),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Text(
                              title,
                              key: ValueKey(title),
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 13.5,
                            ),
                          ),
                          if (s.wifiSpeed.isNotEmpty &&
                              !s.wifiSpeed.startsWith('0 ')) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.speed_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    s.wifiSpeed,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Steps(step: step, pulse: _c),
                if (s.importCurrentFile.isNotEmpty && step == 1) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.insert_drive_file_outlined,
                        color: Colors.white60,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          s.importCurrentFile,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: widget.onStop,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.14),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.stop_rounded, size: 18),
                    label: Text(
                      'Stop',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress ring with expanding ripples
// ─────────────────────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double t; // 0..1 looping
  final double? progress; // null = indeterminate

  _RingPainter({required this.t, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 8;

    // Ripples
    for (int i = 0; i < 2; i++) {
      final k = (t + i / 2) % 1.0;
      final r = radius + 2 + k * 10;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = Colors.white.withValues(alpha: (1 - k) * 0.28),
      );
    }

    // Inner disc
    canvas.drawCircle(
      center,
      radius - 6,
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );

    // Track
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = Colors.white.withValues(alpha: 0.18),
    );

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;

    if (progress == null) {
      // Comet: a rotating arc that fades towards its tail.
      final start = t * 2 * math.pi - math.pi / 2;
      arc.shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 1.2,
        colors: [Colors.white.withValues(alpha: 0), Colors.white],
        transform: GradientRotation(start),
      ).createShader(rect);
      canvas.drawArc(rect, start, math.pi * 1.2, false, arc);
    } else {
      final sweep = (progress!.clamp(0.0, 1.0)) * 2 * math.pi;
      canvas.drawArc(rect, -math.pi / 2, math.max(sweep, 0.001), false, arc);
      // Glowing head
      final angle = -math.pi / 2 + sweep;
      final head = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawCircle(
        head,
        7,
        Paint()..color = Colors.white.withValues(alpha: 0.28),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.t != t || old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Connect → Transfer → Save
// ─────────────────────────────────────────────────────────────────────────────
class _Steps extends StatelessWidget {
  final int step;
  final Animation<double> pulse;

  const _Steps({required this.step, required this.pulse});

  @override
  Widget build(BuildContext context) {
    const labels = ['Connect', 'Transfer', 'Save'];
    return Row(
      children: [
        for (int i = 0; i < 3; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: i <= step ? 0.7 : 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          _StepDot(
            label: labels[i],
            done: i < step,
            active: i == step,
            pulse: pulse,
          ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final String label;
  final bool done;
  final bool active;
  final Animation<double> pulse;

  const _StepDot({
    required this.label,
    required this.done,
    required this.active,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: pulse,
          builder: (_, _) {
            final glow = active
                ? (0.5 + 0.5 * math.sin(pulse.value * 2 * math.pi))
                : 0.0;
            return Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done || active
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.18),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.35 * glow),
                          blurRadius: 10,
                          spreadRadius: 2 * glow,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: done
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppColors.primary,
                    )
                  : active
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            );
          },
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: done || active ? 1 : 0.55),
            fontSize: 11.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
