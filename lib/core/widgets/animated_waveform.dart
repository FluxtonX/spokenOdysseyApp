import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// A premium animated waveform bar visualizer.
///
/// When [isPlaying] is true the bars animate with a sine-wave pattern.
/// When false they collapse to a low static height.
class AnimatedWaveform extends StatefulWidget {
  final bool isPlaying;
  final int barCount;
  final double height;
  final Color? color;

  const AnimatedWaveform({
    super.key,
    required this.isPlaying,
    this.barCount = 28,
    this.height = 36,
    this.color,
  });

  @override
  State<AnimatedWaveform> createState() => _AnimatedWaveformState();
}

class _AnimatedWaveformState extends State<AnimatedWaveform> {
  Timer? _timer;
  double _phase = 0.0;

  static const _tickMs = 60; // ~16 fps

  @override
  void initState() {
    super.initState();
    if (widget.isPlaying) _startTimer();
  }

  @override
  void didUpdateWidget(AnimatedWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _startTimer();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _stopTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(milliseconds: _tickMs),
      (_) {
        if (mounted) {
          setState(() => _phase += 0.28);
        }
      },
    );
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  double _barHeight(int index) {
    if (!widget.isPlaying) return 4.0;
    // Sine wave offset per bar gives a ripple effect
    final raw = math.sin(_phase + index * 0.5) * 0.5 + 0.5;
    // Clamp between 20% and 100% of widget.height
    return 4 + raw * (widget.height - 4);
  }

  @override
  Widget build(BuildContext context) {
    final barColor = widget.color ?? AppColors.primary;
    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(widget.barCount, (i) {
          final h = _barHeight(i);
          final opacity = widget.isPlaying ? (0.45 + (h / widget.height) * 0.55) : 0.3;
          return AnimatedContainer(
            duration: const Duration(milliseconds: _tickMs),
            curve: Curves.easeInOut,
            width: 2.5,
            height: h,
            decoration: BoxDecoration(
              color: barColor.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
