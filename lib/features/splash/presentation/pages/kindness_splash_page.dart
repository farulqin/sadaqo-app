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

/// Splash ucapan dengan perbandingan tinggi 1 : 6 : 3
/// (logo kecil di atas : tulisan di tengah : tunas menjadi hati di bawah).
/// Latar Sand Beige, tulisan Forest Green, tunas dan hati Lime Green.
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
    duration: const Duration(milliseconds: 2600),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  late final Animation<double> _fadeLogo = CurvedAnimation(
    parent: _main,
    curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
  );
  late final Animation<double> _fadeText = CurvedAnimation(
    parent: _main,
    curve: const Interval(0.08, 0.45, curve: Curves.easeOut),
  );
  late final Animation<Offset> _slideText =
      Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
          .animate(_fadeText);

  Timer? _timer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _main.forward().whenComplete(() {
      if (!mounted) return;
      _pulse.repeat(reverse: true); // hati berdenyut lembut
      _timer = Timer(const Duration(milliseconds: 1300), _finish);
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
      backgroundColor: AppColors.sandBeige,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _finish,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                // 1 bagian: logo kecil sebagai tanda khas
                Expanded(
                  flex: 1,
                  child: Center(
                    child: FadeTransition(
                      opacity: _fadeLogo,
                      child: Image.asset(AppAssets.logo, height: 48),
                    ),
                  ),
                ),
                // 6 bagian: tulisan utama
                Expanded(
                  flex: 6,
                  child: Center(
                    child: FadeTransition(
                      opacity: _fadeText,
                      child: SlideTransition(
                        position: _slideText,
                        child: Text(
                          widget.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.forestGreen,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.35,
                            shadows: [Shadow(color: Color(0x99A3D65C), blurRadius: 16)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // 3 bagian: tunas tumbuh menjadi hati
                Expanded(
                  flex: 3,
                  child: CustomPaint(
                    painter: _SproutPainter(_main, _pulse),
                    size: Size.infinite,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final baseY = h * 0.96;
    final stemTopY = h * 0.64;

    // 1) batang tumbuh ke atas
    final stemT = Curves.easeOut.transform(_seg(t, 0.0, 0.40));
    final topY = baseY - (baseY - stemTopY) * stemT;
    canvas.drawLine(
      Offset(cx, baseY),
      Offset(cx, topY),
      Paint()
        ..color = _limeDark
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // 2) dua daun mekar
    final leafT = _seg(t, 0.30, 0.65);
    if (leafT > 0) {
      final scale = Curves.easeOutBack.transform(leafT);
      final ay = baseY - (baseY - stemTopY) * 0.55;
      for (final sign in [-1.0, 1.0]) {
        _leaf(canvas, Offset(cx, ay), sign, h * 0.26 * scale);
      }
    }

    // 3) hati membesar di ujung batang + glow
    final heartT = _seg(t, 0.55, 1.0);
    if (heartT > 0) {
      final sc = Curves.easeOutBack.transform(heartT) * (1 + 0.05 * p);
      final hw = h * 0.50 * sc;
      final hh = h * 0.46 * sc;
      final path = _heart(Rect.fromLTWH(cx - hw / 2, topY - hh + 2, hw, hh));

      canvas.drawPath(
        path,
        Paint()
          ..color = _lime.withValues(alpha: 0.35 + 0.35 * p)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 16 + 8 * p),
      );
      canvas.drawPath(path, Paint()..color = _lime);
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.forestGreen.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
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