import 'package:flutter/material.dart';
import 'package:sadaqo/admin/core/admin_utils.dart';
import 'package:sadaqo/admin/data/admin_activity_log.dart';
import 'package:sadaqo/admin/presentation/widgets/admin_widgets.dart';
import 'package:sadaqo/features/donation/data/datasources/donation_remote_datasource.dart';
import 'package:sadaqo/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:sadaqo/features/report/domain/entities/campaign_report.dart';
import 'package:sadaqo/features/report/domain/repositories/report_repository.dart';
import 'package:sadaqo/features/report/presentation/widgets/report_widgets.dart';
import 'package:sadaqo/injection_container.dart';

/// Admin memeriksa dokumentasi dari pengelola. Disetujui = tampil ke donatur
/// (di Riwayat > Laporan & Dokumentasi) disertai notifikasi.
class ReportReviewPage extends StatefulWidget {
  const ReportReviewPage({super.key});

  @override
  State<ReportReviewPage> createState() => _ReportReviewPageState();
}

class _ReportReviewPageState extends State<ReportReviewPage> {
  final _repo = sl<ReportRepository>();
  final _log = sl<AdminActivityLog>();
  ReportStatus? _filter = ReportStatus.pending;

  /// Kabari donatur yang pernah mendanai program ini.
  Future<void> _notifyDonors(CampaignReport r) async {
    final history = await sl<DonationRemoteDataSource>().getHistory();
    if (!history.any((d) => d.campaignId == r.campaignId)) return;
    await sl<NotificationCubit>().add(
      title: 'Laporan penyaluran baru',
      body:
          'Pengelola telah melaporkan penyaluran dana untuk "${r.campaignTitle}". Lihat di Riwayat > Laporan & Dokumentasi.',
    );
  }

  Future<bool> _approve(CampaignReport r) async {
    final ok = await confirmDialog(
      context,
      title: 'Tampilkan laporan ke donatur?',
      message:
          '"${r.title}" akan tampil di Riwayat > Laporan & Dokumentasi milik donatur program ini, disertai notifikasi.',
      confirmLabel: 'Setujui & Tampilkan',
    );
    if (!ok || !mounted) return false;
    final updated = _repo.approve(r.id);
    if (updated == null) return false;
    _log.add(ActivityKind.verified, 'Laporan "${r.title}" dipublikasikan ke donatur');
    adminToast(context, 'Laporan dipublikasikan ke donatur');
    await _notifyDonors(updated);
    return true;
  }

  Future<bool> _revise(CampaignReport r) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Minta revisi'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Tulis bagian yang perlu diperbaiki (wajib)',
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
            child: const Text('Kirim Revisi'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (note == null || !mounted) return false;
    _repo.requestRevision(r.id, note);
    _log.add(ActivityKind.verified, 'Laporan "${r.title}" diminta revisi');
    adminToast(context, 'Permintaan revisi dikirim ke pengelola');
    return true;
  }

  void _open(CampaignReport r) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ReportReviewDetail(
          reportId: r.id,
          onApprove: _approve,
          onRevise: _revise,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _repo,
      builder: (context, _) {
        final all = _repo.all;
        final items = _filter == null ? all : all.where((r) => r.status == _filter).toList();
        int count(ReportStatus? s) => s == null ? all.length : all.where((r) => r.status == s).length;
        return LayoutBuilder(
          builder: (context, c) {
            final pad = c.maxWidth < 600 ? 14.0 : 24.0;
            return ListView(
              padding: EdgeInsets.fromLTRB(pad, 4, pad, 24),
              children: [
                const PageHeader(
                  title: 'Pemeriksaan Laporan',
                  subtitle: 'Periksa dokumentasi dari pengelola sebelum ditampilkan kepada donatur.',
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip('Menunggu (${count(ReportStatus.pending)})', ReportStatus.pending),
                      _chip('Dipublikasikan (${count(ReportStatus.approved)})', ReportStatus.approved),
                      _chip('Perlu Revisi (${count(ReportStatus.revision)})', ReportStatus.revision),
                      _chip('Semua (${count(null)})', null),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (items.isEmpty)
                  const AdminCard(
                    child: EmptyState(icon: Icons.task_alt_rounded, text: 'Tidak ada laporan di sini'),
                  )
                else
                  for (final r in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ReportCard(report: r, onOpen: () => _open(r)),
                    ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _chip(String label, ReportStatus? value) {
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

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onOpen});

  final CampaignReport report;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final r = report;
    final photo = r.activityPhotos.isEmpty ? null : r.activityPhotos.first;
    final pending = r.status == ReportStatus.pending;
    final statusPill = switch (r.status) {
      ReportStatus.pending => const Pill('Menunggu', color: AdminColors.warn),
      ReportStatus.approved => const Pill('Dipublikasikan', color: AdminColors.green),
      ReportStatus.revision => const Pill('Perlu Revisi', color: AdminColors.danger),
    };
    return AdminCard(
      padding: const EdgeInsets.all(12),
      onTap: onOpen,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photo != null)
            ReportPhotoImage(photo, width: 110, height: 110, radius: 14)
          else
            const AssetThumb(null, width: 110, height: 110, radius: 14),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    statusPill,
                    Pill(r.category.shortLabel, color: AdminColors.green, bg: AdminColors.limeSoft),
                    Pill(AdminFmt.ago(r.submittedAt), color: AdminColors.muted),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  r.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${r.campaignTitle} • ${r.managerName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: AdminColors.muted),
                ),
                const SizedBox(height: 6),
                Text(
                  'Disalurkan ${AdminFmt.rupiah(r.distributedAmount)} • ${r.beneficiaries} penerima',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 10),
                AdminButton(
                  label: pending ? 'Periksa Laporan' : 'Lihat Detail',
                  icon: pending ? Icons.fact_check_rounded : Icons.visibility_outlined,
                  outlined: !pending,
                  onPressed: onOpen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportReviewDetail extends StatelessWidget {
  const _ReportReviewDetail({
    required this.reportId,
    required this.onApprove,
    required this.onRevise,
  });

  final String reportId;
  final Future<bool> Function(CampaignReport) onApprove;
  final Future<bool> Function(CampaignReport) onRevise;

  @override
  Widget build(BuildContext context) {
    final repo = sl<ReportRepository>();
    final r = repo.byId(reportId);
    if (r == null) {
      return const Scaffold(body: Center(child: Text('Laporan tidak ditemukan')));
    }
    final pending = r.status == ReportStatus.pending;
    return Scaffold(
      backgroundColor: AdminColors.page,
      appBar: AppBar(title: const Text('Pemeriksaan Laporan')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ReportDetailBody(report: r, showAdminNote: true),
              const SizedBox(height: 16),
              Text(
                'Dikirim ${AdminFmt.dateTime(r.submittedAt)}',
                style: const TextStyle(fontSize: 12, color: AdminColors.muted),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: pending
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: AdminButton(
                        label: 'Minta Revisi',
                        icon: Icons.edit_note_rounded,
                        outlined: true,
                        danger: true,
                        onPressed: () async {
                          final done = await onRevise(r);
                          if (done && context.mounted) Navigator.of(context).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: AdminButton(
                        label: 'Setujui & Tampilkan',
                        icon: Icons.check_circle_outline_rounded,
                        onPressed: () async {
                          final done = await onApprove(r);
                          if (done && context.mounted) Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}