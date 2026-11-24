import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';

/// Shared visual building blocks for the Smart Glasses screens.

// ─────────────────────────────────────────────────────────────────────────────
// Glasses glyph (drawn, since Material icons have no smart-glasses icon)
// ─────────────────────────────────────────────────────────────────────────────
class GlassesGlyph extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const GlassesGlyph({
    super.key,
    this.size = 32,
    this.color = Colors.white,
    this.strokeWidth = 2.4,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.5,
      child: CustomPaint(
        painter: _GlassesPainter(color: color, strokeWidth: strokeWidth),
      ),
    );
  }
}

class _GlassesPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _GlassesPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color.withValues(alpha: 0.18);

    final lensW = w * 0.36;
    final lensH = h * 0.72;
    final top = h * 0.2;
    final r = Radius.circular(lensH * 0.42);
    final left = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, top, lensW, lensH),
      r,
    );
    final right = RRect.fromRectAndRadius(
      Rect.fromLTWH(w - w * 0.08 - lensW, top, lensW, lensH),
      r,
    );
    canvas
      ..drawRRect(left, fill)
      ..drawRRect(right, fill)
      ..drawRRect(left, stroke)
      ..drawRRect(right, stroke);

    // Bridge
    final bridge = Path()
      ..moveTo(w * 0.08 + lensW, top + lensH * 0.32)
      ..quadraticBezierTo(
        w / 2,
        top - h * 0.02,
        w - w * 0.08 - lensW,
        top + lensH * 0.32,
      );
    canvas.drawPath(bridge, stroke);

    // Temples
    canvas
      ..drawLine(
        Offset(w * 0.08, top + lensH * 0.2),
        Offset(0, top + lensH * 0.05),
        stroke,
      )
      ..drawLine(
        Offset(w - w * 0.08, top + lensH * 0.2),
        Offset(w, top + lensH * 0.05),
        stroke,
      );

    // Camera dot
    canvas.drawCircle(
      Offset(w * 0.08 + lensW * 0.2, top + lensH * 0.08),
      strokeWidth * 0.55,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _GlassesPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

// ─────────────────────────────────────────────────────────────────────────────
// Scanning radar: expanding rings + rotating sweep around the glasses glyph
// ─────────────────────────────────────────────────────────────────────────────
class GlassesScanningRadar extends StatefulWidget {
  final double size;
  final bool active;
  final Color color;
  final Widget? center;

  const GlassesScanningRadar({
    super.key,
    this.size = 200,
    this.active = true,
    this.color = AppColors.primary,
    this.center,
  });

  @override
  State<GlassesScanningRadar> createState() => _GlassesScanningRadarState();
}

class _GlassesScanningRadarState extends State<GlassesScanningRadar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant GlassesScanningRadar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coreSize = widget.size * 0.38;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, _) => CustomPaint(
                size: Size.square(widget.size),
                painter: _RadarPainter(
                  progress: _controller.value,
                  color: widget.color,
                  active: widget.active,
                ),
              ),
            ),
          ),
          Container(
            width: coreSize,
            height: coreSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.color,
                  Color.lerp(widget.color, AppColors.accent, 0.6)!,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: widget.center ?? GlassesGlyph(size: coreSize * 0.56),
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool active;

  _RadarPainter({
    required this.progress,
    required this.color,
    required this.active,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.width / 2;
    final minR = maxR * 0.2;

    // Static guide rings
    final guide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: 0.10);
    for (final f in [0.45, 0.7, 0.95]) {
      canvas.drawCircle(center, maxR * f, guide);
    }
    if (!active) return;

    // Rotating sweep
    final sweepRect = Rect.fromCircle(center: center, radius: maxR * 0.95);
    final sweep = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi / 2,
        colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.28)],
        transform: GradientRotation(progress * 2 * math.pi),
      ).createShader(sweepRect);
    canvas.drawArc(sweepRect, progress * 2 * math.pi, math.pi / 2, true, sweep);

    // Expanding pulse rings
    for (int i = 0; i < 3; i++) {
      final t = (progress + i / 3) % 1.0;
      final radius = minR + (maxR - minR) * Curves.easeOut.transform(t);
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: (1 - t) * 0.45);
      canvas.drawCircle(center, radius, ring);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.progress != progress || old.active != active || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulsing status dot
// ─────────────────────────────────────────────────────────────────────────────
class PulseDot extends StatefulWidget {
  final Color color;
  final bool pulsing;
  final double size;

  const PulseDot({
    super.key,
    required this.color,
    this.pulsing = false,
    this.size = 8,
  });

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulsing) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant PulseDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulsing && !_c.isAnimating) _c.repeat();
    if (!widget.pulsing && _c.isAnimating) _c.reset();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2.4,
      height: widget.size * 2.4,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Stack(
          alignment: Alignment.center,
          children: [
            if (widget.pulsing)
              Container(
                width: widget.size * (1 + _c.value * 1.4),
                height: widget.size * (1 + _c.value * 1.4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: (1 - _c.value) * 0.5),
                ),
              ),
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Signal bars
// ─────────────────────────────────────────────────────────────────────────────
class SignalBars extends StatelessWidget {
  final int level; // 0..4
  final Color color;

  const SignalBars({
    super.key,
    required this.level,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (i) {
        final on = i < level;
        return Container(
          width: 4,
          height: 5.0 + i * 3.5,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: on ? color : AppColors.borderLight,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Battery pill
// ─────────────────────────────────────────────────────────────────────────────
class BatteryPill extends StatelessWidget {
  final int level;
  final bool charging;
  final bool onDark;

  const BatteryPill({
    super.key,
    required this.level,
    this.charging = false,
    this.onDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = level <= 15
        ? AppColors.error
        : level <= 35
        ? AppColors.warning
        : AppColors.success;
    final icon = charging
        ? Icons.battery_charging_full_rounded
        : level > 80
        ? Icons.battery_full_rounded
        : level > 50
        ? Icons.battery_5_bar_rounded
        : level > 25
        ? Icons.battery_3_bar_rounded
        : Icons.battery_1_bar_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.16)
            : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: onDark ? Colors.white : color),
          const SizedBox(width: 4),
          Text(
            '$level%',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: onDark ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────
class GlassesSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const GlassesSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(48, 36),
              ),
              child: Text(
                actionLabel!,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// White rounded card used across the glasses screens.
class GlassesCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const GlassesCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEBFA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1B0F5C),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

String formatGlassesDuration(int seconds) {
  final d = Duration(seconds: seconds);
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
}

String formatGlassesBytes(int bytes) {
  if (bytes <= 0) return '—';
  const units = ['B', 'KB', 'MB', 'GB'];
  double v = bytes.toDouble();
  int i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  return '${v.toStringAsFixed(i == 0 ? 0 : 1)} ${units[i]}';
}

/// A [FileImage] whose cache key includes the file's size and modification time,
/// so a file that is rewritten on disk (the SDK recompresses photos after download)
/// is decoded again instead of showing a stale or broken cached frame.
class GlassesFileImage extends FileImage {
  final int version;

  const GlassesFileImage(super.file, {required this.version});

  factory GlassesFileImage.of(String path) {
    final file = File(path);
    var version = 0;
    try {
      final stat = file.statSync();
      version = Object.hash(stat.size, stat.modified.millisecondsSinceEpoch);
    } catch (_) {}
    return GlassesFileImage(file, version: version);
  }

  @override
  bool operator ==(Object other) =>
      other is GlassesFileImage &&
      other.file.path == file.path &&
      other.version == version &&
      other.scale == scale;

  @override
  int get hashCode => Object.hash(file.path, version, scale);
}
