import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/features/report/domain/entities/campaign_report.dart';

/// Membaca respons API laporan (ReportResource di backend).
CampaignReport reportFromJson(Map<String, dynamic> j) {
  List<ReportPhoto> photos(dynamic v) => [
        if (v is List)
          for (final p in v)
            if (p is Map && p['ref'] is String && p['asset_id'] is num)
              ReportPhoto.remote(p['ref'] as String, (p['asset_id'] as num).toInt()),
      ];
  DateTime? date(dynamic v) => v is String ? DateTime.tryParse(v) : null;

  final status = switch (j['status']) {
    'approved' => ReportStatus.approved,
    'revision' => ReportStatus.revision,
    _ => ReportStatus.pending,
  };

  return CampaignReport(
    id: '${j['id']}',
    campaignId: '${j['campaign_id']}',
    campaignTitle: (j['campaign_title'] ?? '') as String,
    category: ProgramCategory.fromKey((j['category'] ?? 'masjid') as String),
    managerName: (j['manager_name'] ?? 'Pengelola') as String,
    title: (j['title'] ?? '') as String,
    summary: (j['summary'] ?? '') as String,
    distributedAmount: (j['distributed_amount'] as num?)?.toInt() ?? 0,
    beneficiaries: (j['beneficiaries'] as num?)?.toInt() ?? 0,
    activityDate: date(j['activity_date']) ?? DateTime.now(),
    submittedAt: date(j['submitted_at']) ?? DateTime.now(),
    activityPhotos: photos(j['activity_photos']),
    proofPhotos: photos(j['proof_photos']),
    status: status,
    adminNote: j['admin_note'] as String?,
    reviewedAt: date(j['reviewed_at']),
    publishedAt: date(j['published_at']),
  );
}