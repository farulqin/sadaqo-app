import 'package:flutter/foundation.dart';
import 'package:sadaqo/core/constants/app_assets.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/features/report/domain/entities/campaign_report.dart';
import 'package:sadaqo/features/report/domain/repositories/report_repository.dart';

/// Penyimpanan di memori (hilang saat aplikasi ditutup). Isi awal: 2 laporan
/// contoh yang sudah dipublikasikan. Ganti dengan API Laravel nanti.
class ReportRepositoryImpl extends ChangeNotifier implements ReportRepository {
  ReportRepositoryImpl() : _items = _seed() {
    // Laporan contoh dianggap sudah dibaca; hanya laporan baru yang bertanda.
    _read.addAll(_items.map((r) => r.id));
  }

  List<CampaignReport> _items;
  final Set<String> _read = {};

  @override
  List<CampaignReport> get all => List.unmodifiable(_items);

  @override
  int get pendingCount => byStatus(ReportStatus.pending).length;

  @override
  CampaignReport? byId(String id) {
    for (final r in _items) {
      if (r.id == id) return r;
    }
    return null;
  }

  @override
  List<CampaignReport> byCampaign(String campaignId) =>
      _items.where((r) => r.campaignId == campaignId).toList();

  @override
  List<CampaignReport> byStatus(ReportStatus status) =>
      _items.where((r) => r.status == status).toList();

  @override
  List<CampaignReport> publishedFor(Set<String> campaignIds) {
    final list = _items
        .where((r) =>
            r.status == ReportStatus.approved && campaignIds.contains(r.campaignId))
        .toList();
    list.sort((a, b) => (b.publishedAt ?? b.submittedAt)
        .compareTo(a.publishedAt ?? a.submittedAt));
    return list;
  }

  @override
  String nextId() => 'r${_items.length + 1}';

  @override
  void submit(CampaignReport report) {
    final next = report.copyWith(
      status: ReportStatus.pending,
      submittedAt: DateTime.now(),
      clearAdminNote: true,
    );
    _items = [next, ..._items.where((r) => r.id != report.id)];
    notifyListeners();
  }

  @override
  CampaignReport? approve(String id) {
    final r = byId(id);
    if (r == null) return null;
    final now = DateTime.now();
    final updated = r.copyWith(
      status: ReportStatus.approved,
      reviewedAt: now,
      publishedAt: now,
      clearAdminNote: true,
    );
    _replace(updated);
    return updated;
  }

  @override
  CampaignReport? requestRevision(String id, String note) {
    final r = byId(id);
    if (r == null) return null;
    final updated = r.copyWith(
      status: ReportStatus.revision,
      reviewedAt: DateTime.now(),
      adminNote: note,
    );
    _replace(updated);
    return updated;
  }

  void _replace(CampaignReport updated) {
    _items = [for (final r in _items) r.id == updated.id ? updated : r];
    notifyListeners();
  }

  @override
  bool isRead(String id) => _read.contains(id);

  @override
  void markRead(String id) {
    if (_read.add(id)) notifyListeners();
  }

  @override
  int unreadFor(Set<String> campaignIds) =>
      publishedFor(campaignIds).where((r) => !_read.contains(r.id)).length;

  static List<CampaignReport> _seed() {
    final now = DateTime.now();
    return [
      CampaignReport(
        id: 'r2',
        campaignId: 's1',
        campaignTitle: 'Bantuan Korban Banjir',
        category: ProgramCategory.sosial,
        managerName: 'Pengelola SADAQO',
        title: 'Penyaluran Logistik dan Air Bersih untuk Pengungsi',
        summary:
            'Dana disalurkan untuk paket makanan siap saji, air bersih, selimut, dan obat-obatan bagi 210 keluarga di tiga titik pengungsian. Distribusi dilakukan bersama relawan lokal dan diterima langsung oleh kepala keluarga.',
        distributedAmount: 30000000,
        beneficiaries: 210,
        activityDate: now.subtract(const Duration(days: 9)),
        submittedAt: now.subtract(const Duration(days: 7)),
        reviewedAt: now.subtract(const Duration(days: 6)),
        publishedAt: now.subtract(const Duration(days: 6)),
        status: ReportStatus.approved,
        activityPhotos: [ReportPhoto.asset(AppAssets.sosial('banjir.jpg'))],
        proofPhotos: [ReportPhoto.asset(AppAssets.duafa('fakir_miskin.jpg'))],
      ),
      CampaignReport(
        id: 'r1',
        campaignId: 'm1',
        campaignTitle: 'Pembangunan Masjid Al-Azzam',
        category: ProgramCategory.masjid,
        managerName: 'Pengelola SADAQO',
        title: 'Laporan Tahap 1: Serambi dan Tempat Wudhu',
        summary:
            'Tahap pertama pembangunan selesai: pondasi serambi, pemasangan lantai, dan tempat wudhu baru yang ramah lansia. Dana dipakai untuk material, upah tukang, dan perlengkapan keselamatan kerja.',
        distributedAmount: 45000000,
        beneficiaries: 320,
        activityDate: now.subtract(const Duration(days: 20)),
        submittedAt: now.subtract(const Duration(days: 18)),
        reviewedAt: now.subtract(const Duration(days: 16)),
        publishedAt: now.subtract(const Duration(days: 16)),
        status: ReportStatus.approved,
        activityPhotos: [
          ReportPhoto.asset(AppAssets.masjid('masjid_al_azzam.jpg')),
          ReportPhoto.asset(AppAssets.masjid('masjid_al_bayan.jpg')),
        ],
        proofPhotos: [ReportPhoto.asset(AppAssets.masjid('masjid_ar_raihan.jpg'))],
      ),
    ];
  }
}