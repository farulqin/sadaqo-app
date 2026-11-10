import 'package:flutter/material.dart';
import 'package:sadaqo/admin/core/admin_utils.dart';
import 'package:sadaqo/admin/data/admin_analytics_store.dart';
import 'package:sadaqo/admin/presentation/widgets/admin_widgets.dart';
import 'package:sadaqo/admin/presentation/widgets/charts.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/features/campaign/data/datasources/mock_campaign_store.dart';
import 'package:sadaqo/features/donation/domain/entities/donation.dart';
import 'package:sadaqo/injection_container.dart';

/// Statistik donasi (HANYA-LIHAT). Admin tidak dapat mengubah transaksi donatur.
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  static const List<(String, int)> _ranges = [
    ('7 Hari', 7),
    ('30 Hari', 30),
    ('6 Bulan', 180),
    ('1 Tahun', 365),
  ];

  final _analytics = sl<AdminAnalyticsStore>();
  final _campaigns = sl<MockCampaignStore>();
  int _range = 1;

  @override
  void initState() {
    super.initState();
    _analytics.sync();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _analytics,
      builder: (context, _) {
        final now = DateTime.now();
        final end = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
        final start = end.subtract(Duration(days: _ranges[_range].$2));
        final txns = _analytics.between(start, end);
        final total = _analytics.sum(txns);
        final avg = txns.isEmpty ? 0 : total ~/ txns.length;
        final donors = txns
            .where((t) => t.donorName != Donation.anonymousName)
            .map((t) => t.donorName)
            .toSet()
            .length;
        final anon = txns.where((t) => t.donorName == Donation.anonymousName).length;
        final (values, labels) = _analytics.timeSeries(start, end);
        final byCat = _analytics.byCategory(txns);
        final byMethod = _analytics.byMethod(txns);
        final byCampaign = _analytics.byCampaign(txns);
        final topDonors = _analytics.topDonors(txns);

        // Per penyedia (DANA, BCA, dll)
        final providers = <String, int>{};
        for (final t in txns) {
          final p = t.provider;
          if (p != null) providers[p] = (providers[p] ?? 0) + t.amount;
        }
        final providerList = providers.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

        // Per hari dalam seminggu
        final dow = List<int>.filled(7, 0);
        for (final t in txns) {
          dow[t.at.weekday - 1] += t.amount;
        }

        return LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final pad = w < 600 ? 14.0 : 24.0;
            final cols = w >= 1100 ? 4 : (w >= 600 ? 2 : 1);
            const gap = 14.0;
            final cardW = (w - pad * 2 - gap * (cols - 1)) / cols;
            return ListView(
              padding: EdgeInsets.fromLTRB(pad, 4, pad, 24),
              children: [
                PageHeader(
                  title: 'Statistik Donasi',
                  subtitle: 'Ringkasan donasi dari para donatur.',
                  actions: [
                    const Pill('Hanya lihat', color: AdminColors.green, bg: AdminColors.limeSoft, icon: Icons.lock_outline_rounded),
                  ],
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < _ranges.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_ranges[i].$1),
                            selected: _range == i,
                            showCheckmark: false,
                            selectedColor: AdminColors.green,
                            backgroundColor: AdminColors.card,
                            labelStyle: TextStyle(
                              color: _range == i ? Colors.white : const Color(0xFF1A1A1A),
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (_) => setState(() => _range = i),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    SizedBox(width: cardW, child: _kpi(Icons.payments_rounded, AdminFmt.rupiah(total), 'Total donasi', true)),
                    SizedBox(width: cardW, child: _kpi(Icons.receipt_long_rounded, AdminFmt.number(txns.length), 'Jumlah transaksi', false)),
                    SizedBox(width: cardW, child: _kpi(Icons.trending_up_rounded, AdminFmt.rupiah(avg), 'Rata-rata per transaksi', false)),
                    SizedBox(width: cardW, child: _kpi(Icons.volunteer_activism_rounded, '$donors', 'Donatur ($anon anonim)', false)),
                  ],
                ),
                const SizedBox(height: 16),
                AdminCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('Tren Donasi', icon: Icons.show_chart_rounded),
                      const SizedBox(height: 12),
                      LineAreaChart(values: values, labels: labels, height: 260),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _twoCols(w, [
                  _categoryCard(byCat, total),
                  _methodCard(byMethod, providerList, total),
                ]),
                const SizedBox(height: 16),
                _twoCols(w, [
                  _programCard(byCampaign),
                  Column(
                    children: [
                      _donorCard(topDonors),
                      const SizedBox(height: 16),
                      _weekdayCard(dow),
                    ],
                  ),
                ]),
              ],
            );
          },
        );
      },
    );
  }

  Widget _twoCols(double w, List<Widget> children) {
    if (w < 900) {
      return Column(
        children: [
          for (var i = 0; i < children.length; i++)
            Padding(padding: EdgeInsets.only(top: i == 0 ? 0 : 16), child: children[i]),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++)
          Expanded(child: Padding(padding: EdgeInsets.only(left: i == 0 ? 0 : 16), child: children[i])),
      ],
    );
  }

  Widget _kpi(IconData icon, String value, String label, bool dark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: dark
            ? const LinearGradient(colors: [Color(0xFF1F4A31), Color(0xFF143222)])
            : null,
        color: dark ? null : AdminColors.card,
        borderRadius: BorderRadius.circular(18),
        border: dark ? null : Border.all(color: AdminColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 30, color: dark ? AdminColors.lime : AdminColors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: dark ? Colors.white : AdminColors.green),
                  ),
                ),
                Text(label, style: TextStyle(fontSize: 12.5, color: dark ? Colors.white70 : AdminColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryCard(Map<ProgramCategory, int> byCat, int total) {
    final segs = [
      for (final k in ProgramCategory.values) DonutSegment(k.shortLabel, (byCat[k] ?? 0).toDouble(), categoryColor(k)),
    ];
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Donasi per Kategori', icon: Icons.donut_large_rounded),
          const SizedBox(height: 14),
          Center(
            child: DonutChart(
              segments: segs,
              centerTop: AdminFmt.rupiahShort(total),
              centerBottom: 'Total',
              size: 180,
              thickness: 28,
            ),
          ),
          const SizedBox(height: 14),
          for (final k in ProgramCategory.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(width: 11, height: 11, decoration: BoxDecoration(color: categoryColor(k), shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(k.label)),
                  Text(AdminFmt.rupiahShort(byCat[k] ?? 0), style: const TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(
                    width: 48,
                    child: Text(
                      total == 0 ? '0%' : '${((byCat[k] ?? 0) * 100 / total).round()}%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: AdminColors.muted),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _methodCard(Map<PaymentMethod, int> byMethod, List<MapEntry<String, int>> providers, int total) {
    final maxM = byMethod.values.fold<int>(0, (a, b) => a > b ? a : b);
    final maxP = providers.isEmpty ? 1 : providers.first.value;
    final icons = {
      PaymentMethod.qris: Icons.qr_code_2_rounded,
      PaymentMethod.ewallet: Icons.account_balance_wallet_outlined,
      PaymentMethod.transfer: Icons.account_balance_outlined,
    };
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Metode Pembayaran', icon: Icons.payments_outlined),
          const SizedBox(height: 8),
          for (final m in PaymentMethod.values)
            BarRow(
              label: m.label,
              leading: Icon(icons[m], size: 18, color: AdminColors.green),
              valueText: AdminFmt.rupiahShort(byMethod[m] ?? 0),
              fraction: maxM == 0 ? 0 : (byMethod[m] ?? 0) / maxM,
              color: AdminColors.green,
            ),
          const SizedBox(height: 12),
          const Text('E-Wallet & Bank terbanyak', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          if (providers.isEmpty)
            const EmptyState(icon: Icons.account_balance_wallet_outlined, text: 'Belum ada data')
          else
            for (final p in providers.take(6))
              BarRow(
                label: p.key,
                valueText: AdminFmt.rupiahShort(p.value),
                fraction: p.value / maxP,
                color: AdminColors.gold,
              ),
        ],
      ),
    );
  }

  Widget _programCard(List<MapEntry<String, int>> byCampaign) {
    final top = byCampaign.take(8).toList();
    final maxV = top.isEmpty ? 1 : top.first.value;
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Program dengan Donasi Terbanyak', icon: Icons.emoji_events_outlined),
          const SizedBox(height: 8),
          if (top.isEmpty)
            const EmptyState(icon: Icons.campaign_outlined, text: 'Belum ada data')
          else
            for (final e in top)
              Builder(builder: (context) {
                final c = _campaigns.byId(e.key);
                return BarRow(
                  label: c?.title ?? e.key,
                  valueText: AdminFmt.rupiahShort(e.value),
                  fraction: e.value / maxV,
                  color: c == null ? AdminColors.green : categoryColor(c.category),
                );
              }),
        ],
      ),
    );
  }

  Widget _donorCard(List<MapEntry<String, int>> donors) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Donatur Teratas', icon: Icons.favorite_border_rounded),
          const SizedBox(height: 8),
          if (donors.isEmpty)
            const EmptyState(icon: Icons.people_outline, text: 'Belum ada data')
          else
            for (var i = 0; i < donors.length; i++)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 15,
                  backgroundColor: i == 0 ? AdminColors.gold : AdminColors.limeSoft,
                  child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AdminColors.green)),
                ),
                title: Text(donors[i].key),
                trailing: Text(AdminFmt.rupiahShort(donors[i].value), style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
        ],
      ),
    );
  }

  Widget _weekdayCard(List<int> dow) {
    const names = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final maxV = dow.fold<int>(0, (a, b) => a > b ? a : b);
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Donasi per Hari', icon: Icons.calendar_view_week_rounded),
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            maxV == 0 ? '' : AdminFmt.axis(dow[i]),
                            style: const TextStyle(fontSize: 10, color: AdminColors.muted),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            height: maxV == 0 ? 4 : (6 + 84 * dow[i] / maxV),
                            decoration: BoxDecoration(
                              color: dow[i] == maxV && maxV > 0 ? AdminColors.green : AdminColors.lime,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(names[i], style: const TextStyle(fontSize: 11.5)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
