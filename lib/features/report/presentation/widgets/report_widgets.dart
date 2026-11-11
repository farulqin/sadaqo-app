import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/utils/formatter.dart';
import 'package:sadaqo/features/donation/domain/entities/donation.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_history_cubit.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_history_state.dart';
import 'package:sadaqo/features/report/domain/entities/campaign_report.dart';
import 'package:sadaqo/features/report/domain/repositories/report_repository.dart';
import 'package:sadaqo/injection_container.dart';

/// Id program yang pernah didanai donatur (laporan hanya tampil untuk program ini).
Set<String> donatedCampaignIds(List<Donation> donations) =>
    {for (final d in donations) d.campaignId};

Color reportStatusColor(ReportStatus s) {
  switch (s) {
    case ReportStatus.pending:
      return const Color(0xFFC27B12);
    case ReportStatus.approved:
      return AppColors.success;
    case ReportStatus.revision:
      return AppColors.error;
  }
}

class ReportStatusPill extends StatelessWidget {
  const ReportStatusPill(this.status, {super.key});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final c = reportStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: c),
      ),
    );
  }
}

/// Foto laporan (aset atau galeri). Ketuk untuk memperbesar jika [onTap] diisi.
class ReportPhotoImage extends StatelessWidget {
  const ReportPhotoImage(
    this.photo, {
    super.key,
    this.width,
    this.height,
    this.radius = 12,
    this.fit = BoxFit.cover,
    this.onTap,
  });

  final ReportPhoto photo;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;
  final VoidCallback? onTap;

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: AppColors.sandBeige,
        child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted),
      );

  @override
  Widget build(BuildContext context) {
    final Widget image = photo.bytes != null
        ? Image.memory(photo.bytes!, width: width, height: height, fit: fit)
        : Image.asset(
            photo.asset!,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, e, s) => _placeholder(),
          );
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(borderRadius: BorderRadius.circular(radius), child: image),
    );
  }
}

void showReportPhoto(BuildContext context, ReportPhoto photo) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          InteractiveViewer(
            child: Center(child: ReportPhotoImage(photo, fit: BoxFit.contain, radius: 0)),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}

class ReportPhotoStrip extends StatelessWidget {
  const ReportPhotoStrip(this.photos, {super.key});

  final List<ReportPhoto> photos;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const Text('Tidak ada foto', style: TextStyle(color: AppColors.textMuted));
    }
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (context, i) => const SizedBox(width: 8),
        itemBuilder: (context, i) => ReportPhotoImage(
          photos[i],
          width: 160,
          height: 120,
          onTap: () => showReportPhoto(context, photos[i]),
        ),
      ),
    );
  }
}

/// Isi detail laporan. Dipakai donatur, pengelola, dan admin.
class ReportDetailBody extends StatelessWidget {
  const ReportDetailBody({super.key, required this.report, this.showAdminNote = false});

  final CampaignReport report;
  final bool showAdminNote;

  @override
  Widget build(BuildContext context) {
    final r = report;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReportStatusPill(r.status),
        const SizedBox(height: 10),
        Text(
          r.title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.25),
        ),
        const SizedBox(height: 4),
        Text(
          '${r.campaignTitle} • oleh ${r.managerName}',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                icon: Icons.event_rounded,
                label: 'Tanggal Kegiatan',
                value: Formatter.date(r.activityDate),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InfoTile(
                icon: Icons.payments_rounded,
                label: 'Dana Disalurkan',
                value: Formatter.rupiah(r.distributedAmount),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InfoTile(
                icon: Icons.groups_rounded,
                label: 'Penerima Manfaat',
                value: '${r.beneficiaries} orang',
              ),
            ),
          ],
        ),
        if (showAdminNote && r.status == ReportStatus.revision && r.adminNote != null) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8DEDB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catatan Admin',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.error),
                ),
                const SizedBox(height: 4),
                Text(r.adminNote!),
              ],
            ),
          ),
        ],
        const _SectionTitle('Laporan Penyaluran'),
        Text(r.summary, style: const TextStyle(height: 1.5)),
        const _SectionTitle('Foto Kegiatan'),
        ReportPhotoStrip(r.activityPhotos),
        const _SectionTitle('Bukti Penyaluran'),
        ReportPhotoStrip(r.proofPhotos),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.sandBeige),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.forestGreen),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          ),
          Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

/// Titik angka untuk laporan baru yang belum dibuka donatur
/// (dipasang di ikon Riwayat dan tab Laporan & Dokumentasi).
class ReportUnreadBadge extends StatelessWidget {
  const ReportUnreadBadge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DonationHistoryCubit, DonationHistoryState>(
      builder: (context, state) {
        final repo = sl<ReportRepository>();
        return ListenableBuilder(
          listenable: repo,
          builder: (context, _) {
            final n = state is DonationHistoryLoaded
                ? repo.unreadFor(donatedCampaignIds(state.donations))
                : 0;
            return Badge(isLabelVisible: n > 0, label: Text('$n'), child: child);
          },
        );
      },
    );
  }
}