import 'package:flutter/foundation.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/features/campaign/data/datasources/campaign_manage_api.dart';
import 'package:sadaqo/features/campaign/data/models/campaign_model.dart';

enum SubmissionStatus { pending, approved, rejected }

/// Pengajuan kampanye/program yang menunggu verifikasi admin
/// (dari pihak luar atau dari Pengelola Kampanye).
class CampaignSubmission {
  const CampaignSubmission({
    required this.id,
    required this.title,
    required this.category,
    required this.organizer,
    required this.location,
    required this.description,
    required this.targetAmount,
    required this.durationDays,
    required this.submittedAt,
    this.imageAsset,
    this.imageBytes,
    this.subType,
    this.supportingInfo,
    this.ownerId,
    this.campaignId,
    this.status = SubmissionStatus.pending,
    this.note,
  });

  final String id;
  final String title;
  final ProgramCategory category;
  final String organizer;
  final String location;
  final String description;
  final int targetAmount;
  final int durationDays;
  final DateTime submittedAt;

  /// Gambar bawaan ("assets/...") atau URL gambar unggahan dari server.
  final String? imageAsset;

  /// Foto sampul dari galeri pengelola (hanya untuk pratinjau lokal).
  final Uint8List? imageBytes;
  final String? subType;

  /// Penanggung jawab, kontak, dan dokumen pendukung dari pengelola.
  final String? supportingInfo;

  /// Id akun pengelola yang mengajukan (null = pihak luar).
  final String? ownerId;

  /// Id program setelah pengajuan disetujui.
  final String? campaignId;
  final SubmissionStatus status;
  final String? note;

  CampaignSubmission copyWith({
    SubmissionStatus? status,
    String? note,
    String? campaignId,
  }) =>
      CampaignSubmission(
        id: id,
        title: title,
        category: category,
        organizer: organizer,
        location: location,
        description: description,
        targetAmount: targetAmount,
        durationDays: durationDays,
        submittedAt: submittedAt,
        imageAsset: imageAsset,
        imageBytes: imageBytes,
        subType: subType,
        supportingInfo: supportingInfo,
        ownerId: ownerId,
        campaignId: campaignId ?? this.campaignId,
        status: status ?? this.status,
        note: note ?? this.note,
      );
}

/// Pengajuan program, sekarang bersumber dari backend Laravel.
/// - Sisi admin: antrean (pending) dan yang ditolak dari GET /api/admin/campaigns.
/// - Sisi pengelola: semua program miliknya dari GET /api/campaigns/mine.
class AdminVerificationStore extends ChangeNotifier {
  AdminVerificationStore(this._api);

  final CampaignManageApi _api;

  List<CampaignSubmission> _admin = const [];
  final List<CampaignSubmission> _approvedThisSession = [];
  List<CampaignSubmission> _mine = const [];
  List<CampaignModel> _mineActive = const [];

  // ---------- Sisi admin ----------
  List<CampaignSubmission> get all =>
      List.unmodifiable([..._admin, ..._approvedThisSession]);

  int get pendingCount =>
      _admin.where((s) => s.status == SubmissionStatus.pending).length;

  Future<void> loadForAdmin() async {
    try {
      final pending = await _api.list('/admin/campaigns', query: {'status': 'pending'});
      final rejected = await _api.list('/admin/campaigns', query: {'status': 'rejected'});
      _admin = [...pending, ...rejected].map(_toSubmission).toList()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      notifyListeners();
    } on ServerException {
      // Biarkan data lama; admin bisa membuka ulang halaman untuk mencoba lagi.
    }
  }

  Future<void> approve(String id) async {
    await _api.review(id, approve: true);
    final i = _admin.indexWhere((s) => s.id == id);
    if (i >= 0) {
      final s = _admin[i];
      _approvedThisSession.insert(
        0,
        s.copyWith(
          status: SubmissionStatus.approved,
          note: 'Disetujui, program $id aktif',
          campaignId: id,
        ),
      );
      _admin = List.of(_admin)..removeAt(i);
    }
    notifyListeners();
  }

  Future<void> reject(String id, String reason) async {
    await _api.review(id, approve: false, note: reason);
    final i = _admin.indexWhere((s) => s.id == id);
    if (i >= 0) {
      _admin = List.of(_admin)
        ..[i] = _admin[i].copyWith(status: SubmissionStatus.rejected, note: reason);
    }
    notifyListeners();
  }

  // ---------- Sisi pengelola ----------
  List<CampaignSubmission> get mine => List.unmodifiable(_mine);

  /// Program milik pengelola yang sudah aktif.
  List<CampaignModel> get mineActivePrograms => List.unmodifiable(_mineActive);

  Future<void> loadForPengelola() async {
    try {
      final rows = await _api.list('/campaigns/mine');
      _mine = rows.map(_toSubmission).toList();
      _mineActive = [
        for (final j in rows)
          if (j['status'] == 'active') CampaignModel.fromJson(j),
      ];
      notifyListeners();
    } on ServerException {
      // Biarkan data lama.
    }
  }

  /// Mengirim pengajuan baru, atau memperbaiki pengajuan yang ditolak ([editingId]).
  /// Melempar ServerException bila server menolak.
  Future<void> submit({
    required String title,
    required ProgramCategory category,
    required String location,
    required String description,
    required int targetAmount,
    required int durationDays,
    required String supportingInfo,
    Uint8List? cover,
    String? editingId,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'category': category.key,
      'description': description,
      'location': location,
      'target_amount': targetAmount,
      'supporting_info': supportingInfo,
    };
    if (cover != null) {
      body['image_asset_id'] = await _api.uploadImage(cover);
    }
    if (editingId == null) {
      body['duration_days'] = durationDays;
      await _api.create(body);
    } else {
      body['deadline'] =
          DateTime.now().add(Duration(days: durationDays)).toUtc().toIso8601String();
      await _api.update(editingId, body);
    }
    await loadForPengelola();
  }

  // ---------- Pemetaan ----------
  CampaignSubmission _toSubmission(Map<String, dynamic> j) {
    final m = CampaignModel.fromJson(j);
    final created = DateTime.tryParse('${j['created_at']}') ?? DateTime.now();
    final days = m.deadline.difference(created).inDays;
    final status = switch (j['status']) {
      'pending' => SubmissionStatus.pending,
      'rejected' => SubmissionStatus.rejected,
      _ => SubmissionStatus.approved, // active / closed
    };
    return CampaignSubmission(
      id: m.id,
      title: m.title,
      category: m.category,
      organizer: 'Pengelola Kampanye',
      location: m.location,
      description: m.description,
      targetAmount: m.targetAmount,
      durationDays: days < 1 ? 1 : days,
      submittedAt: created,
      imageAsset: m.imageAsset,
      subType: m.subType,
      supportingInfo: j['supporting_info'] as String?,
      ownerId: j['owner_id']?.toString(),
      campaignId: status == SubmissionStatus.approved ? m.id : null,
      status: status,
      note: j['review_note'] as String?,
    );
  }
}