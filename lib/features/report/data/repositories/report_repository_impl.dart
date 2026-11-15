import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/features/campaign/data/datasources/campaign_manage_api.dart';
import 'package:sadaqo/features/report/data/models/report_model.dart';
import 'package:sadaqo/features/report/domain/entities/campaign_report.dart';
import 'package:sadaqo/features/report/domain/repositories/report_repository.dart';

/// Laporan penyaluran dari backend Laravel. Penanda "sudah dibaca" disimpan
/// di perangkat.
class ReportRepositoryImpl extends ChangeNotifier implements ReportRepository {
  ReportRepositoryImpl(this._api, [FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final CampaignManageApi _api;
  final FlutterSecureStorage _storage;
  static const _readKey = 'read_reports';

  List<CampaignReport> _items = const [];
  final Set<String> _read = {};
  bool _readLoaded = false;
  bool _loading = false;
  String? _error;

  @override
  List<CampaignReport> get all => List.unmodifiable(_items);

  @override
  int get pendingCount => byStatus(ReportStatus.pending).length;

  @override
  bool get loading => _loading;

  @override
  String? get error => _error;

  // ---------- Memuat ----------
  Future<void> _load(String path) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _ensureRead();
      final rows = await _api.list(path);
      _items = rows.map(reportFromJson).toList();
    } on ServerException catch (e) {
      _error = e.message;
    }
    _loading = false;
    notifyListeners();
  }

  @override
  Future<void> loadForDonor() => _load('/reports');

  @override
  Future<void> loadForPengelola() => _load('/reports/mine');

  @override
  Future<void> loadForAdmin() => _load('/admin/reports');

  // ---------- Membaca ----------
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

  // ---------- Menulis ----------
  @override
  Future<void> submit(CampaignReport report, {required bool isNew}) async {
    final activity = await _photoIds(report.activityPhotos);
    final proof = await _photoIds(report.proofPhotos);
    final d = report.activityDate;
    final body = <String, dynamic>{
      'title': report.title,
      'summary': report.summary,
      'distributed_amount': report.distributedAmount,
      'beneficiaries': report.beneficiaries,
      'activity_date':
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
      'activity_photo_ids': activity,
      'proof_photo_ids': proof,
    };
    if (isNew) {
      body['campaign_id'] = int.tryParse(report.campaignId) ?? report.campaignId;
      await _api.createReport(body);
    } else {
      await _api.updateReport(report.id, body);
    }
    await loadForPengelola();
  }

  /// Foto dari galeri diunggah dulu (grup report); foto lama memakai id yang sudah ada.
  Future<List<int>> _photoIds(List<ReportPhoto> photos) async {
    final ids = <int>[];
    for (final p in photos) {
      if (p.bytes != null) {
        ids.add(await _api.uploadImage(p.bytes!, group: 'report'));
      } else if (p.assetId != null) {
        ids.add(p.assetId!);
      }
    }
    return ids;
  }

  @override
  Future<void> approve(String id) async {
    await _api.reviewReport(id, approve: true);
    await loadForAdmin();
  }

  @override
  Future<void> requestRevision(String id, String note) async {
    await _api.reviewReport(id, approve: false, note: note);
    await loadForAdmin();
  }

  // ---------- Penanda sudah dibaca ----------
  Future<void> _ensureRead() async {
    if (_readLoaded) return;
    _readLoaded = true;
    try {
      final raw = await _storage.read(key: _readKey);
      if (raw != null && raw.isNotEmpty) _read.addAll(raw.split(','));
    } catch (_) {
      // Penyimpanan tidak tersedia: lanjut tanpa penanda tersimpan.
    }
  }

  Future<void> _persistRead() async {
    try {
      await _storage.write(key: _readKey, value: _read.join(','));
    } catch (_) {}
  }

  @override
  bool isRead(String id) => _read.contains(id);

  @override
  void markRead(String id) {
    if (_read.add(id)) {
      notifyListeners();
      _persistRead();
    }
  }

  @override
  int unreadFor(Set<String> campaignIds) =>
      publishedFor(campaignIds).where((r) => !_read.contains(r.id)).length;
}