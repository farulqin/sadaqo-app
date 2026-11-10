import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sadaqo/admin/core/admin_utils.dart';
import 'package:sadaqo/admin/presentation/widgets/admin_widgets.dart';

/// Grafik garis halus beraluran (area) dengan tooltip saat disentuh / diarahkan mouse.
class LineAreaChart extends StatefulWidget {
  const LineAreaChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 240,
    this.formatValue,
  });

  final List<double> values;
  final List<String> labels;
  final double height;
  final String Function(double)? formatValue;

  @override
  State<LineAreaChart> createState() => _LineAreaChartState();
}

class _LineAreaChartState extends State<LineAreaChart> {
  int? _hover;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, c) {
          final painter = _LinePainter(
            values: widget.values,
            labels: widget.labels,
            hover: _hover,
            format: widget.formatValue ?? (v) => AdminFmt.rupiah(v),
          );
          void update(Offset p) {
            final i = painter.indexAt(p.dx, Size(c.maxWidth, c.maxHeight));
            if (i != _hover) setState(() => _hover = i);
          }

          return MouseRegion(
            onHover: (e) => update(e.localPosition),
            onExit: (_) => setState(() => _hover = null),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => update(d.localPosition),
              onPanUpdate: (d) => update(d.localPosition),
              child: CustomPaint(size: Size(c.maxWidth, c.maxHeight), painter: painter),
            ),
          );
        },
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.values,
    required this.labels,
    required this.hover,
    required this.format,
  });

  final List<double> values;
  final List<String> labels;
  final int? hover;
  final String Function(double) format;

  static const double _left = 54;
  static const double _right = 14;
  static const double _top = 16;
  static const double _bottom = 28;

  double _niceMax() {
    final m = values.isEmpty ? 1.0 : values.reduce(math.max);
    if (m <= 0) return 1;
    final mag = math.pow(10, (math.log(m) / math.ln10).floor()).toDouble();
    final n = m / mag;
    final double nice = n <= 1 ? 1.0 : (n <= 2 ? 2.0 : (n <= 2.5 ? 2.5 : (n <= 5 ? 5.0 : 10.0)));
    return nice * mag;
  }

  Offset _point(int i, Size size, double max) {
    final w = size.width - _left - _right;
    final h = size.height - _top - _bottom;
    final x = values.length <= 1 ? _left + w / 2 : _left + w * i / (values.length - 1);
    final y = _top + h - (values[i] / max) * h;
    return Offset(x, y);
  }

  int? indexAt(double dx, Size size) {
    if (values.isEmpty) return null;
    final w = size.width - _left - _right;
    if (values.length == 1) return 0;
    final t = ((dx - _left) / w).clamp(0.0, 1.0);
    return (t * (values.length - 1)).round();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final max = _niceMax();
    final grid = Paint()
      ..color = AdminColors.border
      ..strokeWidth = 1;
    const ticks = 4;
    for (var i = 0; i <= ticks; i++) {
      final y = _top + (size.height - _top - _bottom) * i / ticks;
      canvas.drawLine(Offset(_left, y), Offset(size.width - _right, y), grid);
      final v = max * (ticks - i) / ticks;
      _text(canvas, AdminFmt.axis(v), Offset(_left - 8, y), align: TextAlign.right, anchorRight: true);
    }
    if (values.isEmpty) return;

    final pts = [for (var i = 0; i < values.length; i++) _point(i, size, max)];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = pts[i];
      final p1 = pts[i + 1];
      final cx = (p0.dx + p1.dx) / 2;
      path.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }
    final area = Path.from(path)
      ..lineTo(pts.last.dx, size.height - _bottom)
      ..lineTo(pts.first.dx, size.height - _bottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AdminColors.lime.withValues(alpha: 0.45),
            AdminColors.lime.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, _top, size.width, size.height)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AdminColors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    // Titik data (jika sedikit) + label sumbu X.
    final dot = Paint()..color = AdminColors.green;
    final dotBg = Paint()..color = Colors.white;
    final step = math.max(1, (values.length / 8).ceil());
    for (var i = 0; i < pts.length; i++) {
      if (values.length <= 14 || i == hover) {
        canvas.drawCircle(pts[i], 4.5, dotBg);
        canvas.drawCircle(pts[i], 3.2, dot);
      }
      if (i % step == 0 || i == pts.length - 1) {
        _text(canvas, labels[i], Offset(pts[i].dx, size.height - _bottom + 8), align: TextAlign.center);
      }
    }

    // Tooltip.
    final h = hover;
    if (h != null && h < pts.length) {
      final p = pts[h];
      canvas.drawLine(
        Offset(p.dx, _top),
        Offset(p.dx, size.height - _bottom),
        Paint()
          ..color = AdminColors.green.withValues(alpha: 0.25)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(p, 6, dotBg);
      canvas.drawCircle(p, 4.2, dot);
      final tp = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${labels[h]}\n',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            TextSpan(
              text: format(values[h]),
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final boxW = tp.width + 20;
      final boxH = tp.height + 14;
      var bx = p.dx - boxW / 2;
      bx = bx.clamp(_left, size.width - _right - boxW).toDouble();
      var by = p.dy - boxH - 12;
      if (by < 0) by = p.dy + 12;
      final rect = RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, boxW, boxH), const Radius.circular(10));
      canvas.drawRRect(rect, Paint()..color = AdminColors.green);
      tp.paint(canvas, Offset(bx + 10, by + 7));
    }
  }

  void _text(Canvas canvas, String s, Offset at,
      {TextAlign align = TextAlign.left, bool anchorRight = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: const TextStyle(fontSize: 11, color: AdminColors.muted)),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout();
    double dx = at.dx;
    double dy = at.dy;
    if (anchorRight) {
      dx = at.dx - tp.width;
      dy = at.dy - tp.height / 2;
    } else {
      dx = at.dx - tp.width / 2;
    }
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.hover != hover || old.values != values || old.labels != labels;
}

class DonutSegment {
  const DonutSegment(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
}

/// Donat dengan teks di tengah.
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.segments,
    required this.centerTop,
    required this.centerBottom,
    this.size = 170,
    this.thickness = 28,
  });

  final List<DonutSegment> segments;
  final String centerTop;
  final String centerBottom;
  final double size;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(segments, thickness),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerTop,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AdminColors.green),
              ),
              Text(centerBottom, style: const TextStyle(fontSize: 12, color: AdminColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.segments, this.thickness);

  final List<DonutSegment> segments;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(0, (a, s) => a + s.value);
    final rect = Rect.fromLTWH(thickness / 2, thickness / 2, size.width - thickness, size.height - thickness);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..color = AdminColors.border;
    if (total <= 0) {
      canvas.drawArc(rect, 0, math.pi * 2, false, base);
      return;
    }
    var start = -math.pi / 2;
    const gap = 0.02;
    for (final s in segments) {
      if (s.value <= 0) continue;
      final sweep = s.value / total * math.pi * 2;
      canvas.drawArc(
        rect,
        start + gap / 2,
        math.max(0.001, sweep - gap),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness
          ..color = s.color,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.segments != segments || old.thickness != thickness;
}

/// Garis kecil tren untuk kartu statistik.
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values, required this.color, this.width = 110, this.height = 46});

  final List<double> values;
  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(width, height), painter: _SparkPainter(values, color));
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color);

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxV = values.reduce(math.max);
    final minV = values.reduce(math.min);
    final span = (maxV - minV) == 0 ? 1.0 : (maxV - minV);
    final pts = [
      for (var i = 0; i < values.length; i++)
        Offset(
          size.width * i / (values.length - 1),
          size.height - 4 - (values[i] - minV) / span * (size.height - 8),
        ),
    ];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final cx = (pts[i].dx + pts[i + 1].dx) / 2;
      path.cubicTo(cx, pts[i].dy, cx, pts[i + 1].dy, pts[i + 1].dx, pts[i + 1].dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.values != values || old.color != color;
}
