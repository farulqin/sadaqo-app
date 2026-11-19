import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sadaqo/core/constants/app_colors.dart';

/// Dialog sukses dengan centang yang tergambar dan percikan konfeti.
/// Konfeti berada di atas dialog dan tidak menghalangi ketukan.
Future<void> showCelebrationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String closeLabel = 'Tutup',
}) {
  HapticFeedback.mediumImpact(); // getar ringan di HP (diabaikan di web)
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Stack(
      fit: StackFit.expand,
      children: [
        AlertDialog(
          icon: const AnimatedSuccessCheck(),
          title: Text(title),
          content: Text(message, textAlign: TextAlign.center),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(closeLabel),
            ),
          ],
        ),
        const Positioned.fill(child: ConfettiBurst()),
      ],
    ),
  );
}

// ======================= Centang tergambar =======================

class AnimatedSuccessCheck extends StatefulWidget {
  const AnimatedSuccessCheck({super.key, this.size = 60});

  final double size;

  @override
  State<AnimatedSuccessCheck> createState() => _AnimatedSuccessCheckState();
}

class _AnimatedSuccessCheckState extends State<AnimatedSuccessCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _c.value = 1;
    } else if (_c.status == AnimationStatus.dismissed) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final pop = Curves.elasticOut.transform((_c.value / 0.5).clamp(0.0, 1.0));
            final check = Curves.easeOutCubic.transform(((_c.value - 0.4) / 0.6).clamp(0.0, 1.0));
            final ring = ((_c.value - 0.3) / 0.7).clamp(0.0, 1.0);
            return SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _CheckPainter(pop: pop, check: check, ring: ring),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.pop, required this.check, required this.ring});

  final double pop; // 0..1 (boleh melewati 1 karena efek membal)
  final double check; // 0..1 progres goresan centang
  final double ring; // 0..1 cincin yang memudar

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final c = size.center(Offset.zero);
    final r = side / 2;

    // Cincin yang melebar lalu memudar.
    if (ring > 0 && ring < 1) {
      canvas.drawCircle(
        c,
        r * (1 + 0.45 * ring),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = AppColors.success.withValues(alpha: 0.35 * (1 - ring)),
      );
    }

    // Lingkaran hijau yang membal masuk.
    canvas.drawCircle(c, r * pop, Paint()..color = AppColors.success);

    // Centang digambar sedikit demi sedikit.
    final w = side;
    final h = side;
    final path = Path()
      ..moveTo(w * 0.28, h * 0.52)
      ..lineTo(w * 0.44, h * 0.68)
      ..lineTo(w * 0.74, h * 0.36);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * check),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.09
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.pop != pop || old.check != check || old.ring != ring;
}

// ======================= Konfeti =======================

class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.count = 36});

  final int count;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  static const _seconds = 2.2;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  late final List<_Particle> _particles = () {
    final rnd = math.Random(7);
    return List.generate(widget.count, (_) => _Particle(rnd));
  }();
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _c.value = 1; // langsung selesai: tidak ada konfeti
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _ConfettiPainter(_c, _particles, _seconds),
        ),
      ),
    );
  }
}

class _Particle {
  _Particle(math.Random r)
      : angle = -math.pi / 2 + (r.nextDouble() - 0.5) * math.pi * 1.15,
        speed = 320 + r.nextDouble() * 480,
        size = 6 + r.nextDouble() * 6,
        spin = (r.nextDouble() - 0.5) * 12,
        rotation = r.nextDouble() * math.pi,
        colorIndex = r.nextInt(_palette.length),
        round = r.nextBool();

  static const _palette = [
    AppColors.forestGreen,
    AppColors.limeGreen,
    Color(0xFFD9B84A),
    Color(0xFF7FB08A),
    Color(0xFFE5532D),
  ];

  final double angle;
  final double speed;
  final double size;
  final double spin;
  final double rotation;
  final int colorIndex;
  final bool round;

  Color get color => _palette[colorIndex];
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.animation, this.particles, this.seconds) : super(repaint: animation);

  final Animation<double> animation;
  final List<_Particle> particles;
  final double seconds;

  static const _drag = 1.6;
  static const _gravity = 900.0;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value * seconds;
    if (animation.value >= 1) return;
    final origin = Offset(size.width / 2, size.height * 0.42);
    final fade = t < 1.4 ? 1.0 : (1 - (t - 1.4) / (seconds - 1.4)).clamp(0.0, 1.0);
    final damp = (1 - math.exp(-_drag * t)) / _drag;
    final paint = Paint();

    for (final p in particles) {
      final x = origin.dx + math.cos(p.angle) * p.speed * damp;
      final y = origin.dy + math.sin(p.angle) * p.speed * damp + 0.5 * _gravity * t * t;
      paint.color = p.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + p.spin * t);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size * 0.35, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}