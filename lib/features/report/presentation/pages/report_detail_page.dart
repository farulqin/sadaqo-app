import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/features/report/domain/entities/campaign_report.dart';
import 'package:sadaqo/features/report/domain/repositories/report_repository.dart';
import 'package:sadaqo/features/report/presentation/widgets/report_widgets.dart';
import 'package:sadaqo/injection_container.dart';

/// Detail laporan. Donatur: otomatis ditandai sudah dibaca.
/// Pengelola: [markAsRead] false dan [showAdminNote] true.
class ReportDetailPage extends StatefulWidget {
  const ReportDetailPage({
    super.key,
    required this.report,
    this.markAsRead = true,
    this.showAdminNote = false,
  });

  final CampaignReport report;
  final bool markAsRead;
  final bool showAdminNote;

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  @override
  void initState() {
    super.initState();
    if (widget.markAsRead) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => sl<ReportRepository>().markRead(widget.report.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan & Dokumentasi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ReportDetailBody(report: widget.report, showAdminNote: widget.showAdminNote),
          if (widget.report.status == ReportStatus.approved) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_rounded, color: AppColors.success),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Laporan ini sudah diperiksa Admin SADAQO sebelum ditampilkan.',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}