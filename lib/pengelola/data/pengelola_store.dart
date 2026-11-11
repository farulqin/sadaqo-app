import 'package:flutter/foundation.dart';
import 'package:sadaqo/admin/data/admin_verification_store.dart';
import 'package:sadaqo/features/campaign/data/datasources/mock_campaign_store.dart';
import 'package:sadaqo/features/campaign/data/models/campaign_model.dart';
import 'package:sadaqo/features/report/domain/entities/campaign_report.dart';
import 'package:sadaqo/features/report/domain/repositories/report_repository.dart';
import 'package:sadaqo/pengelola/core/pengelola_config.dart';

/// Status program dari sisi pengelola (terkait dokumentasi).
enum ProgramDocStatus {
  active('Aktif'),
  awaitingDocs('Menunggu Dokumen'),
  underReview('Menunggu Pemeriksaan'),
  needsRevision('Perlu Revisi');

  const ProgramDocStatus(this.label);
  final String label;
}

/// Data dashboard pengelola. Memakai sumber data yang SAMA dengan aplikasi
/// donatur dan admin (MockCampaignStore, ReportRepository, AdminVerificationStore).
/// Jumlah donatur dan grafik mingguan masih contoh; ganti dengan data API nanti.
class PengelolaStore {
  PengelolaStore(this._campaigns, this._reports, this._submissions);

  final MockCampaignStore _campaigns;
  final ReportRepository _reports;
  final AdminVerificationStore _submissions;

  /// Gabungan perubahan laporan dan pengajuan, untuk ListenableBuilder.
  late final Listenable changes = Listenable.merge([_reports, _submissions]);

  /// Program awal milik akun pengelola contoh (di luar yang dibuat lewat form).
  static const List<String> _seedOwnedIds = ['m1', 'd1', 's1', 'm6', 'q6'];

  /// Program yang sudah menyalurkan dana tetapi belum ada dokumentasinya.
  static const Set<String> _awaitingSeed = {'d1', 'm6'};

  /// Rata-rata donasi per donatur untuk memperkirakan jumlah donatur (contoh).
  static const int _averageDonation = 90000;

  /// Donasi 7 hari terakhir dalam jutaan rupiah (contoh).
  static const List<double> weeklyDonationMillions = [2.4, 4.6, 3.9, 6.2, 6.4, 8.2, 7.4];
  static const List<String> weekdayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  // ---------- Pengajuan kampanye (alur 1-3) ----------
  List<CampaignSubmission> get mySubmissions => _submissions.all
      .where((s) => s.ownerId == PengelolaConfig.accountId)
      .toList();

  int get submissionPendingCount =>
      mySubmissions.where((s) => s.status == SubmissionStatus.pending).length;

  /// Pengajuan yang dikembalikan admin dan perlu diperbaiki.
  int get submissionRevisionCount =>
      mySubmissions.where((s) => s.status == SubmissionStatus.rejected).length;

  // ---------- Program ----------
  List<String> get _ownedIds => [
        ..._seedOwnedIds,
        for (final s in mySubmissions)
          if (s.status == SubmissionStatus.approved && s.campaignId != null) s.campaignId!,
      ];

  List<CampaignModel> get programs {
    final list = <CampaignModel>[];
    for (final id in _ownedIds) {
      final c = _campaigns.byId(id);
      if (c != null) list.add(c);
    }
    return list;
  }

  bool owns(String campaignId) => _ownedIds.contains(campaignId);

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
    return _awaitingSeed.contains(campaignId)
        ? ProgramDocStatus.awaitingDocs
        : ProgramDocStatus.active;
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