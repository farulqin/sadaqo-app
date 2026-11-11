import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/utils/formatter.dart';
import 'package:sadaqo/core/widgets/program_image.dart';
import 'package:sadaqo/features/report/domain/entities/campaign_report.dart';
import 'package:sadaqo/features/report/domain/repositories/report_repository.dart';
import 'package:sadaqo/features/report/presentation/pages/report_detail_page.dart';
import 'package:sadaqo/features/report/presentation/widgets/report_widgets.dart';
import 'package:sadaqo/injection_container.dart';
import 'package:sadaqo/pengelola/data/pengelola_store.dart';
import 'package:sadaqo/pengelola/presentation/widgets/pengelola_widgets.dart';

/// Riwayat dokumentasi yang dikirim pengelola + status pemeriksaan admin.
class PengelolaDocsPage extends StatefulWidget {
  const PengelolaDocsPage({super.key, required this.onSend, required this.onRevise});

  final VoidCallback onSend;
  final ValueChanged<CampaignReport> onRevise;

  @override
  State<PengelolaDocsPage> createState() => _PengelolaDocsPageState();
}

class _PengelolaDocsPageState extends State<PengelolaDocsPage> {
  ReportStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final store = sl<PengelolaStore>();
    return Scaffold(
      appBar: AppBar(title: const Text('Dokumentasi')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onSend,
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('Kirim Dokumentasi'),
      ),
      body: ListenableBuilder(
        listenable: sl<ReportRepository>(),
        builder: (context, _) {
          final all = store.myReports;
          final items = _filter == null ? all : all.where((r) => r.status == _filter).toList();
          int count(ReportStatus? s) =>
              s == null ? all.length : all.where((r) => r.status == s).length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.success),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Admin memeriksa dokumentasi sebelum laporan ditampilkan kepada donatur.',
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip('Semua (${count(null)})', null),
                    _chip('Menunggu (${count(ReportStatus.pending)})', ReportStatus.pending),
                    _chip('Perlu Revisi (${count(ReportStatus.revision)})', ReportStatus.revision),
                    _chip('Dipublikasikan (${count(ReportStatus.approved)})', ReportStatus.approved),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(Icons.description_outlined, size: 52, color: AppColors.textMuted),
                      SizedBox(height: 8),
                      Text('Belum ada dokumentasi', style: TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                )
              else
                for (final r in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ReportCard(report: r, onRevise: () => widget.onRevise(r)),
                  ),
            ],
          );
        },
      ),
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
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: AppColors.forestGreen,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onRevise});

  final CampaignReport report;
  final VoidCallback onRevise;

  @override
  Widget build(BuildContext context) {
    final photo = report.activityPhotos.isEmpty ? null : report.activityPhotos.first;
    return SoftCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ReportDetailPage(report: report, markAsRead: false, showAdminNote: true),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                photo == null
                    ? ProgramImage(
                        category: report.category,
                        width: 64,
                        height: 64,
                        borderRadius: BorderRadius.circular(12),
                      )
                    : ReportPhotoImage(photo, width: 64, height: 64),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ReportStatusPill(report.status),
                      const SizedBox(height: 4),
                      Text(
                        report.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        report.campaignTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      Text(
                        'Dikirim ${Formatter.date(report.submittedAt)} • ${Formatter.rupiah(report.distributedAmount)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (report.status == ReportStatus.revision) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8DEDB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Catatan admin: ${report.adminNote ?? '-'}',
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRevise,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Perbaiki & Kirim Ulang'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.forestGreen,
                    side: const BorderSide(color: AppColors.forestGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}