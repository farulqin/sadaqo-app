import 'dart:typed_data';

import 'package:sadaqo/core/constants/program_category.dart';

enum ReportStatus {
  pending('Menunggu Pemeriksaan'),
  approved('Dipublikasikan'),
  revision('Perlu Revisi');

  const ReportStatus(this.label);
  final String label;
}

/// Foto laporan: dari aset (data contoh) atau dari galeri (bytes).
class ReportPhoto {
  const ReportPhoto.asset(String path)
      : asset = path,
        bytes = null;
  const ReportPhoto.memory(Uint8List data)
      : bytes = data,
        asset = null;

  final String? asset;
  final Uint8List? bytes;
}

/// Laporan & dokumentasi penyaluran dari pengelola. Tampil ke donatur
/// hanya setelah diperiksa dan disetujui admin.
class CampaignReport {
  const CampaignReport({
    required this.id,
    required this.campaignId,
    required this.campaignTitle,
    required this.category,
    required this.managerName,
    required this.title,
    required this.summary,
    required this.distributedAmount,
    required this.beneficiaries,
    required this.activityDate,
    required this.submittedAt,
    this.activityPhotos = const [],
    this.proofPhotos = const [],
    this.status = ReportStatus.pending,
    this.adminNote,
    this.reviewedAt,
    this.publishedAt,
  });

  final String id;
  final String campaignId;
  final String campaignTitle;
  final ProgramCategory category;
  final String managerName;
  final String title;
  final String summary;
  final int distributedAmount;
  final int beneficiaries;
  final DateTime activityDate;
  final DateTime submittedAt;
  final List<ReportPhoto> activityPhotos;
  final List<ReportPhoto> proofPhotos;
  final ReportStatus status;

  /// Catatan admin saat meminta revisi.
  final String? adminNote;
  final DateTime? reviewedAt;
  final DateTime? publishedAt;

  CampaignReport copyWith({
    DateTime? submittedAt,
    ReportStatus? status,
    String? adminNote,
    bool clearAdminNote = false,
    DateTime? reviewedAt,
    DateTime? publishedAt,
  }) {
    return CampaignReport(
      id: id,
      campaignId: campaignId,
      campaignTitle: campaignTitle,
      category: category,
      managerName: managerName,
      title: title,
      summary: summary,
      distributedAmount: distributedAmount,
      beneficiaries: beneficiaries,
      activityDate: activityDate,
      submittedAt: submittedAt ?? this.submittedAt,
      activityPhotos: activityPhotos,
      proofPhotos: proofPhotos,
      status: status ?? this.status,
      adminNote: clearAdminNote ? null : (adminNote ?? this.adminNote),
      reviewedAt: reviewedAt ?? this.reviewedAt,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }
}