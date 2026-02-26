import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/theme.dart';

class CustomLoader extends StatefulWidget {
  const CustomLoader({super.key});

  @override
  State<CustomLoader> createState() => _CustomLoaderState();
}

class _CustomLoaderState extends State<CustomLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final List<Color> _colors = [
    AppTheme.white,
    AppTheme.primaryLight,
    Color(0xff227093),
    Color(0xff0532c9),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _interpolateSize(double t) {
    const minSize = 10.0;
    const maxSize = 30.0;
    return minSize + (t * (maxSize - minSize));
  }

  double _degToRad(double deg) => deg * math.pi / 180;

  Alignment _alignmentFor(double t, double angle) {
    final dist = t;
    return Alignment(
      dist * math.cos(_degToRad(angle)),
      dist * math.sin(_degToRad(angle)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          final t = _animation.value * 2 - 1;
          return SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              children: List.generate(_colors.length, (i) {
                final angle = 360 / _colors.length * i;
                final size = _interpolateSize(t.abs());
                return Align(
                  alignment: _alignmentFor(t.abs(), angle),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: _colors[i],
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
