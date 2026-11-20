import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_colors.dart';

/// Latar tema Liquid Glass: gradien hijau tua dengan cahaya lime dan mint.
/// Pada tema lain widget ini tidak menggambar apa pun.
class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppColors.isGlass) return const SizedBox.shrink();
    return const RepaintBoundary(
      child: CustomPaint(painter: _GlassPainter(), size: Size.infinite),
    );
  }
}

class _GlassPainter extends CustomPainter {
  const _GlassPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1F16), Color(0xFF11301F), Color(0xFF0B2419)],
        ).createShader(rect),
    );

    void glow(Offset center, double radius, Color color) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    final s = size.shortestSide;
    glow(Offset(size.width * 0.12, size.height * 0.10), s * 0.95, const Color(0xFFA3D65C).withValues(alpha: 0.30));
    glow(Offset(size.width * 0.98, size.height * 0.52), s * 0.85, const Color(0xFF3DDC97).withValues(alpha: 0.20));
    glow(Offset(size.width * 0.20, size.height * 0.98), s * 0.80, const Color(0xFFF2D37A).withValues(alpha: 0.14));
  }

  @override
  bool shouldRepaint(_GlassPainter old) => false;
}

/// Pembungkus transisi halaman: setiap halaman membawa latar kaca sendiri
/// (agar tidak tembus pandang saat berpindah) lalu memakai animasi bawaan platform.
/// Susunan widget dibuat tetap di semua tema agar state halaman tidak ter-reset
/// ketika tema berganti.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder(this.inner);

  final PageTransitionsBuilder inner;

  static const material = AppPageTransitionsBuilder(ZoomPageTransitionsBuilder());
  static const cupertino = AppPageTransitionsBuilder(CupertinoPageTransitionsBuilder());

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return inner.buildTransitions<T>(
      route,
      context,
      animation,
      secondaryAnimation,
      Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: GlassBackdrop()),
          child,
        ],
      ),
    );
  }
}
