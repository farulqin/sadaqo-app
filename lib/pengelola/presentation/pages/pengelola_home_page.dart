import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_assets.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/utils/formatter.dart';
import 'package:sadaqo/core/widgets/program_image.dart';
import 'package:sadaqo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sadaqo/features/campaign/data/models/campaign_model.dart';
import 'package:sadaqo/features/profile/presentation/widgets/user_avatar.dart';
import 'package:sadaqo/injection_container.dart';
import 'package:sadaqo/pengelola/core/pengelola_fmt.dart';
import 'package:sadaqo/pengelola/data/pengelola_store.dart';
import 'package:sadaqo/pengelola/presentation/widgets/pengelola_widgets.dart';
import 'package:sadaqo/pengelola/core/pengelola_layout.dart';
import 'package:sadaqo/pengelola/data/pengelola_account_store.dart';

class PengelolaHomePage extends StatelessWidget {
  const PengelolaHomePage({
    super.key,
    required this.onNavigateTab,
    required this.onSendDocs,
  });

  final ValueChanged<int> onNavigateTab;
  final VoidCallback onSendDocs;

  @override
  Widget build(BuildContext context) {
    final store = sl<PengelolaStore>();
    return ListenableBuilder(
      listenable: store.changes,
      builder: (context, _) {
        final programs = store.programs;
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _Header(store: store, onNavigateTab: onNavigateTab),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: PengelolaLayout.contentMax),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final wide = c.maxWidth >= 760;
                      final summary = Column(
                        children: [
                          _StatsCard(store: store),
                          const SizedBox(height: 16),
                          const _ActivityCard(),
                        ],
                      );
                      final side = Column(
                        children: [
                          _ProgramSection(
                            programs: programs.take(wide ? 4 : 3).toList(),
                            store: store,
                            onSeeAll: () => onNavigateTab(1),
                          ),
                          const SizedBox(height: 14),
                          _DocsBanner(attention: store.attentionCount, onTap: onSendDocs),
                        ],
                      );
                      if (!wide) {
                        return Column(
                          children: [summary, const SizedBox(height: 20), side],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 11, child: summary),
                          const SizedBox(width: 20),
                          Expanded(flex: 9, child: side),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ======================= HEADER =======================
class _Header extends StatelessWidget {
  const _Header({required this.store, required this.onNavigateTab});

  final PengelolaStore store;
  final ValueChanged<int> onNavigateTab;

  @override
  Widget build(BuildContext context) {
    final initial = context.watch<AuthCubit>().user?.initial ?? 'P';
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _HeaderPainter())),
          // Isi header dibatasi lebarnya agar rapi di tablet dan layar lebar.
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: PengelolaLayout.contentMax),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                          child: Row(
                            children: [
                              Image.asset(
                                AppAssets.logoEmblem,
                                height: 46,
                                errorBuilder: (context, e, s) =>
                                    const Icon(Icons.mosque, size: 40, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'SADAQO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const Spacer(),
                              _Bell(store: store, onNavigateTab: onNavigateTab),
                              InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => onNavigateTab(3),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: UserAvatar(initial: initial, radius: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 20,
                      top: 206,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Assalamu'alaikum,",
                            style: TextStyle(fontSize: 15, color: AppColors.textMuted),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Selamat datang, Pengelola!',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Bersama kita sebarkan kebaikan ✨',
                            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bell extends StatelessWidget {
  const _Bell({required this.store, required this.onNavigateTab});

  final PengelolaStore store;
  final ValueChanged<int> onNavigateTab;

  @override
  Widget build(BuildContext context) {
    final account = sl<PengelolaAccountStore>();
    return ListenableBuilder(
      listenable: account,
      builder: (context, _) {
        final subRevision = store.submissionRevisionCount;
        final subPending = store.submissionPendingCount;
        final revision = store.revisionCount;
        final awaiting = store.awaitingDocsCount;
        final review = store.pendingReviewCount;
        final total = subRevision + revision + awaiting;
        final empty = total + subPending + review == 0;
        return PopupMenuButton<int>(
          tooltip: 'Pemberitahuan',
          offset: const Offset(0, 48),
          onSelected: onNavigateTab,
          itemBuilder: (context) => [
            if (empty)
              const PopupMenuItem<int>(enabled: false, child: Text('Tidak ada pemberitahuan baru')),
            if (subRevision > 0)
              PopupMenuItem<int>(value: 1, child: Text('$subRevision pengajuan kampanye perlu direvisi')),
            if (subPending > 0)
              PopupMenuItem<int>(value: 1, child: Text('$subPending pengajuan menunggu verifikasi admin')),
            if (revision > 0)
              PopupMenuItem<int>(value: 2, child: Text('$revision dokumentasi perlu direvisi')),
            if (awaiting > 0)
              PopupMenuItem<int>(value: 1, child: Text('$awaiting program menunggu dokumen')),
            if (review > 0)
              PopupMenuItem<int>(value: 2, child: Text('$review laporan sedang diperiksa admin')),
          ],
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Badge(
              isLabelVisible: account.notificationsEnabled && total > 0,
              smallSize: 10,
              backgroundColor: AppColors.error,
              child: const Icon(Icons.notifications_none_rounded, size: 28, color: AppColors.forestGreen),
            ),
          ),
        );
      },
    );
  }
}

/// Gelombang hijau di kiri atas + siluet masjid di kanan (seperti desain referensi).
/// Di layar lebar, bentuknya tidak melebar: mengikuti lebar isi (maks. contentMax).
class _HeaderPainter extends CustomPainter {
  const _HeaderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cw = math.min(size.width, PengelolaLayout.contentMax);
    final off = (size.width - cw) / 2;
    final w = math.min(cw, 720.0); // lebar acuan gelombang

    // Masjid di belakang (hijau muda transparan), menempel di sisi kanan isi.
    final mw = math.min(cw * 0.38, 260.0);
    _mosque(
      canvas,
      Offset(off + cw - mw * 0.5 - 16, 296),
      mw,
      Paint()..color = const Color(0xFF7FB08A).withValues(alpha: 0.5),
    );

    // Layar lebar: tutup sisi kiri supaya gelombang tidak terpotong.
    if (off > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, off + 1, 196),
        Paint()..color = const Color(0xFF1F3D2B),
      );
    }

    canvas.save();
    canvas.translate(off, 0);

    // Garis lime di tepi gelombang.
    final edge = Path()
      ..moveTo(w * 0.80 + 10, 0)
      ..cubicTo(w * 0.74 + 10, 70, w * 0.62 + 10, 150, w * 0.30 + 10, 168);
    canvas.drawPath(
      edge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = AppColors.limeGreen.withValues(alpha: 0.6),
    );

    // Gelombang hijau tua.
    final wave = Path()
      ..lineTo(w * 0.80, 0)
      ..cubicTo(w * 0.74, 70, w * 0.62, 150, w * 0.30, 168)
      ..cubicTo(w * 0.16, 176, w * 0.05, 186, 0, 196)
      ..close();
    canvas.drawPath(
      wave,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F3D2B), Color(0xFF3A6B47)],
        ).createShader(Rect.fromLTWH(0, 0, w, 200)),
    );

    canvas.restore();
  }

  /// Siluet masjid sederhana: kubah utama, dua kubah kecil, dua menara.
  void _mosque(Canvas c, Offset base, double width, Paint p) {
    final u = width / 10;
    final path = Path()
      ..addRect(Rect.fromLTWH(base.dx - 3.2 * u, base.dy - 3 * u, 6.4 * u, 3 * u))
      ..addOval(Rect.fromCenter(center: Offset(base.dx, base.dy - 3 * u), width: 4 * u, height: 4 * u))
      ..addRect(Rect.fromLTWH(base.dx - 0.12 * u, base.dy - 5.6 * u, 0.24 * u, 0.8 * u));
    for (final s in [-1.0, 1.0]) {
      path.addOval(
        Rect.fromCenter(center: Offset(base.dx + s * 2.8 * u, base.dy - 2.4 * u), width: 1.8 * u, height: 1.8 * u),
      );
      final mx = base.dx + s * 4.6 * u;
      path
        ..addRect(Rect.fromLTWH(mx - 0.35 * u, base.dy - 7 * u, 0.7 * u, 7 * u))
        ..moveTo(mx - 0.5 * u, base.dy - 7 * u)
        ..lineTo(mx, base.dy - 8.6 * u)
        ..lineTo(mx + 0.5 * u, base.dy - 7 * u)
        ..close();
    }
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _HeaderPainter oldDelegate) => false;
}

// ======================= STATISTIK =======================
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.store});

  final PengelolaStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1F3D2B), Color(0xFF2E5E3E)]),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _Stat(
              icon: Icons.campaign_rounded,
              value: store.totalPrograms.toString().padLeft(2, '0'),
              label: 'Total Program',
            ),
            _divider(),
            _Stat(
              icon: Icons.groups_rounded,
              value: PengelolaFmt.number(store.totalDonors),
              label: 'Total Donatur',
            ),
            _divider(),
            _Stat(
              icon: Icons.account_balance_wallet_rounded,
              value: PengelolaFmt.rupiahShort(store.totalDonation),
              label: 'Total Donasi',
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => VerticalDivider(
        width: 1,
        thickness: 1,
        color: Colors.white.withValues(alpha: 0.2),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.limeGreen, size: 28),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ======================= RINGKASAN AKTIVITAS =======================
class _ActivityCard extends StatefulWidget {
  const _ActivityCard();

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  static const _values = PengelolaStore.weeklyDonationMillions;
  static const _labels = PengelolaStore.weekdayLabels;
  int _selected = 5;

  String _jt(double v) => 'Rp ${v.toStringAsFixed(1).replaceAll('.', ',')} jt';

  void _detail() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Donasi 7 Hari Terakhir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _values.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 48, child: Text(_labels[i])),
                    Expanded(child: Text(_jt(_values[i]), style: const TextStyle(fontWeight: FontWeight.w700))),
                  ],
                ),
              ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: AppColors.success, size: 28),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Ringkasan Aktivitas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              TextButton(
                onPressed: _detail,
                child: const Text('Lihat Detail →', style: TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LayoutBuilder(
            builder: (context, c) {
              void pick(double dx) {
                final w = c.maxWidth - _ChartPainter.left - _ChartPainter.right;
                final i = ((dx - _ChartPainter.left) / w * (_values.length - 1))
                    .round()
                    .clamp(0, _values.length - 1)
                    .toInt();
                if (i != _selected) setState(() => _selected = i);
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => pick(d.localPosition.dx),
                onHorizontalDragUpdate: (d) => pick(d.localPosition.dx),
                child: CustomPaint(
                  size: Size(c.maxWidth, 190),
                  painter: _ChartPainter(_values, _labels, _selected, _jt(_values[_selected])),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.values, this.labels, this.selected, this.tooltip);

  final List<double> values;
  final List<String> labels;
  final int selected;
  final String tooltip;

  static const double left = 38;
  static const double right = 12;
  static const double top = 34;
  static const double bottom = 26;

  void _text(Canvas canvas, String text, Offset at, double size, Color color,
      {bool center = false, FontWeight weight = FontWeight.w400}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, color: color, fontWeight: weight)),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(center ? at.dx - tp.width / 2 : at.dx, at.dy);
    tp.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final chartW = size.width - left - right;
    final chartH = size.height - top - bottom;
    final maxValue = values.reduce(math.max);
    final maxY = math.max(4, (maxValue / 4).ceil() * 4).toDouble();

    // Garis bantu + label sumbu Y.
    final grid = Paint()
      ..color = const Color(0xFFE6E0D0)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final v = maxY / 4 * i;
      final y = top + chartH - chartH * (v / maxY);
      canvas.drawLine(Offset(left, y), Offset(size.width - right, y), grid);
      _text(canvas, '${v.round()} jt', Offset(0, y - 7), 11, AppColors.textMuted);
    }

    final pts = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          left + chartW * i / (values.length - 1),
          top + chartH - chartH * (values[i] / maxY),
        ),
    ];

    // Label sumbu X.
    for (var i = 0; i < pts.length; i++) {
      _text(canvas, labels[i], Offset(pts[i].dx, size.height - 18), 11, AppColors.textMuted, center: true);
    }

    // Garis mulus + area gradien.
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final a = pts[i];
      final b = pts[i + 1];
      final mx = (a.dx + b.dx) / 2;
      line.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }
    final baseY = top + chartH;
    final area = Path.from(line)
      ..lineTo(pts.last.dx, baseY)
      ..lineTo(pts.first.dx, baseY)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.success.withValues(alpha: 0.28), AppColors.success.withValues(alpha: 0.02)],
        ).createShader(Rect.fromLTWH(left, top, chartW, chartH)),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF2E7D32),
    );

    // Titik data.
    for (var i = 0; i < pts.length; i++) {
      if (i == selected) {
        canvas.drawCircle(pts[i], 8, Paint()..color = Colors.white);
        canvas.drawCircle(pts[i], 6, Paint()..color = const Color(0xFF2E7D32));
        canvas.drawLine(
          Offset(pts[i].dx, pts[i].dy + 8),
          Offset(pts[i].dx, baseY),
          Paint()
            ..color = AppColors.success.withValues(alpha: 0.35)
            ..strokeWidth = 1,
        );
      } else {
        canvas.drawCircle(pts[i], 4.5, Paint()..color = const Color(0xFF2E7D32));
      }
    }

    // Tooltip di atas titik terpilih.
    final tp = TextPainter(
      text: TextSpan(text: tooltip, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    final bw = tp.width + 22;
    const bh = 28.0;
    final p = pts[selected];
    final bx = (p.dx - bw / 2).clamp(0.0, size.width - bw).toDouble();
    final by = math.max(0.0, p.dy - 44);
    final box = RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bw, bh), const Radius.circular(9));
    final tri = Path()
      ..moveTo(p.dx - 6, by + bh)
      ..lineTo(p.dx + 6, by + bh)
      ..lineTo(p.dx, by + bh + 7)
      ..close();
    final fill = Paint()..color = AppColors.forestGreen;
    canvas.drawRRect(box, fill);
    canvas.drawPath(tri, fill);
    tp.paint(canvas, Offset(bx + 11, by + (bh - tp.height) / 2));
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.selected != selected || old.values != values;
}

// ======================= PROGRAM SAYA =======================
class _ProgramSection extends StatelessWidget {
  const _ProgramSection({required this.programs, required this.store, required this.onSeeAll});

  final List<CampaignModel> programs;
  final PengelolaStore store;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.star_rounded, color: AppColors.forestGreen, size: 28),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Program Saya', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ),
            TextButton(
              onPressed: onSeeAll,
              child: const Text('Lihat Semua →', style: TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        for (final p in programs)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ProgramTile(program: p, status: store.statusOf(p.id), onTap: onSeeAll),
          ),
      ],
    );
  }
}

class _ProgramTile extends StatelessWidget {
  const _ProgramTile({required this.program, required this.status, required this.onTap});

  final CampaignModel program;
  final ProgramDocStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inactive = status != ProgramDocStatus.active;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 1.5,
      shadowColor: AppColors.forestGreen.withValues(alpha: 0.15),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ProgramImage(
                category: program.category,
                imageAsset: program.imageAsset,
                width: 76,
                height: 76,
                borderRadius: BorderRadius.circular(14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProgramStatusChip(status),
                    const SizedBox(height: 4),
                    Text(
                      program.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Target: ${Formatter.rupiah(program.targetAmount)}',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: program.progress,
                              minHeight: 8,
                              backgroundColor: const Color(0xFFE6E0D0),
                              color: inactive ? const Color(0xFF8A8A7A) : const Color(0xFF6FA82B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${program.progressPercent}%', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(color: Color(0xFFDDEFC6), shape: BoxShape.circle),
                child: const Icon(Icons.chevron_right_rounded, color: AppColors.forestGreen),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================= KIRIM DOKUMENTASI =======================
class _DocsBanner extends StatelessWidget {
  const _DocsBanner({required this.attention, required this.onTap});

  final int attention;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF1F3D2B), Color(0xFF2E5E3E)]),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Kirim Dokumentasi',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        if (attention > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.limeGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$attention',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.forestGreen,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Unggah foto kegiatan dan laporan penyaluran.',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(color: AppColors.limeGreen, shape: BoxShape.circle),
                child: const Icon(Icons.chevron_right_rounded, color: AppColors.forestGreen),
              ),
            ],
          ),
        ),
      ),
    );
  }
}