import 'package:flutter/foundation.dart';
import 'package:sadaqo/features/report/domain/entities/campaign_report.dart';

/// Kontrak data laporan. Daftar dimuat sesuai peran (donatur / pengelola / admin);
/// pengiriman dan pemeriksaan melempar ServerException bila server menolak.
abstract class ReportRepository implements Listenable {
  /// Semua laporan yang sedang dimuat, terbaru di atas.
  List<CampaignReport> get all;
  int get pendingCount;
  bool get loading;
  String? get error;

  /// Donatur: laporan yang sudah disetujui. Pengelola: laporan miliknya.
  /// Admin: semua laporan.
  Future<void> loadForDonor();
  Future<void> loadForPengelola();
  Future<void> loadForAdmin();

  CampaignReport? byId(String id);
  List<CampaignReport> byCampaign(String campaignId);
  List<CampaignReport> byStatus(ReportStatus status);

  /// Laporan yang sudah dipublikasikan untuk program-program tertentu
  /// (dipakai donatur: program yang pernah ia danai).
  List<CampaignReport> publishedFor(Set<String> campaignIds);

  /// Pengelola mengirim laporan baru ([isNew]) atau mengirim ulang setelah revisi.
  Future<void> submit(CampaignReport report, {required bool isNew});

  /// Admin menyetujui = laporan tampil ke donatur (server memberi notifikasi).
  Future<void> approve(String id);

  /// Admin meminta revisi dengan catatan.
  Future<void> requestRevision(String id, String note);

  bool isRead(String id);
  void markRead(String id);
  int unreadFor(Set<String> campaignIds);
}