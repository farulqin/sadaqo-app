import 'package:flutter/material.dart';
import 'package:sadaqo/admin/data/admin_verification_store.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/utils/formatter.dart';
import 'package:sadaqo/core/widgets/program_image.dart';
import 'package:sadaqo/features/campaign/data/models/campaign_model.dart';
import 'package:sadaqo/injection_container.dart';
import 'package:sadaqo/pengelola/data/pengelola_store.dart';
import 'package:sadaqo/pengelola/presentation/widgets/pengelola_widgets.dart';
import 'package:sadaqo/pengelola/core/pengelola_layout.dart';

/// Pengajuan kampanye + daftar program milik pengelola.
class PengelolaProgramsPage extends StatelessWidget {
  const PengelolaProgramsPage({
    super.key,
    required this.onSendDocs,
    required this.onCreate,
    required this.onEdit,
  });

  final ValueChanged<String> onSendDocs;
  final VoidCallback onCreate;
  final ValueChanged<CampaignSubmission> onEdit;

  @override
  Widget build(BuildContext context) {
    final store = sl<PengelolaStore>();
    return Scaffold(
      appBar: AppBar(title: const Text('Program Saya')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onCreate,
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buat Kampanye'),
      ),
      body: ListenableBuilder(
        listenable: store.changes,
        builder: (context, _) {
          // Pengajuan yang disetujui sudah menjadi program, jadi tidak ditampilkan lagi.
          final subs = store.mySubmissions
              .where((s) => s.status != SubmissionStatus.approved)
              .toList();
          final programs = store.programs;
          return ContentListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            children: [
              if (subs.isNotEmpty) ...[
                const _SectionTitle('Pengajuan Kampanye'),
                ResponsiveGrid(
                  minItemWidth: 420,
                  children: [
                    for (final s in subs)
                      _SubmissionCard(submission: s, onEdit: () => onEdit(s)),
                  ],
                ),
                const SizedBox(height: 22),
              ],
              _SectionTitle('Program Aktif (${programs.length})'),
              ResponsiveGrid(
                minItemWidth: 340,
                children: [
                  for (final p in programs)
                    _ProgramCard(
                      program: p,
                      status: store.statusOf(p.id),
                      donors: store.donorsOf(p),
                      onSendDocs: () => onSendDocs(p.id),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      );
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({required this.submission, required this.onEdit});

  final CampaignSubmission submission;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final s = submission;
    final revision = s.status == SubmissionStatus.rejected;
    final fg = revision ? AppColors.error : const Color(0xFFC27B12);
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              s.imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(s.imageBytes!, width: 72, height: 72, fit: BoxFit.cover),
                    )
                  : ProgramImage(
                      category: s.category,
                      imageAsset: s.imageAsset,
                      width: 72,
                      height: 72,
                      borderRadius: BorderRadius.circular(12),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: fg.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        revision ? 'Perlu Revisi' : 'Menunggu Verifikasi',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${s.category.shortLabel} • Target ${Formatter.rupiah(s.targetAmount)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (revision) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8DEDB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Catatan admin: ${s.note ?? '-'}',
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Perbaiki & Kirim Ulang'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.forestGreen,
                  side: const BorderSide(color: AppColors.forestGreen),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Text(
              'Sedang diperiksa admin. Kampanye tampil di aplikasi setelah disetujui.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.program,
    required this.status,
    required this.donors,
    required this.onSendDocs,
  });

  final CampaignModel program;
  final ProgramDocStatus status;
  final int donors;
  final VoidCallback onSendDocs;

  @override
  Widget build(BuildContext context) {
    final needDocs = status == ProgramDocStatus.awaitingDocs ||
        status == ProgramDocStatus.needsRevision;
    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProgramImage(
            category: program.category,
            imageAsset: program.imageAsset,
            height: 130,
            width: double.infinity,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ProgramStatusChip(status),
                    const SizedBox(width: 6),
                    Text(
                      program.category.shortLabel,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(program.title, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(program.location, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: program.progress,
                    minHeight: 9,
                    backgroundColor: const Color(0xFFE6E0D0),
                    color: const Color(0xFF6FA82B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${Formatter.rupiah(program.collectedAmount)} dari ${Formatter.rupiah(program.targetAmount)} (${program.progressPercent}%)',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Meta(icon: Icons.groups_rounded, text: '$donors donatur'),
                    const SizedBox(width: 16),
                    _Meta(icon: Icons.timer_outlined, text: '${program.daysLeft} hari lagi'),
                  ],
                ),
                if (needDocs) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onSendDocs,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Kirim Dokumentasi'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.forestGreen),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
      ],
    );
  }
}