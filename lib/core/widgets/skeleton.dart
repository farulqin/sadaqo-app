// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_colors.dart';

/// Bentuk kerangka loading yang tersedia.
enum LoadingVariant { list, banner, cards, programList, posts }

/// Efek kilau yang bergerak melintasi seluruh [child]. Satu animasi dipakai
/// bersama oleh semua bentuk di dalamnya (hemat).
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          colors: [AppColors.shimmerBase, AppColors.shimmerHighlight, AppColors.shimmerBase],
          stops: const [0.35, 0.5, 0.65],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          transform: _SlideTransform(-1 + 2 * _c.value),
        ).createShader(bounds),
        child: child,
      ),
    );
  }
}

class _SlideTransform extends GradientTransform {
  const _SlideTransform(this.percent);

  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * percent, 0, 0);
}

/// Kotak kerangka. Warna aslinya diganti oleh [Shimmer].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width = double.infinity, this.height = 14, this.radius = 8});

  final double width;

  /// `null` = isi ruang yang tersedia (pakai di dalam Expanded).
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(radius)),
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
    );
  }
}

/// Susunan kerangka yang menyerupai konten asli.
class SkeletonLayouts {
  SkeletonLayouts._();

  static Widget of(LoadingVariant v) {
    switch (v) {
      case LoadingVariant.banner:
        return const SkeletonBox(height: 190, radius: 16);
      case LoadingVariant.cards:
        return SizedBox(
          height: 236,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 190,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Expanded(child: SkeletonBox(height: null, radius: 16)),
                        SizedBox(height: 10),
                        SkeletonBox(height: 14),
                        SizedBox(height: 6),
                        SkeletonBox(width: 110, height: 12),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      case LoadingVariant.programList:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [for (var i = 0; i < 3; i++) _programRow()],
        );
      case LoadingVariant.posts:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [for (var i = 0; i < 3; i++) _postRow()],
        );
      case LoadingVariant.list:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [for (var i = 0; i < 5; i++) _listRow()],
        );
    }
  }

  static Widget _listRow() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SkeletonCircle(size: 44),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 14),
                  SizedBox(height: 8),
                  SkeletonBox(width: 140, height: 12),
                ],
              ),
            ),
          ],
        ),
      );

  static Widget _programRow() => const Padding(
        padding: EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 118, height: 150, radius: 14),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 16),
                  SizedBox(height: 8),
                  SkeletonBox(width: 120, height: 12),
                  SizedBox(height: 14),
                  SkeletonBox(height: 8, radius: 4),
                  SizedBox(height: 6),
                  SkeletonBox(width: 90, height: 10),
                  SizedBox(height: 22),
                  SkeletonBox(height: 36, radius: 10),
                ],
              ),
            ),
          ],
        ),
      );

  static Widget _postRow() => const Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonCircle(size: 40),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 120, height: 12),
                      SizedBox(height: 6),
                      SkeletonBox(width: 70, height: 10),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            SkeletonBox(height: 12),
            SizedBox(height: 6),
            SkeletonBox(height: 12),
            SizedBox(height: 6),
            SkeletonBox(width: 180, height: 12),
          ],
        ),
      );
}