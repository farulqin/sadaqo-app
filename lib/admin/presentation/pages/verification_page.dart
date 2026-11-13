import 'package:flutter/material.dart';
import 'package:sadaqo/admin/core/admin_utils.dart';
import 'package:sadaqo/admin/data/admin_activity_log.dart';
import 'package:sadaqo/admin/data/admin_verification_store.dart';
import 'package:sadaqo/admin/presentation/widgets/admin_widgets.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_cubit.dart';
import 'package:sadaqo/injection_container.dart';
import 'package:sadaqo/core/error/exceptions.dart';

/// Antrean verifikasi kampanye. Menyetujui = program langsung tampil di aplikasi.
class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final _store = sl<AdminVerificationStore>();
  final _log = sl<AdminActivityLog>();
  SubmissionStatus? _filter = SubmissionStatus.pending;

  @override
  void initState() {
    super.initState();
    _store.loadForAdmin();
  }

  Future<void> _approve(CampaignSubmission s) async {
    final ok = await confirmDialog(
      context,
      title: 'Setujui kampanye?',
      message: '"${s.title}" akan langsung tampil sebagai program di aplikasi pengguna.',
      confirmLabel: 'Setujui',
    );
    if (!ok || !mounted) return;
    try {
      await _store.approve(s.id);
    } on ServerException catch (e) {
      if (mounted) adminToast(context, e.message);
      return;
    }
    sl<CampaignCubit>().refresh();
    _log.add(ActivityKind.verified, 'Program "${s.title}" berhasil diverifikasi');
    if (!mounted) return;
    adminToast(context, 'Disetujui. Program sudah aktif di aplikasi donatur.');
  }

  Future<void> _reject(CampaignSubmission s) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak / minta revisi'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Tulis alasan atau bagian yang perlu direvisi (wajib)',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AdminColors.danger),
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx, controller.text.trim());
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || !mounted) return;
    try {
      await _store.reject(s.id, reason);
    } on ServerException catch (e) {
      if (mounted) adminToast(context, e.message);
      return;
    }
    _log.add(ActivityKind.verified, 'Pengajuan "${s.title}" ditolak');
    if (!mounted) return;
    adminToast(context, 'Pengajuan ditolak');
}

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final all = _store.all;
        final items = _filter == null ? all : all.where((s) => s.status == _filter).toList();
        int count(SubmissionStatus? st) =>
            st == null ? all.length : all.where((s) => s.status == st).length;
        return LayoutBuilder(
          builder: (context, c) {
            final pad = c.maxWidth < 600 ? 14.0 : 24.0;
            return ListView(
              padding: EdgeInsets.fromLTRB(pad, 4, pad, 24),
              children: [
                const PageHeader(
                  title: 'Verifikasi Kampanye',
                  subtitle: 'Periksa pengajuan program sebelum tampil di aplikasi.',
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip('Menunggu (${count(SubmissionStatus.pending)})', SubmissionStatus.pending),
                      _chip('Disetujui (${count(SubmissionStatus.approved)})', SubmissionStatus.approved),
                      _chip('Ditolak (${count(SubmissionStatus.rejected)})', SubmissionStatus.rejected),
                      _chip('Semua (${count(null)})', null),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (items.isEmpty)
                  const AdminCard(
                    child: EmptyState(icon: Icons.task_alt_rounded, text: 'Tidak ada pengajuan di sini'),
                  )
                else
                  for (final s in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SubmissionCard(
                        s: s,
                        compact: c.maxWidth < 760,
                        onApprove: () => _approve(s),
                        onReject: () => _reject(s),
                      ),
                    ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _chip(String label, SubmissionStatus? value) {
    final selected = _filter == value;
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
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({
    required this.s,
    required this.compact,
    required this.onApprove,
    required this.onReject,
  });

  final CampaignSubmission s;
  final bool compact;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final pending = s.status == SubmissionStatus.pending;
    final statusPill = switch (s.status) {
      SubmissionStatus.pending => const Pill('Menunggu', color: AdminColors.warn),
      SubmissionStatus.approved => const Pill('Disetujui', color: AdminColors.green),
      SubmissionStatus.rejected => const Pill('Ditolak', color: AdminColors.danger),
    };
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            statusPill,
            if (s.ownerId != null) const Pill('Dari Pengelola', color: AdminColors.green),
            Pill(s.category.shortLabel, color: AdminColors.green, bg: AdminColors.limeSoft),
            Pill(AdminFmt.ago(s.submittedAt), color: AdminColors.muted),
          ],
        ),
        const SizedBox(height: 8),
        Text(s.title, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          '${s.organizer} • ${s.location}',
          style: const TextStyle(fontSize: 12.5, color: AdminColors.muted),
        ),
        const SizedBox(height: 8),
        Text(s.description, maxLines: 3, overflow: TextOverflow.ellipsis),
        if (s.supportingInfo != null) ...[
          const SizedBox(height: 6),
          Text(
            'Info pendukung: ${s.supportingInfo}',
            style: const TextStyle(fontSize: 12.5, color: AdminColors.muted),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'Target ${AdminFmt.rupiah(s.targetAmount)} • ${s.durationDays} hari',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        if (s.note != null) ...[
          const SizedBox(height: 6),
          Text('Catatan: ${s.note}', style: const TextStyle(fontSize: 12.5, color: AdminColors.muted)),
        ],
        if (pending) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AdminButton(label: 'Setujui', icon: Icons.check_circle_outline_rounded, onPressed: onApprove),
              AdminButton(label: 'Tolak', icon: Icons.close_rounded, outlined: true, danger: true, onPressed: onReject),
            ],
          ),
        ],
      ],
    );
    if (compact) {
      return AdminCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Cover(s, width: double.infinity, height: 140),
            const SizedBox(height: 10),
            info,
          ],
        ),
      );
    }
    return AdminCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Cover(s, width: 170, height: 150),
          const SizedBox(width: 16),
          Expanded(child: info),
        ],
      ),
    );
  }
}
  /// Sampul pengajuan: foto galeri pengelola jika ada, selain itu aset.
  class _Cover extends StatelessWidget {
    const _Cover(this.s, {required this.width, required this.height});

    final CampaignSubmission s;
    final double width;
    final double height;

    @override
    Widget build(BuildContext context) {
      if (s.imageBytes != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(s.imageBytes!, width: width, height: height, fit: BoxFit.cover),
        );
      }
      return AssetThumb(s.imageAsset, width: width, height: height, radius: 14);
    }
  }
