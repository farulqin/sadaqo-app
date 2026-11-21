import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_colors.dart';

/// Latar tema Liquid Glass: gradasi hijau lembut ke krem dengan cahaya lime,
/// awan putih, dan hijau dedaunan yang buram. Pada tema lain tidak menggambar apa pun.
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
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC9E1BE), Color(0xFFE9F1DA), Color(0xFFF6F1E1), Color(0xFFDCEBCB)],
          stops: [0, 0.32, 0.66, 1],
        ).createShader(rect),
    );

    void blob(Offset c, double r, Color color, double sigma) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma),
      );
    }

    final w = size.width;
    final h = size.height;
    final s = size.shortestSide;
    blob(Offset(w * 0.05, h * 0.02), s * 0.75, const Color(0xFF3E8E41).withValues(alpha: 0.36), 60);
    blob(Offset(w * 1.00, h * 0.10), s * 0.60, const Color(0xFFA3D65C).withValues(alpha: 0.40), 55);
    blob(Offset(w * 0.55, h * 0.30), s * 0.55, Colors.white.withValues(alpha: 0.55), 70);
    blob(Offset(w * 0.00, h * 0.62), s * 0.50, const Color(0xFFA3D65C).withValues(alpha: 0.22), 60);
    blob(Offset(w * 0.95, h * 0.88), s * 0.65, const Color(0xFF7FB77E).withValues(alpha: 0.30), 70);
    blob(Offset(w * 0.20, h * 1.00), s * 0.55, Colors.white.withValues(alpha: 0.50), 60);
  }

  @override
  bool shouldRepaint(_GlassPainter old) => false;
}

/// Dipasang lewat MaterialApp.builder: latar kaca berada di bawah Navigator,
/// sehingga halaman (yang transparan pada tema Glass) selalu tampil di atasnya.
/// Susunan widget sama di semua tema agar state halaman tidak ter-reset.
class GlassRoot extends StatelessWidget {
  const GlassRoot({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: GlassBackdrop()),
        child,
      ],
    );
  }
}
