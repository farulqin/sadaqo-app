import 'package:flutter/material.dart';

/// Progress bar yang terisi pelan dari 0 ke [value] saat pertama tampil,
/// dan bergerak halus bila nilainya berubah.
class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({
    super.key,
    required this.value,
    required this.color,
    required this.backgroundColor,
    this.minHeight = 8,
    this.radius = 8,
    this.duration = const Duration(milliseconds: 800),
  });

  /// 0.0 sampai 1.0
  final double value;
  final Color color;
  final Color backgroundColor;
  final double minHeight;
  final double radius;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: reduce ? Duration.zero : duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: LinearProgressIndicator(
          value: v,
          minHeight: minHeight,
          backgroundColor: backgroundColor,
          color: color,
        ),
      ),
    );
  }
}