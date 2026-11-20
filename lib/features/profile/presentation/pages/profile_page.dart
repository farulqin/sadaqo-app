import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:flutter/foundation.dart';
import 'package:sadaqo/core/constants/app_assets.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/core/navigation/main_tab_controller.dart';
import 'package:sadaqo/core/utils/formatter.dart';
import 'package:sadaqo/core/widgets/sadaqo_logo.dart';
import 'package:sadaqo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sadaqo/features/auth/presentation/pages/login_page.dart';
import 'package:sadaqo/features/campaign/domain/entities/campaign.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_cubit.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_state.dart';
import 'package:sadaqo/features/community_feed/presentation/cubit/community_feed_cubit.dart';
import 'package:sadaqo/features/community_feed/presentation/pages/community_badges_page.dart';
import 'package:sadaqo/features/donation/domain/entities/donation.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_history_cubit.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_history_state.dart';
import 'package:sadaqo/features/favorite/presentation/cubit/favorite_cubit.dart';
import 'package:sadaqo/features/favorite/presentation/pages/favorites_page.dart';
import 'package:sadaqo/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:sadaqo/features/notification/presentation/pages/notification_page.dart';
import 'package:sadaqo/features/profile/presentation/pages/about_page.dart';
import 'package:sadaqo/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:sadaqo/features/profile/presentation/pages/help_page.dart';
import 'package:sadaqo/features/profile/presentation/pages/settings_page.dart';
import 'package:sadaqo/features/profile/presentation/widgets/photo_picker_sheet.dart';
import 'package:sadaqo/features/profile/presentation/widgets/user_avatar.dart';
import 'package:sadaqo/injection_container.dart';
import 'package:sadaqo/core/widgets/count_up_text.dart';

/// Level kebaikan dihitung dari total donasi berhasil.
/// Poin = total donasi / Rp 10.000 (pembulatan ke bawah).
class _Level {
  const _Level(this.name, this.min);

  final String name;
  final int min;

  static const tiers = [
    _Level('Pemula', 0),
    _Level('Dermawan', 500000),
    _Level('Sahabat Kebaikan', 2000000),
    _Level('Pahlawan Kebaikan', 5000000),
  ];

  static _Level of(int total) => tiers.lastWhere((t) => total >= t.min);
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _months = 6;

  @override
  void initState() {
    super.initState();
    context.read<CommunityFeedCubit>().refreshQuiet();
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _goHistory() {
    Navigator.of(context).pop(); // kembali dari halaman Profil
    sl<MainTabController>().index.value = MainTabController.history;
  }

  String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit yang lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam yang lalu';
    if (diff.inDays < 30) return '${diff.inDays} hari yang lalu';
    return Formatter.date(d);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().user;
    final history = context.watch<DonationHistoryCubit>().state;
    final donations = history is DonationHistoryLoaded ? history.donations : <Donation>[];
    final ok = donations.where((d) => d.status == DonationStatus.success).toList();
    final total = history is DonationHistoryLoaded ? history.totalSuccess : 0;
    final programs = ok.map((d) => d.campaignId).toSet().length;
    final social = ok.where((d) => d.category == ProgramCategory.sosial || d.category == ProgramCategory.duafa).length;
    final level = _Level.of(total);
    final points = total ~/ 10000;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          _hero(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _identity(user?.name ?? '-', user?.email ?? '-', user?.initial ?? '?', ok.isNotEmpty),
                const SizedBox(height: 12),
                _levelCard(level, points),
                const SizedBox(height: 12),
                _statsBar(total, programs, social),
                const SizedBox(height: 14),
                _activityCard(ok),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, c) {
                    final wide = c.maxWidth >= 520;
                    final a = _achievementsCard();
                    final b = _favoriteCard();
                    if (wide) {
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)],
                        ),
                      );
                    }
                    return Column(children: [a, const SizedBox(height: 12), b]);
                  },
                ),
                const SizedBox(height: 14),
                _recentCard(ok),
                const SizedBox(height: 14),
                _menu(),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    await context.read<AuthCubit>().logout();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Keluar'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Header ----------

  Widget _hero(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: top + 110,
      child: Stack(
        children: [
          Positioned.fill(child: Container(color: const Color(0xFFF1EFDD))),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width * 0.6,
            child: Opacity(
              opacity: 0.55,
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (r) => const LinearGradient(
                  colors: [Colors.transparent, Colors.black],
                  stops: [0.0, 0.6],
                ).createShader(r),
                child: Image.asset(AppAssets.masjidModel, fit: BoxFit.cover, alignment: Alignment.center),
              ),
            ),
          ),
          Positioned(top: -16, right: -30, child: Image.asset(AppAssets.daunKanan, width: 120)),
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(4, top + 10, 24, 12),
              decoration: const BoxDecoration(
                color: AppColors.forestGreen,
                borderRadius: BorderRadius.only(bottomRight: Radius.circular(44)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  const SadaqoLogo(size: 38),
                  const SizedBox(width: 8),
                  const Text('SADAQO', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
          Positioned(
            right: 4,
            top: top + 8,
            child: Row(
              children: [
                BlocBuilder<NotificationCubit, NotificationState>(
                  builder: (context, state) => IconButton(
                    onPressed: () => _open(const NotificationPage()),
                    icon: Badge(
                      isLabelVisible: state.unread > 0,
                      label: Text('${state.unread}'),
                      child: Image.asset(AppAssets.iconNotifikasi, width: 28, height: 28),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _open(const SettingsPage()),
                  icon: const Icon(Icons.settings_rounded, color: AppColors.forestGreen, size: 26),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _identity(String name, String email, String initial, bool active) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const PhotoPickerSheet(),
          ),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: UserAvatar(initial: initial, radius: 42),
              ),
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.forestGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(active ? 'Donatur Aktif' : 'Donatur Baru', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.forestGreen)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _levelCard(_Level level, int points) {
    final idx = _Level.tiers.indexOf(level);
    final next = idx + 1 < _Level.tiers.length ? _Level.tiers[idx + 1] : null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EBC8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Level Kebaikan', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                Text(level.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                Text(
                  next == null ? '$points Poin' : '$points Poin  •  naik level di ${Formatter.rupiah(next.min)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsBar(int total, int programs, int social) {
    const valueStyle = TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w800);
    Widget stat(IconData icon, String label, Widget value) => Expanded(
          child: Column(
            children: [
              Icon(icon, color: AppColors.limeGreen, size: 24),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              FittedBox(child: value),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(color: AppColors.forestGreen, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          stat(
            Icons.volunteer_activism_rounded,
            'Total Donasi',
            CountUpText(value: total, format: Formatter.rupiah, style: valueStyle),
          ),
          Container(width: 1, height: 44, color: Colors.white24),
          stat(
            Icons.favorite_rounded,
            'Program Diikuti',
            CountUpText(value: programs, format: (v) => '${v.round()} Program', style: valueStyle),
          ),
          Container(width: 1, height: 44, color: Colors.white24),
          stat(
            Icons.star_rounded,
            'Kegiatan Sosial',
            CountUpText(value: social, format: (v) => '${v.round()} Kegiatan', style: valueStyle),
          ),
        ],
      ),
    );
  }

  // ---------- Grafik aktivitas ----------

  Widget _card({required Widget child, Color color = Colors.white}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.sandBeige.withValues(alpha: 0.6)),
        ),
        child: child,
      );

  Widget _activityCard(List<Donation> ok) {
    final now = DateTime.now();
    final values = <double>[];
    final labels = <String>[];
    for (var i = _months - 1; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i);
      final sum = ok
          .where((d) => d.createdAt.year == m.year && d.createdAt.month == m.month)
          .fold<int>(0, (a, d) => a + d.amount);
      values.add(sum.toDouble());
      labels.add(DateFormat('MMM', 'id_ID').format(m));
    }
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: AppColors.forestGreen),
              const SizedBox(width: 8),
              const Expanded(child: Text('Ringkasan Aktivitas', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: AppColors.sandBeige.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20)),
                child: DropdownButton<int>(
                  value: _months,
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                  items: const [
                    DropdownMenuItem(value: 3, child: Text('3 Bulan Terakhir')),
                    DropdownMenuItem(value: 6, child: Text('6 Bulan Terakhir')),
                    DropdownMenuItem(value: 12, child: Text('12 Bulan Terakhir')),
                  ],
                  onChanged: (v) => setState(() => _months = v ?? 6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 170,
            width: double.infinity,
            child: CustomPaint(painter: _ActivityPainter(values, labels)),
          ),
        ],
      ),
    );
  }

  // ---------- Pencapaian & favorit ----------

  Widget _achievementsCard() {
    return BlocBuilder<CommunityFeedCubit, CommunityFeedState>(
      builder: (context, state) {
        final badges = state.overview?.myBadges ?? const [];
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _open(const CommunityBadgesPage()),
          child: _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.emoji_events_rounded, color: Color(0xFFF2B01E), size: 34),
                    SizedBox(width: 10),
                    Text('Pencapaian Saya', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${badges.length} Badge', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (badges.isEmpty)
                      const Expanded(
                        child: Text('Berpartisipasilah di Komunitas untuk meraih badge.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      )
                    else
                      for (final b in badges.take(3))
                        Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.only(right: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3EBC8),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.sandBeige),
                          ),
                          child: Text(b.icon, style: const TextStyle(fontSize: 22)),
                        ),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _favoriteCard() {
    final campaigns = context.watch<CampaignCubit>().state;
    final favs = context.watch<FavoriteCubit>().state;
    Campaign? first;
    if (campaigns is CampaignLoaded) {
      for (final c in campaigns.campaigns) {
        if (favs.isFavorite(c.id)) {
          first = c;
          break;
        }
      }
    }
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _open(const FavoritesPage()),
      child: _card(
        color: const Color(0xFFE9F3D2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.card_giftcard_rounded, color: AppColors.forestGreen, size: 34),
                SizedBox(width: 10),
                Expanded(child: Text('Program Favorit', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800))),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              first?.title ?? 'Belum ada program favorit',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(20)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Lihat Detail', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.forestGreen)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.forestGreen),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Aktivitas terbaru ----------

  Widget _recentCard(List<Donation> ok) {
    final recent = [...ok]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, color: AppColors.forestGreen),
              const SizedBox(width: 8),
              const Expanded(child: Text('Aktivitas Terbaru', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
              GestureDetector(
                onTap: _goHistory,
                child: const Text('Lihat Semua →', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Belum ada donasi berhasil. Yuk mulai berbagi kebaikan.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            )
          else
            for (final d in recent.take(3))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: AppColors.successSoft, borderRadius: BorderRadius.circular(12)),
                      child: Icon(d.category.icon, color: AppColors.forestGreen, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Anda berdonasi ${Formatter.rupiah(d.amount)} untuk ${d.campaignTitle}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Text(_ago(d.createdAt), style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  // ---------- Menu ----------

  Widget _menu() {
    // Material (bukan Container) agar efek tekan ListTile terlihat.
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _MenuTile(Icons.person_outline, 'Profil Saya', () => _open(const EditProfilePage())),
          _MenuTile(Icons.receipt_long_outlined, 'Riwayat Donasi', _goHistory),
          _MenuTile(Icons.favorite_border, 'Program Favorit', () => _open(const FavoritesPage())),
          _MenuTile(Icons.settings_outlined, 'Pengaturan', () => _open(const SettingsPage())),
          _MenuTile(Icons.help_outline, 'Bantuan & FAQ', () => _open(const HelpPage())),
          _MenuTile(Icons.info_outline, 'Tentang SADAQO', () => _open(const AboutPage()), last: true),
        ],
      ),
    );
  }
}

/// Grafik garis area sederhana untuk total donasi per bulan.
class _ActivityPainter extends CustomPainter {
  _ActivityPainter(this.values, this.labels);

  final List<double> values;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    const bottomPad = 24.0;
    const topPad = 26.0;
    const sidePad = 14.0;
    final chartH = size.height - bottomPad - topPad;
    final chartW = size.width - sidePad * 2;
    final maxV = values.fold<double>(0, math.max);
    final top = maxV <= 0 ? 1.0 : maxV;

    final grid = Paint()
      ..color = AppColors.sandBeige.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = topPad + chartH * i / 3;
      canvas.drawLine(Offset(sidePad, y), Offset(size.width - sidePad, y), grid);
    }

    final n = values.length;
    final pts = <Offset>[
      for (var i = 0; i < n; i++)
        Offset(
          sidePad + (n == 1 ? chartW / 2 : chartW * i / (n - 1)),
          topPad + chartH * (1 - values[i] / top),
        ),
    ];

    if (pts.length > 1) {
      final line = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        final prev = pts[i - 1];
        final cur = pts[i];
        final mid = (prev.dx + cur.dx) / 2;
        line.cubicTo(mid, prev.dy, mid, cur.dy, cur.dx, cur.dy);
      }
      final area = Path.from(line)
        ..lineTo(pts.last.dx, topPad + chartH)
        ..lineTo(pts.first.dx, topPad + chartH)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.success.withValues(alpha: 0.28), AppColors.success.withValues(alpha: 0.02)],
          ).createShader(Rect.fromLTWH(0, topPad, size.width, chartH)),
      );
      canvas.drawPath(
        line,
        Paint()
          ..color = AppColors.success
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    final dot = Paint()..color = AppColors.success;
    for (final p in pts) {
      canvas.drawCircle(p, 4.5, dot);
    }

    // Label bulan (jarang-jarang bila bulan banyak).
    final step = n > 6 ? 2 : 1;
    for (var i = 0; i < n; i += step) {
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: const TextStyle(fontSize: 11.5, color: AppColors.textDark)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pts[i].dx - tp.width / 2, size.height - tp.height));
    }

    // Balon nilai pada bulan terakhir.
    final last = pts.last;
    final text = Formatter.rupiah(values.last);
    final tp = TextPainter(
      text: TextSpan(text: text, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white)),
      textDirection: TextDirection.ltr,
    )..layout();
    final w = tp.width + 16;
    var left = last.dx - w / 2;
    left = left.clamp(0.0, size.width - w).toDouble();
    final rect = RRect.fromRectAndRadius(Rect.fromLTWH(left, math.max(0, last.dy - 32), w, 22), const Radius.circular(8));
    canvas.drawRRect(rect, Paint()..color = AppColors.forestGreen);
    tp.paint(canvas, Offset(left + 8, rect.top + (22 - tp.height) / 2));
  }

  @override
  bool shouldRepaint(covariant _ActivityPainter old) =>
    !listEquals(old.values, values) || !listEquals(old.labels, labels);
}

class _MenuTile extends StatelessWidget {
  const _MenuTile(this.icon, this.label, this.onTap, {this.last = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: AppColors.forestGreen),
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        if (!last) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}