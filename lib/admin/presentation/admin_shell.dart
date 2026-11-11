import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/admin/core/admin_config.dart';
import 'package:sadaqo/admin/data/admin_credentials_store.dart';
import 'package:sadaqo/admin/data/admin_user_store.dart';
import 'package:sadaqo/admin/data/admin_verification_store.dart';
import 'package:sadaqo/admin/presentation/admin_nav.dart';
import 'package:sadaqo/admin/presentation/pages/categories_page.dart';
import 'package:sadaqo/admin/presentation/pages/community_monitor_page.dart';
import 'package:sadaqo/admin/presentation/pages/dashboard_page.dart';
import 'package:sadaqo/admin/presentation/pages/news_admin_page.dart';
import 'package:sadaqo/admin/presentation/pages/programs_page.dart';
import 'package:sadaqo/admin/presentation/pages/settings_page.dart';
import 'package:sadaqo/admin/presentation/pages/statistics_page.dart';
import 'package:sadaqo/admin/presentation/pages/transactions_page.dart';
import 'package:sadaqo/admin/presentation/pages/users_page.dart';
import 'package:sadaqo/admin/presentation/pages/verification_page.dart';
import 'package:sadaqo/admin/presentation/widgets/admin_widgets.dart';
import 'package:sadaqo/core/constants/app_assets.dart';
import 'package:sadaqo/core/constants/app_info.dart';
import 'package:sadaqo/core/widgets/batik_widgets.dart';
import 'package:sadaqo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sadaqo/features/auth/presentation/pages/login_page.dart';
import 'package:sadaqo/features/campaign/data/datasources/mock_campaign_store.dart';
import 'package:sadaqo/features/community/data/datasources/community_admin_datasource.dart';
import 'package:sadaqo/features/news/data/datasources/news_mock_datasource.dart';
import 'package:sadaqo/features/profile/presentation/widgets/user_avatar.dart';
import 'package:sadaqo/injection_container.dart';
import 'package:sadaqo/admin/presentation/pages/report_review_page.dart';
import 'package:sadaqo/features/report/domain/repositories/report_repository.dart';

/// Kerangka dashboard admin: sidebar hijau (tetap di layar lebar, laci di layar
/// sempit), bilah atas dengan pencarian, notifikasi, dan profil, lalu isi halaman.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final AdminNav _nav = AdminNav();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _nav.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final ok = await confirmDialog(
      context,
      title: 'Keluar dari dashboard admin?',
      message: 'Kamu perlu masuk lagi dengan email dan password admin.',
      confirmLabel: 'Keluar',
    );
    if (!ok || !mounted) return;
    await context.read<AuthCubit>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Widget _page(AdminPage page) {
    final q = _nav.takeQuery();
    final create = _nav.takeCreate();
    switch (page) {
      case AdminPage.dashboard:
        return DashboardPage(nav: _nav);
      case AdminPage.programs:
        return ProgramsPage(initialQuery: q, startCreate: create);
      case AdminPage.verification:
        return const VerificationPage();
      case AdminPage.reports:
        return const ReportReviewPage();
      case AdminPage.users:
        return UsersPage(initialQuery: q, startCreate: create);
      case AdminPage.community:
        return const CommunityMonitorPage();
      case AdminPage.statistics:
        return const StatisticsPage();
      case AdminPage.transactions:
        return TransactionsPage(initialQuery: q);
      case AdminPage.news:
        return NewsAdminPage(initialQuery: q, startCreate: create);
      case AdminPage.categories:
        return const CategoriesPage();
      case AdminPage.settings:
        return const SettingsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= AdminBreak.wide;
        final sidebar = _Sidebar(nav: _nav, onLogout: _logout, closeOnTap: !wide);
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AdminColors.page,
          drawer: wide ? null : Drawer(width: 280, child: sidebar),
          body: Row(
            children: [
              if (wide) SizedBox(width: 258, child: sidebar),
              Expanded(
                child: ListenableBuilder(
                  listenable: _nav,
                  builder: (context, _) => Stack(
                    children: [
                      // Latar bercorak batik, sama seperti halaman "Tentang SADAQO".
                      const Positioned.fill(
                        child: BatikBackground(opacity: 0.07, child: SizedBox.expand()),
                      ),
                      // Gambar masjid selebar layar di dashboard (tulisan sambutan menimpanya).
                      if (_nav.page == AdminPage.dashboard)
                        const Positioned(top: 0, left: 0, right: 0, height: 310, child: _HeroBackdrop()),
                      const Positioned(right: 0, bottom: 0, child: IgnorePointer(child: _LeafCorner())),
                      Column(
                        children: [
                          _TopBar(
                            nav: _nav,
                            compact: !wide,
                            onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                            onLogout: _logout,
                          ),
                          Expanded(
                            child: ClipRect(
                              child: KeyedSubtree(
                                key: ValueKey<int>(_nav.nonce),
                                child: _page(_nav.page),
                              ),
                            ),
                          ),
                          const _Footer(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ======================= SIDEBAR =======================
class _Sidebar extends StatefulWidget {
  const _Sidebar({required this.nav, required this.onLogout, required this.closeOnTap});

  final AdminNav nav;
  final VoidCallback onLogout;
  final bool closeOnTap;

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  bool _reportOpen = false;

  void _go(AdminPage p) {
    widget.nav.go(p);
    if (widget.closeOnTap) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final verification = sl<AdminVerificationStore>();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AdminColors.sidebarTop, AdminColors.sidebarBottom],
        ),
      ),
      child: Stack(
        children: [
          // Cahaya lembut di belakang logo + corak batik tipis.
          Positioned(
            top: -60,
            left: 0,
            right: 0,
            height: 300,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AdminColors.lime.withValues(alpha: 0.20),
                    AdminColors.lime.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: CustomPaint(painter: _SidebarPatternPainter())),
          SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([widget.nav, verification, sl<ReportRepository>()]),
          builder: (context, _) {
            final current = widget.nav.page;
            final inReport = current == AdminPage.statistics || current == AdminPage.transactions;
            final reportOpen = _reportOpen || inReport;
            return Column(
              children: [
                const SizedBox(height: 22),
                Image.asset(
                  AppAssets.logoEmblem,
                  height: 74,
                  errorBuilder: (context, e, s) =>
                      const Icon(Icons.mosque, size: 64, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  AppInfo.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    AppInfo.tagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _item(AdminPage.dashboard, current),
                      _item(AdminPage.programs, current),
                      _item(AdminPage.verification, current, badge: verification.pendingCount),
                      _item(AdminPage.reports, current, badge: sl<ReportRepository>().pendingCount),
                      _item(AdminPage.users, current),
                      _item(AdminPage.community, current),
                      _group(
                        icon: Icons.bar_chart_rounded,
                        label: 'Laporan',
                        open: reportOpen,
                        active: inReport,
                        onTap: () => setState(() => _reportOpen = !reportOpen),
                        children: [
                          _item(AdminPage.statistics, current, sub: true),
                          _item(AdminPage.transactions, current, sub: true),
                        ],
                      ),
                      _item(AdminPage.news, current),
                      _item(AdminPage.categories, current),
                      _item(AdminPage.settings, current),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.volunteer_activism, color: AdminColors.lime),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Bersama, wujudkan kebaikan yang lebih besar.',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                LayoutBuilder(
                  builder: (context, c) {
                    final showArt = MediaQuery.sizeOf(context).height >= 830;
                    final artH = c.maxWidth * 800 / 1120;
                    return SizedBox(
                      height: showArt ? artH : 64,
                      child: Stack(
                        children: [
                          if (showArt)
                            Positioned.fill(
                              child: Image.asset(
                                'assets/illustrations/admin_sidebar_art.png',
                                fit: BoxFit.fitWidth,
                                alignment: Alignment.bottomCenter,
                                errorBuilder: (context, e, s) => const SizedBox.shrink(),
                              ),
                            ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: InkWell(
                              onTap: widget.onLogout,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      const Color(0xFF14301F).withValues(alpha: 0),
                                      const Color(0xFF14301F).withValues(alpha: 0.85),
                                    ],
                                  ),
                                ),
                                padding: const EdgeInsets.fromLTRB(26, 22, 26, 16),
                                child: const Row(
                                  children: [
                                    Icon(Icons.logout_rounded, color: Colors.white),
                                    SizedBox(width: 14),
                                    Text(
                                      'Logout',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
          ),
        ],
      ),
    );
  }

  Widget _item(AdminPage page, AdminPage current, {int badge = 0, bool sub = false}) {
    final active = page == current;
    return Padding(
      padding: EdgeInsets.only(bottom: 4, left: sub ? 18 : 0),
      child: Material(
        color: active ? AdminColors.lime : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _go(page),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: sub ? 10 : 13),
            child: Row(
              children: [
                Icon(page.icon, size: sub ? 18 : 22, color: active ? AdminColors.green : Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    page.label,
                    style: TextStyle(
                      fontSize: sub ? 13 : 14,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                      color: active ? AdminColors.green : Colors.white,
                    ),
                  ),
                ),
                if (badge > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AdminColors.lime,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AdminColors.green,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _group({
    required IconData icon,
    required String label,
    required bool open,
    required bool active,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Icon(
                    open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (open) ...children,
      ],
    );
  }
}

// ======================= TOP BAR =======================
class _Hit {
  const _Hit(this.label, this.sub, this.page, this.icon);

  final String label;
  final String sub;
  final AdminPage page;
  final IconData icon;
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.nav,
    required this.compact,
    required this.onMenu,
    required this.onLogout,
  });

  final AdminNav nav;
  final bool compact;
  final VoidCallback onMenu;
  final VoidCallback onLogout;

  List<_Hit> _hits() {
    final hits = <_Hit>[];
    for (final c in sl<MockCampaignStore>().all) {
      hits.add(_Hit(c.title, 'Program • ${c.category.shortLabel}', AdminPage.programs, Icons.campaign_rounded));
    }
    for (final u in sl<AdminUserStore>().all) {
      hits.add(_Hit(u.name, 'Pengguna • ${u.email}', AdminPage.users, Icons.person_rounded));
    }
    for (final n in sl<NewsMockDataSource>().adminAll()) {
      hits.add(_Hit(n.title, 'Berita • ${n.category.shortLabel}', AdminPage.news, Icons.newspaper_rounded));
    }
    return hits;
  }

  @override
  Widget build(BuildContext context) {
    final creds = sl<AdminCredentialsStore>();
    final verification = sl<AdminVerificationStore>();
    final community = sl<CommunityAdminDataSource>();

    return Container(
      padding: EdgeInsets.fromLTRB(compact ? 8 : 24, 12, compact ? 8 : 24, 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (compact)
              IconButton(onPressed: onMenu, icon: const Icon(Icons.menu_rounded, color: AdminColors.green)),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Autocomplete<_Hit>(
                    displayStringForOption: (h) => h.label,
                    optionsBuilder: (v) {
                      final q = v.text.trim().toLowerCase();
                      if (q.length < 2) return const Iterable<_Hit>.empty();
                      return _hits()
                          .where((h) => h.label.toLowerCase().contains(q) || h.sub.toLowerCase().contains(q))
                          .take(8);
                    },
                    onSelected: (h) => nav.go(h.page, query: h.label),
                    fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: compact
                              ? 'Cari...'
                              : 'Cari program, pengguna, atau berita...',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          filled: true,
                          fillColor: AdminColors.card,
                        ),
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 6,
                          borderRadius: BorderRadius.circular(14),
                          color: AdminColors.card,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 460, maxHeight: 340),
                            child: ListView(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              shrinkWrap: true,
                              children: [
                                for (final h in options)
                                  ListTile(
                                    dense: true,
                                    leading: Icon(h.icon, color: AdminColors.green),
                                    title: Text(h.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    subtitle: Text(h.sub, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    onTap: () => onSelected(h),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AdminColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
            // ----- Notifikasi -----
            StreamBuilder<void>(
              stream: community.changes,
              builder: (context, _) => ListenableBuilder(
                listenable: Listenable.merge([verification, sl<ReportRepository>()]),
                builder: (context, _) {
                  final pending = verification.pendingCount;
                  final reports = community.reports.length;
                  final banned = community.allStatuses.values.where((s) => s.isBanned()).length;
                  final docs = sl<ReportRepository>().pendingCount;
                  final total = pending + reports + docs;
                  return PopupMenuButton<AdminPage>(
                    tooltip: 'Pemberitahuan',
                    onSelected: (p) => nav.go(p),
                    offset: const Offset(0, 46),
                    itemBuilder: (context) => [
                      if (pending == 0 && reports == 0 && banned == 0 && docs == 0)
                        const PopupMenuItem<AdminPage>(
                          enabled: false,
                          child: Text('Tidak ada pemberitahuan baru'),
                        ),
                      if (pending > 0)
                        PopupMenuItem(
                          value: AdminPage.verification,
                          child: Text('$pending kampanye menunggu verifikasi'),
                        ),
                      if (docs > 0)
                        PopupMenuItem(
                          value: AdminPage.reports,
                          child: Text('$docs laporan menunggu pemeriksaan'),
                        ),
                      if (reports > 0)
                        PopupMenuItem(
                          value: AdminPage.community,
                          child: Text('$reports laporan pesan di Komunitas'),
                        ),
                      if (banned > 0)
                        PopupMenuItem(
                          value: AdminPage.community,
                          child: Text('$banned pengguna sedang dibanned'),
                        ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Badge(
                        isLabelVisible: total > 0,
                        label: Text('$total'),
                        backgroundColor: AdminColors.danger,
                        child: const Icon(Icons.notifications_none_rounded, size: 28, color: AdminColors.green),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 4),
            // ----- Profil admin -----
            ListenableBuilder(
              listenable: creds,
              builder: (context, _) => PopupMenuButton<String>(
                tooltip: 'Akun admin',
                offset: const Offset(0, 50),
                onSelected: (v) {
                  if (v == 'settings') nav.go(AdminPage.settings);
                  if (v == 'logout') onLogout();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'settings', child: Text('Pengaturan')),
                  PopupMenuItem(value: 'logout', child: Text('Keluar')),
                ],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    UserAvatar(initial: creds.adminName.isEmpty ? 'A' : creds.adminName[0].toUpperCase(), radius: 20),
                    if (!compact) ...[
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            creds.adminName,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                          ),
                          const Text(
                            AdminConfig.roleLabel,
                            style: TextStyle(fontSize: 12, color: AdminColors.muted),
                          ),
                        ],
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded),
                    ],
                  ],
                ),
              ),
            ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: AdminColors.goldSoft,
        border: Border(top: BorderSide(color: AdminColors.border)),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Text(
              'SADAQO  •  Platform Penggalangan Dana Komunitas',
              style: TextStyle(fontSize: 12, color: AdminColors.muted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.shield_outlined, size: 16, color: AdminColors.green),
          SizedBox(width: 6),
          Text('Sistem Aman & Terpercaya', style: TextStyle(fontSize: 12, color: AdminColors.muted)),
          SizedBox(width: 14),
          Text('v${AppInfo.version}', style: TextStyle(fontSize: 12, color: AdminColors.muted)),
        ],
      ),
    );
  }
}

/// Gambar masjid selebar layar di bagian atas dashboard, memudar ke warna latar.
class _HeroBackdrop extends StatelessWidget {
  const _HeroBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Colors.black, Colors.transparent],
          stops: [0, 0.58, 1],
        ).createShader(rect),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AppAssets.masjid('masjid_al_azzam.jpg'),
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.3),
              cacheWidth: 1600,
              errorBuilder: (context, e, s) => const SizedBox.shrink(),
            ),
            // Sisi kiri dibuat krem agar tulisan sambutan tetap terbaca.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xF2F6F0E1), Color(0xC8F6F0E1), Color(0x00F6F0E1)],
                  stops: [0, 0.4, 0.8],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lengkung daun lembut di pojok kanan bawah (pemanis, seperti desain referensi).
class _LeafCorner extends StatelessWidget {
  const _LeafCorner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 420, height: 230, child: CustomPaint(painter: _LeafCornerPainter()));
  }
}

class _LeafCornerPainter extends CustomPainter {
  const _LeafCornerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final back = Path()
      ..moveTo(w, h * 0.18)
      ..cubicTo(w * 0.78, h * 0.34, w * 0.55, h * 0.72, w * 0.12, h)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(back, Paint()..color = AdminColors.lime.withValues(alpha: 0.20));
    final front = Path()
      ..moveTo(w, h * 0.46)
      ..cubicTo(w * 0.82, h * 0.62, w * 0.66, h * 0.86, w * 0.36, h)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(front, Paint()..color = AdminColors.green.withValues(alpha: 0.10));
  }

  @override
  bool shouldRepaint(covariant _LeafCornerPainter oldDelegate) => false;
}

/// Corak kawung tipis (putih transparan) untuk latar sidebar hijau.
class _SidebarPatternPainter extends CustomPainter {
  const _SidebarPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 64.0;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (double y = cell / 2; y < size.height + cell; y += cell) {
      for (double x = cell / 2; x < size.width + cell; x += cell) {
        canvas.save();
        canvas.translate(x, y);
        for (var k = 0; k < 4; k++) {
          canvas.drawOval(Rect.fromCenter(center: const Offset(0, 14), width: 20, height: 28), paint);
          canvas.rotate(1.5707963267948966);
        }
        canvas.drawCircle(Offset.zero, 3, paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SidebarPatternPainter oldDelegate) => false;
}
