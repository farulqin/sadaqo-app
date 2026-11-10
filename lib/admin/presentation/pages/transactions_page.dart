import 'package:flutter/material.dart';
import 'package:sadaqo/admin/core/admin_utils.dart';
import 'package:sadaqo/admin/data/admin_analytics_store.dart';
import 'package:sadaqo/admin/presentation/widgets/admin_widgets.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/features/donation/domain/entities/donation.dart';
import 'package:sadaqo/injection_container.dart';

/// Daftar transaksi donasi (HANYA-LIHAT): admin tidak dapat mengubah atau menghapus.
class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final _analytics = sl<AdminAnalyticsStore>();
  late final TextEditingController _search;
  ProgramCategory? _category;
  PaymentMethod? _method;
  int _shown = 40;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.initialQuery ?? '');
    _analytics.sync();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _analytics,
      builder: (context, _) {
        final q = _search.text.trim().toLowerCase();
        final items = _analytics.all.where((t) {
          if (_category != null && t.category != _category) return false;
          if (_method != null && t.method != _method) return false;
          if (q.isEmpty) return true;
          return t.donorName.toLowerCase().contains(q) ||
              t.campaignTitle.toLowerCase().contains(q) ||
              t.id.toLowerCase().contains(q) ||
              (t.provider?.toLowerCase().contains(q) ?? false);
        }).toList();
        final total = _analytics.sum(items);
        final visible = items.take(_shown).toList();

        return LayoutBuilder(
          builder: (context, c) {
            final pad = c.maxWidth < 600 ? 14.0 : 24.0;
            final compact = c.maxWidth < 760;
            return ListView(
              padding: EdgeInsets.fromLTRB(pad, 4, pad, 24),
              children: [
                PageHeader(
                  title: 'Transaksi Donasi',
                  subtitle: '${AdminFmt.number(items.length)} transaksi • ${AdminFmt.rupiah(total)}',
                  actions: const [
                    Pill('Hanya lihat', color: AdminColors.green, bg: AdminColors.limeSoft, icon: Icons.lock_outline_rounded),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AdminColors.goldSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: AdminColors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Transaksi donatur tidak dapat diubah atau dihapus oleh admin. Halaman ini hanya untuk memantau.',
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
                AdminSearchField(
                  controller: _search,
                  hint: 'Cari donatur, program, ID, atau bank/e-wallet...',
                  onChanged: (_) => setState(() => _shown = 40),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip('Semua kategori', _category == null, () => setState(() => _category = null)),
                      for (final k in ProgramCategory.values)
                        _chip(k.shortLabel, _category == k, () => setState(() {
                              _category = k;
                              _shown = 40;
                            })),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip('Semua metode', _method == null, () => setState(() => _method = null)),
                      for (final m in PaymentMethod.values)
                        _chip(m.label, _method == m, () => setState(() {
                              _method = m;
                              _shown = 40;
                            })),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (items.isEmpty)
                  const AdminCard(child: EmptyState(icon: Icons.receipt_long_outlined, text: 'Tidak ada transaksi yang cocok'))
                else
                  AdminCard(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        for (var i = 0; i < visible.length; i++) ...[
                          _row(visible[i], compact),
                          if (i != visible.length - 1) const Divider(height: 1, color: AdminColors.border),
                        ],
                      ],
                    ),
                  ),
                if (items.length > visible.length) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: AdminButton(
                      label: 'Muat lebih banyak (${items.length - visible.length} lagi)',
                      outlined: true,
                      onPressed: () => setState(() => _shown += 40),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: AdminColors.green,
        backgroundColor: AdminColors.card,
        labelStyle: TextStyle(
          color: selected ? Colors.white : const Color(0xFF1A1A1A),
          fontWeight: FontWeight.w600,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _row(AdminTxn t, bool compact) {
    final amount = Text(
      AdminFmt.rupiah(t.amount),
      style: const TextStyle(fontWeight: FontWeight.w800, color: AdminColors.green),
    );
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(child: Text(t.donorName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))),
            if (t.isLive) ...[
              const SizedBox(width: 6),
              const Pill('Baru', color: AdminColors.green, bg: AdminColors.limeSoft),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(t.campaignTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
        const SizedBox(height: 2),
        Text(
          '${t.id} • ${AdminFmt.dateTime(t.at)}',
          style: const TextStyle(fontSize: 11.5, color: AdminColors.muted),
        ),
      ],
    );
    return InkWell(
      onTap: () => _detail(t),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: compact
            ? Row(
                children: [
                  Expanded(child: left),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      amount,
                      const SizedBox(height: 4),
                      Text(t.methodLabel, style: const TextStyle(fontSize: 11.5, color: AdminColors.muted)),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(flex: 4, child: left),
                  Expanded(flex: 2, child: Pill(t.category.shortLabel, color: categoryColor(t.category))),
                  Expanded(flex: 2, child: Text(t.methodLabel, style: const TextStyle(fontSize: 13))),
                  SizedBox(width: 130, child: Align(alignment: Alignment.centerRight, child: amount)),
                  const SizedBox(width: 10),
                  const Pill('Berhasil', color: AdminColors.green),
                ],
              ),
      ),
    );
  }

  void _detail(AdminTxn t) {
    Widget line(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 110, child: Text(k, style: const TextStyle(color: AdminColors.muted))),
              Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
            ],
          ),
        );
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.card,
        title: Row(
          children: [
            const Expanded(child: Text('Detail Transaksi')),
            const Pill('Hanya lihat', color: AdminColors.green, icon: Icons.lock_outline_rounded),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              line('ID', t.id),
              line('Waktu', AdminFmt.dateTime(t.at)),
              line('Donatur', t.donorName),
              line('Program', t.campaignTitle),
              line('Kategori', t.category.label),
              line('Metode', t.methodLabel),
              line('Nominal', AdminFmt.rupiah(t.amount)),
              line('Status', 'Berhasil'),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))],
      ),
    );
  }
}
