import 'package:flutter/material.dart';
import 'package:sadaqo/admin/core/admin_utils.dart';
import 'package:sadaqo/admin/data/admin_activity_log.dart';
import 'package:sadaqo/admin/data/admin_analytics_store.dart';
import 'package:sadaqo/admin/data/admin_credentials_store.dart';
import 'package:sadaqo/admin/data/admin_user_store.dart';
import 'package:sadaqo/admin/data/admin_verification_store.dart';
import 'package:sadaqo/admin/presentation/admin_nav.dart';
import 'package:sadaqo/admin/presentation/widgets/admin_widgets.dart';
import 'package:sadaqo/admin/presentation/widgets/charts.dart';
import 'package:sadaqo/core/constants/app_assets.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/features/campaign/data/datasources/mock_campaign_store.dart';
import 'package:sadaqo/features/campaign/domain/entities/campaign.dart';
import 'package:sadaqo/features/community/data/datasources/community_admin_datasource.dart';
import 'package:sadaqo/injection_container.dart';

class _Range {
  const _Range(this.label, this.days);

  final String label;
  final int days;
}

/// Halaman utama admin: ringkasan angka, grafik donasi, program terpopuler,
/// aktivitas terbaru, komposisi kategori, dan pintasan pengelolaan.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.nav});

  final AdminNav nav;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const List<_Range> _ranges = [
    _Range('7 Hari', 7),
    _Range('30 Hari', 30),
    _Range('6 Bulan', 180),
    _Range('1 Tahun', 365),
  ];

  final _analytics = sl<AdminAnalyticsStore>();
  final _users = sl<AdminUserStore>();
  final _verification = sl<AdminVerificationStore>();
  final _log = sl<AdminActivityLog>();
  final _community = sl<CommunityAdminDataSource>();
  final _campaigns = sl<MockCampaignStore>();
  final _creds = sl<AdminCredentialsStore>();

  int _rangeIndex = 0;
  DateTimeRange? _custom; // jika admin memilih tanggal sendiri
  final PageController _popular = PageController();
  int _popularPage = 0;

  @override
  void initState() {
    super.initState();
    _analytics.sync();
  }

  @override
  void dispose() {
    _popular.dispose();
    super.dispose();
  }

  DateTimeRange get _period {
    final c = _custom;
    if (c != null) return c;
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    return DateTimeRange(
      start: end.subtract(Duration(days: _ranges[_rangeIndex].days)),
      end: end,
    );
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 6)),
        end: now,
      ),
    );
    if (picked == null) return;
    setState(() {
      _custom = DateTimeRange(
        start: DateTime(picked.start.year, picked.start.month, picked.start.day),
        end: DateTime(picked.end.year, picked.end.month, picked.end.day).add(const Duration(days: 1)),
      );
    });
  }

  double? _trend(num current, num previous) {
    if (previous <= 0) return null;
    return (current - previous) / previous * 100;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: _community.changes,
      builder: (context, _) => ListenableBuilder(
        listenable: Listenable.merge([_analytics, _users, _verification, _log, _creds]),
        builder: (context, _) => LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final pad = w < 600 ? 14.0 : 24.0;
            return ListView(
              padding: EdgeInsets.fromLTRB(pad, 4, pad, 24),
              children: [
                _welcome(w),
                const SizedBox(height: 16),
                _stats(w),
                const SizedBox(height: 16),
                _split(w, 980, const [2, 1], [_chartCard(), _popularCard()]),
                const SizedBox(height: 16),
                _split(w, 980, const [3, 2, 2], [_activityCard(), _categoryCard(), _quickCard()]),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------------- Header ----------------
  Widget _welcome(double w) {
    return SizedBox(
      height: 112,
      child: Stack(
        children: [
          if (w >= 760)
            Positioned(
              right: 0,
              top: -4,
              bottom: 0,
              width: w * 0.42,
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (r) => const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.transparent, Colors.black],
                  stops: [0, 0.55],
                ).createShader(r),
                child: Image.asset(
                  AppAssets.masjid('masjid_al_azzam.jpg'),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  cacheWidth: 900,
                  errorBuilder: (context, e, s) => const SizedBox.shrink(),
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat datang, Admin! 👋',
                  style: TextStyle(
                    fontSize: w < 600 ? 22 : 30,
                    fontWeight: FontWeight.w800,
                    color: AdminColors.green,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Berikut ringkasan aktivitas SADAQO hari ini.',
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Kartu statistik ----------------
  Widget _stats(double w) {
    final now = DateTime.now();
    final all = _analytics.all;
    final total = _analytics.sum(all);
    final week = _analytics.sum(_analytics.between(now.subtract(const Duration(days: 7)), now.add(const Duration(minutes: 1))));
    final prevWeek = _analytics.sum(_analytics.between(now.subtract(const Duration(days: 14)), now.subtract(const Duration(days: 7))));
    final donTrend = _trend(week, prevWeek);

    final users = _users.all;
    final newUsers = users.where((u) => u.joinedAt.isAfter(now.subtract(const Duration(days: 7)))).length;
    final prevUsers = users
        .where((u) =>
            u.joinedAt.isAfter(now.subtract(const Duration(days: 14))) &&
            u.joinedAt.isBefore(now.subtract(const Duration(days: 7))))
        .length;
    final userTrend = _trend(newUsers, prevUsers);

    final campaigns = _campaigns.all;
    final active = campaigns.where((c) => c.daysLeft > 0 && c.progress < 1).length;

    // Garis tren kecil: donasi 14 hari terakhir dan pendaftar 8 minggu terakhir.
    final donSpark = <double>[];
    for (var i = 13; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      donSpark.add(_analytics.sum(_analytics.between(d, d.add(const Duration(days: 1)))).toDouble());
    }
    final userSpark = <double>[];
    for (var i = 7; i >= 0; i--) {
      final end = now.subtract(Duration(days: i * 7));
      userSpark.add(users.where((u) => u.joinedAt.isBefore(end)).length.toDouble());
    }
    final progSpark = <double>[
      for (final c in campaigns.take(10)) c.progress,
    ];

    final cards = <Widget>[
      _StatCard(
        dark: true,
        icon: Icons.groups_rounded,
        value: AdminFmt.number(users.length),
        label: 'Total Pengguna',
        trend: userTrend,
        trendFallback: '$newUsers baru minggu ini',
        spark: userSpark,
        sparkColor: AdminColors.lime,
      ),
      _StatCard(
        icon: Icons.favorite_rounded,
        value: AdminFmt.rupiah(total),
        label: 'Total Donasi',
        trend: donTrend,
        trendFallback: 'Belum ada pembanding',
        spark: donSpark,
        sparkColor: AdminColors.gold,
        gradient: const LinearGradient(colors: [Color(0xFFFFF6E2), Color(0xFFF3E4BF)]),
      ),
      _StatCard(
        icon: Icons.campaign_rounded,
        value: '$active',
        label: 'Program Aktif',
        trendFallback: 'dari ${campaigns.length} program',
        spark: progSpark,
        sparkColor: AdminColors.green,
        gradient: const LinearGradient(colors: [Color(0xFFEFF7DC), Color(0xFFD8EAAE)]),
      ),
      _StatCard(
        dark: true,
        icon: Icons.verified_user_rounded,
        value: '${_verification.pendingCount}',
        label: 'Menunggu Verifikasi',
        onTap: () => widget.nav.go(AdminPage.verification),
      ),
    ];
    final cols = w >= 1100 ? 4 : (w >= 640 ? 2 : 1);
    const gap = 14.0;
    final itemW = (w - (w < 600 ? 28 : 48) - gap * (cols - 1)) / cols;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [for (final c in cards) SizedBox(width: itemW, child: c)],
    );
  }

  // ---------------- Grafik donasi ----------------
  Widget _chartCard() {
    final period = _period;
    final (values, labels) = _analytics.timeSeries(period.start, period.end);
    final txns = _analytics.between(period.start, period.end);
    final total = _analytics.sum(txns);
    final lastDay = period.end.subtract(const Duration(days: 1));
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 10,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart_rounded, color: AdminColors.green),
                  SizedBox(width: 8),
                  Text(
                    'Statistik Donasi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AdminColors.green),
                  ),
                ],
              ),
              _segmented(),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${AdminFmt.rupiah(total)} • ${AdminFmt.number(txns.length)} transaksi',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _pickRange,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: AdminColors.muted),
                      const SizedBox(width: 5),
                      Text(
                        '${AdminFmt.dayMonthYear(period.start)} – ${AdminFmt.dayMonthYear(lastDay)}',
                        style: const TextStyle(fontSize: 12, color: AdminColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LineAreaChart(values: values, labels: labels, height: 250),
        ],
      ),
    );
  }

  Widget _segmented() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AdminColors.page,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _ranges.length; i++)
            GestureDetector(
              onTap: () => setState(() {
                _rangeIndex = i;
                _custom = null;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _custom == null && _rangeIndex == i ? AdminColors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  _ranges[i].label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _custom == null && _rangeIndex == i ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------- Program terpopuler ----------------
  Widget _popularCard() {
    final top = [..._campaigns.all]..sort((a, b) => b.collectedAmount.compareTo(a.collectedAmount));
    final items = top.take(3).toList();
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            'Program Terpopuler',
            icon: Icons.star_rounded,
            trailing: TextButton(
              onPressed: () => widget.nav.go(AdminPage.programs),
              child: const Text('Lihat Semua →'),
            ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const EmptyState(icon: Icons.campaign_outlined, text: 'Belum ada program')
          else ...[
            SizedBox(
              height: 218,
              child: PageView(
                controller: _popular,
                onPageChanged: (i) => setState(() => _popularPage = i),
                children: [for (final c in items) _popularItem(c)],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < items.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _popularPage ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _popularPage ? AdminColors.green : AdminColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _popularItem(Campaign c) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AssetThumb(c.imageAsset, width: 112, height: 190, radius: 14),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Pill(c.category.shortLabel, color: AdminColors.green, bg: AdminColors.limeSoft),
              const SizedBox(height: 8),
              Text(
                c.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: c.progress,
                  minHeight: 8,
                  backgroundColor: AdminColors.border,
                  color: AdminColors.lime,
                ),
              ),
              const SizedBox(height: 6),
              Text('${c.progressPercent}% tercapai', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                '${AdminFmt.rupiah(c.collectedAmount)} / ${AdminFmt.rupiah(c.targetAmount)}',
                style: const TextStyle(fontSize: 12, color: AdminColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- Aktivitas terbaru ----------------
  List<AdminActivity> _activities() {
    final items = <AdminActivity>[..._log.all];
    for (final t in _analytics.all.take(4)) {
      items.add(AdminActivity(
        ActivityKind.donation,
        'Donasi sebesar ${AdminFmt.rupiah(t.amount)} untuk program ${t.campaignTitle} (${t.donorName})',
        t.at,
      ));
    }
    for (final u in _users.all.where((u) => !u.isDemo || DateTime.now().difference(u.joinedAt).inDays < 14).take(3)) {
      items.add(AdminActivity(ActivityKind.user, 'Pengguna baru mendaftar: ${u.name}', u.joinedAt));
    }
    for (final e in _community.events.take(4)) {
      items.add(AdminActivity(
        e.action.isAuto ? ActivityKind.report : ActivityKind.community,
        '${e.action.label}: ${e.userName}',
        e.at,
      ));
    }
    for (final s in _verification.all.where((s) => s.status == SubmissionStatus.pending)) {
      items.add(AdminActivity(ActivityKind.verified, 'Pengajuan kampanye baru: "${s.title}"', s.submittedAt));
    }
    items.sort((a, b) => b.at.compareTo(a.at));
    return items;
  }

  (IconData, Color) _kindStyle(ActivityKind k) {
    switch (k) {
      case ActivityKind.verified:
        return (Icons.verified_user_rounded, AdminColors.green);
      case ActivityKind.user:
        return (Icons.person_add_alt_1_rounded, AdminColors.green);
      case ActivityKind.donation:
        return (Icons.favorite_rounded, AdminColors.danger);
      case ActivityKind.report:
        return (Icons.security_rounded, AdminColors.warn);
      case ActivityKind.community:
        return (Icons.forum_rounded, AdminColors.green);
      case ActivityKind.content:
        return (Icons.description_rounded, AdminColors.green);
    }
  }

  Widget _activityCard() {
    final items = _activities();
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            'Aktivitas Terbaru',
            icon: Icons.history_rounded,
            trailing: TextButton(
              onPressed: () => _showAll(items),
              child: const Text('Lihat Semua →'),
            ),
          ),
          const SizedBox(height: 6),
          if (items.isEmpty)
            const EmptyState(icon: Icons.history_rounded, text: 'Belum ada aktivitas')
          else
            for (final a in items.take(5)) _activityRow(a),
        ],
      ),
    );
  }

  Widget _activityRow(AdminActivity a) {
    final (icon, color) = _kindStyle(a.kind);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: AdminColors.limeSoft, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AdminFmt.ago(a.at), style: const TextStyle(fontSize: 11.5, color: AdminColors.muted)),
                const SizedBox(height: 2),
                Text(a.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAll(List<AdminActivity> items) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AdminColors.card,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(child: SectionTitle('Semua Aktivitas', icon: Icons.history_rounded)),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                Expanded(
                  child: ListView(children: [for (final a in items.take(40)) _activityRow(a)]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Kategori program ----------------
  Widget _categoryCard() {
    final campaigns = _campaigns.all;
    final colors = <ProgramCategory, Color>{
      ProgramCategory.masjid: const Color(0xFF1F3D2B),
      ProgramCategory.sosial: const Color(0xFF7FB03A),
      ProgramCategory.zakat: const Color(0xFFD9B84A),
      ProgramCategory.duafa: const Color(0xFFA3D65C),
      ProgramCategory.qurban: const Color(0xFF8A6D4B),
    };
    final counts = {for (final k in ProgramCategory.values) k: campaigns.where((c) => c.category == k).length};
    final segments = [for (final k in ProgramCategory.values) DonutSegment(k.shortLabel, counts[k]!.toDouble(), colors[k]!)];
    final total = campaigns.length;
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Kategori Program'),
          const SizedBox(height: 14),
          Center(child: DonutChart(segments: segments, centerTop: '$total', centerBottom: 'Program', size: 160, thickness: 26)),
          const SizedBox(height: 14),
          for (final k in ProgramCategory.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(width: 11, height: 11, decoration: BoxDecoration(color: colors[k], shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(k.shortLabel)),
                  Text(
                    total == 0 ? '0%' : '${(counts[k]! * 100 / total).round()}%',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ---------------- Pengelolaan cepat ----------------
  Widget _quickCard() {
    final tiles = <(IconData, String, VoidCallback)>[
      (Icons.add_circle_outline_rounded, 'Tambah Program', () => widget.nav.go(AdminPage.programs, create: true)),
      (Icons.people_alt_rounded, 'Kelola Pengguna', () => widget.nav.go(AdminPage.users)),
      (Icons.bar_chart_rounded, 'Lihat Laporan', () => widget.nav.go(AdminPage.statistics)),
      (Icons.settings_rounded, 'Pengaturan Sistem', () => widget.nav.go(AdminPage.settings)),
    ];
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Pengelolaan Cepat', icon: Icons.bolt_rounded),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              for (final t in tiles)
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: t.$3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AdminColors.goldSoft.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(t.$1, size: 30, color: AdminColors.green),
                        const SizedBox(height: 8),
                        Text(
                          t.$2,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _split(double w, double breakpoint, List<int> flex, List<Widget> children) {
    if (w >= breakpoint) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++)
            Expanded(
              flex: flex[i],
              child: Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 16),
                child: children[i],
              ),
            ),
        ],
      );
    }
    return Column(
      children: [
        for (var i = 0; i < children.length; i++)
          Padding(padding: EdgeInsets.only(top: i == 0 ? 0 : 16), child: children[i]),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.dark = false,
    this.trend,
    this.trendFallback,
    this.spark,
    this.sparkColor,
    this.gradient,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool dark;
  final double? trend;
  final String? trendFallback;
  final List<double>? spark;
  final Color? sparkColor;
  final Gradient? gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : AdminColors.green;
    final sub = dark ? Colors.white70 : AppColors.textDark;
    final up = (trend ?? 0) >= 0;
    final decoration = BoxDecoration(
      gradient: dark
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1F4A31), Color(0xFF143222)],
            )
          : gradient,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AdminColors.green.withValues(alpha: 0.16),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        height: 138,
        padding: const EdgeInsets.all(16),
        decoration: decoration,
        child: Stack(
          children: [
            if (spark != null && sparkColor != null)
              Positioned(right: 0, bottom: 4, child: Sparkline(values: spark!, color: sparkColor!)),
            if (onTap != null)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(color: AdminColors.lime, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward_rounded, color: AdminColors.green, size: 20),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 28, color: fg),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: fg),
                      ),
                    ),
                    Text(label, style: TextStyle(color: sub, fontSize: 13.5)),
                    if (trend != null)
                      Text(
                        '${up ? '↑' : '↓'} ${up ? '+' : ''}${trend!.toStringAsFixed(1).replaceAll('.', ',')}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: dark ? AdminColors.lime : (up ? AdminColors.green : AdminColors.danger),
                        ),
                      )
                    else if (trendFallback != null)
                      Text(trendFallback!, style: TextStyle(fontSize: 12, color: sub)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
