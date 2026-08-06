import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class WaveformVisualizer extends StatefulWidget {
  final bool isRecording;

  const WaveformVisualizer({super.key, required this.isRecording});

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(24, (index) {
            final double baseHeight = 15.0 + (index % 5) * 8.0;
            final double activeHeight = widget.isRecording
                ? baseHeight + (_controller.value * 25 * ((index % 3) + 1))
                : baseHeight;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 4,
              height: activeHeight.clamp(10.0, 70.0),
              decoration: BoxDecoration(
                color: widget.isRecording ? AppColors.primary : AppColors.indicatorInactive,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }
}
