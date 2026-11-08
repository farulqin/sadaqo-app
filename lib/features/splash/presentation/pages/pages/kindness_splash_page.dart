import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_assets.dart';
import 'package:sadaqo/core/constants/app_colors.dart';

class KindnessMessages {
  KindnessMessages._();

  static const String welcome =
      'Ahlan wa sahlan di SADAQO.\nBismillah, mari tebar benih kebaikan hari ini';
  static const String thanks =
      'Alhamdulillah, benih kebaikanmu sudah tertanam hari ini';
}

/// Splash ucapan dengan tampilan yang sama seperti splash pembuka aplikasi:
/// latar gradient + lingkaran lembut, logo besar beranimasi, tulisan ucapan,
/// tunas yang tumbuh menjadi hati (Lime Green), dan bar loading di bawah.
/// Tertutup otomatis sekitar 4 detik; ketuk layar untuk melewatinya.
class KindnessSplashPage extends StatefulWidget {
  const KindnessSplashPage({super.key, required this.message, required this.onDone});

  final String message;

  /// Dipanggil sekali saat splash selesai (otomatis atau diketuk).
  final void Function(BuildContext context) onDone;

  @override
  State<KindnessSplashPage> createState() => _KindnessSplashPageState();
}

class _KindnessSplashPageState extends State<KindnessSplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _main = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  late final Animation<double> _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
    CurvedAnimation(
      parent: _main,
      curve: const Interval(0.0, 0.40, curve: Curves.easeOutBack),
    ),
  );
  late final Animation<double> _logoFade = CurvedAnimation(
    parent: _main,
    curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
  );
  late final Animation<Offset> _logoSlide =
      Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
    CurvedAnimation(
      parent: _main,
      curve: const Interval(0.0, 0.40, curve: Curves.easeOutCubic),
    ),
  );
  late final Animation<double> _textFade = CurvedAnimation(
    parent: _main,
    curve: const Interval(0.20, 0.50, curve: Curves.easeIn),
  );
  late final Animation<Offset> _textSlide =
      Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero).animate(
    CurvedAnimation(
      parent: _main,
      curve: const Interval(0.20, 0.50, curve: Curves.easeOut),
    ),
  );

  Timer? _timer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _main.forward().whenComplete(() {
      if (!mounted) return;
      _pulse.repeat(reverse: true); // hati berdenyut lembut
      _timer = Timer(const Duration(milliseconds: 1200), _finish);
    });
  }

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    widget.onDone(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _main.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _finish,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, AppColors.background, AppColors.sandBeige],
            ),
          ),
          child: Stack(
            children: [
              // Hiasan lingkaran lembut (sama seperti splash pembuka)
              Positioned(
                top: -60,
                right: -50,
                child: _Circle(size: 200, color: AppColors.limeGreen.withValues(alpha: 0.15)),
              ),
              Positioned(
                bottom: -70,
                left: -60,
                child: _Circle(size: 220, color: AppColors.forestGreen.withValues(alpha: 0.08)),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FadeTransition(
                          opacity: _logoFade,
                          child: SlideTransition(
                            position: _logoSlide,
                            child: ScaleTransition(
                              scale: _logoScale,
                              child: Image.asset(AppAssets.logo, width: 210),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        FadeTransition(
                          opacity: _textFade,
                          child: SlideTransition(
                            position: _textSlide,
                            child: Text(
                              widget.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.forestGreen,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                height: 1.4,
                                shadows: [
                                  Shadow(color: Color(0x80A3D65C), blurRadius: 12),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 200,
                          height: 140,
                          child: CustomPaint(painter: _SproutPainter(_main, _pulse)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Bar loading di bawah (sama seperti splash pembuka)
              Positioned(
                left: 0,
                right: 0,
                bottom: 48,
                child: Center(
                  child: SizedBox(
                    width: 120,
                    child: AnimatedBuilder(
                      animation: _main,
                      builder: (context, child) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _main.value,
                          minHeight: 4,
                          backgroundColor: AppColors.sandBeige,
                          color: AppColors.limeGreen,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Batang tumbuh, dua daun mekar, lalu hati muncul dengan cahaya (glow) berdenyut.
class _SproutPainter extends CustomPainter {
  _SproutPainter(this.main, this.pulse)
      : super(repaint: Listenable.merge([main, pulse]));

  final Animation<double> main;
  final Animation<double> pulse;

  static const Color _lime = AppColors.limeGreen;
  static const Color _limeDark = Color(0xFF78B03C);

  double _seg(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final t = main.value;
    final p = pulse.value;
    final h = size.height;
    final cx = size.width / 2;
    final baseY = h * 0.96;
    final stemTopY = h * 0.64;

    // 1) batang tumbuh ke atas
    final stemT = Curves.easeOut.transform(_seg(t, 0.30, 0.58));
    final topY = baseY - (baseY - stemTopY) * stemT;
    if (stemT > 0) {
      canvas.drawLine(
        Offset(cx, baseY),
        Offset(cx, topY),
        Paint()
          ..color = _limeDark
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }

    // 2) dua daun mekar
    final leafT = _seg(t, 0.48, 0.78);
    if (leafT > 0) {
      final scale = Curves.easeOutBack.transform(leafT);
      final ay = baseY - (baseY - stemTopY) * 0.55;
      for (final sign in [-1.0, 1.0]) {
        _leaf(canvas, Offset(cx, ay), sign, h * 0.26 * scale);
      }
    }

    // 3) hati membesar di ujung batang + glow
    final heartT = _seg(t, 0.66, 1.0);
    if (heartT > 0) {
      final sc = Curves.easeOutBack.transform(heartT) * (1 + 0.05 * p);
      final hw = h * 0.52 * sc;
      final hh = h * 0.48 * sc;
      final path = _heart(Rect.fromLTWH(cx - hw / 2, topY - hh + 2, hw, hh));

      canvas.drawPath(
        path,
        Paint()
          ..color = _lime.withValues(alpha: 0.35 + 0.35 * p)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14 + 8 * p),
      );
      canvas.drawPath(path, Paint()..color = _lime);
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.forestGreen.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  void _leaf(Canvas canvas, Offset a, double sign, double len) {
    if (len <= 0) return;
    final e = Offset(a.dx + sign * len * 0.866, a.dy - len * 0.5);
    final m = Offset((a.dx + e.dx) / 2, (a.dy + e.dy) / 2);
    final raw = Offset(e.dy - a.dy, -(e.dx - a.dx));
    final n = Offset(raw.dx / raw.distance, raw.dy / raw.distance) * (len * 0.32);
    final c1 = m + n;
    final c2 = m - n;
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(c1.dx, c1.dy, c1.dx, c1.dy, e.dx, e.dy)
      ..cubicTo(c2.dx, c2.dy, c2.dx, c2.dy, a.dx, a.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = _lime);
  }

  Path _heart(Rect r) {
    Offset u(double x, double y) => Offset(r.left + x * r.width, r.top + y * r.height);
    final p = Path();
    final s = u(0.5, 1.0);
    p.moveTo(s.dx, s.dy);
    void c(double x1, double y1, double x2, double y2, double x3, double y3) {
      final a = u(x1, y1);
      final b = u(x2, y2);
      final e = u(x3, y3);
      p.cubicTo(a.dx, a.dy, b.dx, b.dy, e.dx, e.dy);
    }

    c(0.18, 0.78, 0.0, 0.55, 0.0, 0.32);
    c(0.0, 0.10, 0.16, 0.0, 0.30, 0.0);
    c(0.40, 0.0, 0.47, 0.06, 0.5, 0.16);
    c(0.53, 0.06, 0.60, 0.0, 0.70, 0.0);
    c(0.84, 0.0, 1.0, 0.10, 1.0, 0.32);
    c(1.0, 0.55, 0.82, 0.78, 0.5, 1.0);
    p.close();
    return p;
  }

  @override
  bool shouldRepaint(covariant _SproutPainter oldDelegate) => false;
}