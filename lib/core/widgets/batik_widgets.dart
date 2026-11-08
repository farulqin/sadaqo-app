import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_colors.dart';

/// Latar dengan pola batik kawung yang sangat tipis (watermark).
class BatikBackground extends StatelessWidget {
  const BatikBackground({super.key, required this.child, this.opacity = 0.06});

  final Widget child;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _KawungPainter(opacity))),
        child,
      ],
    );
  }
}

class _KawungPainter extends CustomPainter {
  const _KawungPainter(this.opacity);

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 64.0;
    final paint = Paint()
      ..color = AppColors.forestGreen.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (double y = cell / 2; y < size.height + cell; y += cell) {
      for (double x = cell / 2; x < size.width + cell; x += cell) {
        canvas.save();
        canvas.translate(x, y);
        for (var k = 0; k < 4; k++) {
          canvas.drawOval(Rect.fromCenter(center: const Offset(0, 14), width: 20, height: 28), paint);
          canvas.rotate(1.5707963267948966); // 90 derajat
        }
        canvas.drawCircle(Offset.zero, 3, paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KawungPainter oldDelegate) => oldDelegate.opacity != opacity;
}

/// Garis pemisah antar-seksi dengan hiasan belah ketupat bergaya batik.
class BatikDivider extends StatelessWidget {
  const BatikDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forestGreen.withValues(alpha: 0.35);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: color)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '◆  ◇  ◆',
              style: TextStyle(color: color, fontSize: 10, letterSpacing: 3),
            ),
          ),
          Expanded(child: Container(height: 1, color: color)),
        ],
      ),
    );
  }
}