import 'package:flutter/foundation.dart';
import 'package:sadaqo/admin/data/admin_verification_store.dart';
import 'package:sadaqo/features/campaign/data/models/campaign_model.dart';
import 'package:sadaqo/features/report/domain/entities/campaign_report.dart';
import 'package:sadaqo/features/report/domain/repositories/report_repository.dart';

/// Status program dari sisi pengelola (terkait dokumentasi).
enum ProgramDocStatus {
  active('Aktif'),
  awaitingDocs('Menunggu Dokumen'),
  underReview('Menunggu Pemeriksaan'),
  needsRevision('Perlu Revisi');

  const ProgramDocStatus(this.label);
  final String label;
}

/// Data dashboard pengelola. Program dan pengajuan berasal dari backend
/// (lewat AdminVerificationStore). Laporan dokumentasi masih data contoh.
/// Jumlah donatur dan grafik mingguan masih perkiraan/contoh.
class PengelolaStore {
  PengelolaStore(this._reports, this._submissions);

  final ReportRepository _reports;
  final AdminVerificationStore _submissions;

  /// Gabungan perubahan laporan dan pengajuan, untuk ListenableBuilder.
  late final Listenable changes = Listenable.merge([_reports, _submissions]);

  /// Rata-rata donasi per donatur untuk memperkirakan jumlah donatur (contoh).
  static const int _averageDonation = 90000;

  /// Donasi 7 hari terakhir dalam jutaan rupiah (contoh).
  static const List<double> weeklyDonationMillions = [2.4, 4.6, 3.9, 6.2, 6.4, 8.2, 7.4];
  static const List<String> weekdayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  /// Muat program dan pengajuan milik pengelola dari server.
  Future<void> load() => _submissions.loadForPengelola();

  // ---------- Pengajuan kampanye ----------
  List<CampaignSubmission> get mySubmissions => _submissions.mine;

  int get submissionPendingCount =>
      mySubmissions.where((s) => s.status == SubmissionStatus.pending).length;

  /// Pengajuan yang dikembalikan admin dan perlu diperbaiki.
  int get submissionRevisionCount =>
      mySubmissions.where((s) => s.status == SubmissionStatus.rejected).length;

  // ---------- Program ----------
  List<CampaignModel> get programs => _submissions.mineActivePrograms;

  bool owns(String campaignId) => programs.any((c) => c.id == campaignId);

  ProgramDocStatus statusOf(String campaignId) {
    final reports = _reports.byCampaign(campaignId); // terbaru di atas
    if (reports.isNotEmpty) {
      switch (reports.first.status) {
        case ReportStatus.revision:
          return ProgramDocStatus.needsRevision;
        case ReportStatus.pending:
          return ProgramDocStatus.underReview;
        case ReportStatus.approved:
          return ProgramDocStatus.active;
      }
    }
    return ProgramDocStatus.active;
  }

  int get totalPrograms => programs.length;
  int get totalDonation => programs.fold(0, (sum, c) => sum + c.collectedAmount);
  int donorsOf(CampaignModel c) => (c.collectedAmount / _averageDonation).round();
  int get totalDonors => programs.fold(0, (sum, c) => sum + donorsOf(c));

  // ---------- Dokumentasi ----------
  /// Laporan milik program pengelola, terbaru di atas.
  List<CampaignReport> get myReports =>
      _reports.all.where((r) => owns(r.campaignId)).toList();

  int get revisionCount =>
      myReports.where((r) => r.status == ReportStatus.revision).length;
  int get pendingReviewCount =>
      myReports.where((r) => r.status == ReportStatus.pending).length;
  int get awaitingDocsCount => programs
      .where((p) => statusOf(p.id) == ProgramDocStatus.awaitingDocs)
      .length;

  /// Jumlah program yang butuh dokumentasi dari pengelola.
  int get attentionCount => revisionCount + awaitingDocsCount;
}