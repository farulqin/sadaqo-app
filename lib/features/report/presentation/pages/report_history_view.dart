import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/utils/formatter.dart';
import 'package:sadaqo/core/widgets/program_image.dart';
import 'package:sadaqo/core/widgets/state_views.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_history_cubit.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_history_state.dart';
import 'package:sadaqo/features/report/domain/entities/campaign_report.dart';
import 'package:sadaqo/features/report/domain/repositories/report_repository.dart';
import 'package:sadaqo/features/report/presentation/pages/report_detail_page.dart';
import 'package:sadaqo/features/report/presentation/widgets/report_widgets.dart';
import 'package:sadaqo/injection_container.dart';

/// Riwayat laporan & dokumentasi penyaluran dari program yang pernah didanai.
class ReportHistoryView extends StatelessWidget {
  const ReportHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DonationHistoryCubit, DonationHistoryState>(
      builder: (context, state) {
        if (state is DonationHistoryError) {
          return ErrorView(
            message: state.message,
            onRetry: () => context.read<DonationHistoryCubit>().load(),
          );
        }
        if (state is! DonationHistoryLoaded) return const LoadingView();

        final ids = donatedCampaignIds(state.donations);
        final repo = sl<ReportRepository>();
        return ListenableBuilder(
          listenable: repo,
          builder: (context, _) {
            final items = repo.publishedFor(ids);
            if (items.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.description_outlined, size: 56, color: AppColors.textMuted),
                      SizedBox(height: 10),
                      Text(
                        'Belum ada laporan.\nLaporan dan dokumentasi penyaluran dari program yang kamu bantu akan muncul di sini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (context, i) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _ReportTile(
                report: items[i],
                unread: !repo.isRead(items[i].id),
              ),
            );
          },
        );
      },
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report, required this.unread});

  final CampaignReport report;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final photo = report.activityPhotos.isEmpty ? null : report.activityPhotos.first;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => ReportDetailPage(report: report)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              photo == null
                  ? ProgramImage(
                      category: report.category,
                      width: 72,
                      height: 72,
                      borderRadius: BorderRadius.circular(12),
                    )
                  : ReportPhotoImage(photo, width: 72, height: 72),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (unread)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.limeGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Baru',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forestGreen,
                          ),
                        ),
                      ),
                    Text(
                      report.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      report.campaignTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    Text(
                      'Disalurkan ${Formatter.rupiah(report.distributedAmount)} • ${Formatter.date(report.publishedAt ?? report.submittedAt)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}