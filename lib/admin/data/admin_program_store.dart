import 'package:flutter/foundation.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/features/campaign/data/datasources/campaign_manage_api.dart';
import 'package:sadaqo/features/campaign/data/models/campaign_model.dart';

/// Daftar program untuk halaman Kelola Program admin, bersumber dari server
/// (GET /api/admin/campaigns). Hanya program berstatus active atau closed;
/// pengajuan pending/ditolak ada di AdminVerificationStore.
class AdminProgramStore extends ChangeNotifier {
  AdminProgramStore(this._api);

  final CampaignManageApi _api;

  List<CampaignModel> _items = const [];
  final Map<String, String> _status = {};
  bool _loading = false;
  String? _error;

  List<CampaignModel> get all => List.unmodifiable(_items);
  bool get loading => _loading;
  String? get error => _error;

  CampaignModel? byId(String id) {
    for (final c in _items) {
      if (c.id == id) return c;
    }
    return null;
  }

  bool isClosed(String id) => _status[id] == 'closed';

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final rows = await _api.list('/admin/campaigns');
      final items = <CampaignModel>[];
      _status.clear();
      for (final j in rows) {
        final s = '${j['status']}';
        if (s != 'active' && s != 'closed') continue;
        final m = CampaignModel.fromJson(j);
        items.add(m);
        _status[m.id] = s;
      }
      items.sort((a, b) => (int.tryParse(a.id) ?? 0).compareTo(int.tryParse(b.id) ?? 0));
      _items = items;
    } on ServerException catch (e) {
      _error = e.message;
    }
    _loading = false;
    notifyListeners();
  }

  /// Tambah ([isNew]) atau ubah program. Melempar ServerException bila server menolak.
  /// [cover] = foto baru dari galeri; bila null, gambar dipilih dari [CampaignModel.imageAsset].
  Future<void> save(CampaignModel c, {Uint8List? cover, required bool isNew}) async {
    final end = DateTime(c.deadline.year, c.deadline.month, c.deadline.day, 23, 59, 59);
    final body = <String, dynamic>{
      'title': c.title,
      'category': c.category.key,
      'description': c.description,
      'location': c.location,
      'sub_type': c.subType,
      'target_amount': c.targetAmount,
      'deadline': end.toUtc().toIso8601String(),
      'unit_price': c.unitPrice,
      'unit_label': c.unitLabel,
      'slot_total': c.slotTotal,
    };
    final assetId = await _api.resolveAssetId(c.imageAsset, cover);
    if (assetId != null) body['image_asset_id'] = assetId;

    if (isNew) {
      await _api.create(body);
    } else {
      await _api.update(c.id, body);
    }
    await load();
  }

  Future<void> setClosed(String id, bool closed) async {
    await _api.update(id, {'status': closed ? 'closed' : 'active'});
    await load();
  }

  /// Gagal (ServerException) bila program sudah punya donasi.
  Future<void> remove(String id) async {
    await _api.delete(id);
    await load();
  }
}