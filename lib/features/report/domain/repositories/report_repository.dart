import 'package:flutter/foundation.dart';
import 'package:sadaqo/features/report/domain/entities/campaign_report.dart';

/// Kontrak data laporan. Saat backend Laravel siap, buat implementasi baru
/// berbasis Dio; halaman pengelola, admin, dan donatur tidak perlu diubah.
abstract class ReportRepository implements Listenable {
  /// Semua laporan, terbaru di atas.
  List<CampaignReport> get all;
  int get pendingCount;

  CampaignReport? byId(String id);
  List<CampaignReport> byCampaign(String campaignId);
  List<CampaignReport> byStatus(ReportStatus status);

  /// Laporan yang sudah dipublikasikan untuk program-program tertentu
  /// (dipakai donatur: program yang pernah ia danai).
  List<CampaignReport> publishedFor(Set<String> campaignIds);

  String nextId();

  /// Pengelola mengirim laporan baru atau kirim ulang setelah revisi.
  void submit(CampaignReport report);

  /// Admin menyetujui = laporan tampil ke donatur.
  CampaignReport? approve(String id);

  /// Admin meminta revisi dengan catatan.
  CampaignReport? requestRevision(String id, String note);

  bool isRead(String id);
  void markRead(String id);
  int unreadFor(Set<String> campaignIds);
}