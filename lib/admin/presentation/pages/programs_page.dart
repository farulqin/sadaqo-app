import 'package:flutter/material.dart';
import 'package:sadaqo/admin/core/admin_utils.dart';
import 'package:sadaqo/admin/data/admin_activity_log.dart';
import 'package:sadaqo/admin/presentation/pages/program_form_dialog.dart';
import 'package:sadaqo/admin/presentation/widgets/admin_widgets.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/features/campaign/data/datasources/mock_campaign_store.dart';
import 'package:sadaqo/features/campaign/domain/entities/campaign.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_cubit.dart';
import 'package:sadaqo/injection_container.dart';

/// Tambah, ubah, dan hapus program. Perubahan langsung terlihat di aplikasi pengguna.
class ProgramsPage extends StatefulWidget {
  const ProgramsPage({super.key, this.initialQuery, this.startCreate = false});

  final String? initialQuery;
  final bool startCreate;

  @override
  State<ProgramsPage> createState() => _ProgramsPageState();
}

class _ProgramsPageState extends State<ProgramsPage> {
  final _store = sl<MockCampaignStore>();
  final _log = sl<AdminActivityLog>();
  late final TextEditingController _search;
  ProgramCategory? _category;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.initialQuery ?? '');
    if (widget.startCreate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openForm();
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _refreshApp() => sl<CampaignCubit>().refresh();

  Future<void> _openForm({Campaign? existing}) async {
    final result = await showProgramForm(
      context,
      store: _store,
      existing: existing == null ? null : _store.byId(existing.id),
    );
    if (result == null || !mounted) return;
    _store.adminSave(result);
    _refreshApp();
    _log.add(
      ActivityKind.content,
      existing == null ? 'Program baru ditambahkan: "${result.title}"' : 'Program diperbarui: "${result.title}"',
    );
    setState(() {});
    adminToast(context, existing == null ? 'Program ditambahkan' : 'Perubahan disimpan');
  }

  Future<void> _delete(Campaign c) async {
    final extra = c.collectedAmount > 0
        ? '\n\nProgram ini sudah menerima ${AdminFmt.rupiah(c.collectedAmount)}. Riwayat transaksi donatur tetap tersimpan dan tidak ikut terhapus.'
        : '';
    final ok = await confirmDialog(
      context,
      title: 'Hapus program?',
      message: '"${c.title}" akan hilang dari aplikasi pengguna.$extra',
      confirmLabel: 'Hapus',
      danger: true,
    );
    if (!ok || !mounted) return;
    _store.adminRemove(c.id);
    _refreshApp();
    _log.add(ActivityKind.content, 'Program dihapus: "${c.title}"');
    setState(() {});
    adminToast(context, 'Program dihapus');
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final all = _store.all;
    final items = all.where((c) {
      if (_category != null && c.category != _category) return false;
      if (q.isEmpty) return true;
      return c.title.toLowerCase().contains(q) ||
          c.location.toLowerCase().contains(q) ||
          (c.subType?.toLowerCase().contains(q) ?? false) ||
          c.category.label.toLowerCase().contains(q);
    }).toList();

    return LayoutBuilder(
      builder: (context, c) {
        final pad = c.maxWidth < 600 ? 14.0 : 24.0;
        return ListView(
          padding: EdgeInsets.fromLTRB(pad, 4, pad, 24),
          children: [
            PageHeader(
              title: 'Kelola Program',
              subtitle: '${all.length} program • tambah, ubah, atau hapus program donasi.',
              actions: [
                AdminButton(
                  label: 'Tambah Program',
                  icon: Icons.add_rounded,
                  onPressed: () => _openForm(),
                ),
              ],
            ),
            AdminSearchField(
              controller: _search,
              hint: 'Cari judul, lokasi, atau jenis program...',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('Semua', _category == null, () => setState(() => _category = null)),
                  for (final k in ProgramCategory.values)
                    _chip(
                      '${k.shortLabel} (${all.where((x) => x.category == k).length})',
                      _category == k,
                      () => setState(() => _category = k),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (items.isEmpty)
              const AdminCard(child: EmptyState(icon: Icons.search_off_rounded, text: 'Tidak ada program yang cocok'))
            else
              for (final p in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ProgramRow(
                    campaign: p,
                    compact: c.maxWidth < 760,
                    onEdit: () => _openForm(existing: p),
                    onDelete: () => _delete(p),
                  ),
                ),
          ],
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
}

class _ProgramRow extends StatelessWidget {
  const _ProgramRow({
    required this.campaign,
    required this.compact,
    required this.onEdit,
    required this.onDelete,
  });

  final Campaign campaign;
  final bool compact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = campaign;
    final status = c.isFull
        ? const Pill('Penuh', color: AdminColors.warn)
        : (c.progress >= 1
            ? const Pill('Target tercapai', color: AdminColors.green)
            : (c.daysLeft <= 0
                ? const Pill('Berakhir', color: AdminColors.danger)
                : Pill('${c.daysLeft} hari lagi', color: AdminColors.green)));

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            Pill(c.category.shortLabel, color: AdminColors.green, bg: AdminColors.limeSoft),
            if (c.subType != null) Pill(c.subType!, color: AdminColors.muted),
            status,
            if (c.unitPrice != null) Pill('${AdminFmt.rupiah(c.unitPrice!)}/${c.unitLabel ?? 'unit'}', color: AdminColors.gold),
          ],
        ),
        const SizedBox(height: 8),
        Text(c.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(c.location, style: const TextStyle(fontSize: 12.5, color: AdminColors.muted)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: c.progress,
            minHeight: 7,
            backgroundColor: AdminColors.border,
            color: AdminColors.lime,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${c.progressPercent}% • ${AdminFmt.rupiah(c.collectedAmount)} / ${AdminFmt.rupiah(c.targetAmount)}'
          '${c.isSlotBased ? '  •  Slot ${c.slotFilled ?? 0}/${c.slotTotal}' : ''}',
          style: const TextStyle(fontSize: 12.5),
        ),
      ],
    );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          tooltip: 'Ubah',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_rounded, size: 20),
        ),
        const SizedBox(width: 6),
        IconButton.filledTonal(
          tooltip: 'Hapus',
          style: IconButton.styleFrom(
            backgroundColor: AdminColors.dangerSoft,
            foregroundColor: AdminColors.danger,
          ),
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded, size: 20),
        ),
      ],
    );

    if (compact) {
      return AdminCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AssetThumb(c.imageAsset, width: double.infinity, height: 140, radius: 14),
            const SizedBox(height: 10),
            info,
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerRight, child: actions),
          ],
        ),
      );
    }
    return AdminCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AssetThumb(c.imageAsset, width: 150, height: 122, radius: 14),
          const SizedBox(width: 16),
          Expanded(child: info),
          const SizedBox(width: 12),
          actions,
        ],
      ),
    );
  }
}
