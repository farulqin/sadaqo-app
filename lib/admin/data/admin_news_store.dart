import 'package:flutter/foundation.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/features/campaign/data/datasources/campaign_manage_api.dart';
import 'package:sadaqo/features/news/data/models/news_model.dart';

/// Daftar berita untuk halaman Berita admin, bersumber dari server.
class AdminNewsStore extends ChangeNotifier {
  AdminNewsStore(this._api);

  final CampaignManageApi _api;

  List<NewsModel> _items = const [];
  bool _loading = false;
  String? _error;

  List<NewsModel> get all => List.unmodifiable(_items);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final rows = await _api.list('/news');
      _items = rows.map(NewsModel.fromJson).toList();
    } on ServerException catch (e) {
      _error = e.message;
    }
    _loading = false;
    notifyListeners();
  }

  /// Tambah ([isNew]) atau ubah berita. Melempar ServerException bila server menolak.
  Future<void> save(NewsModel n, {Uint8List? cover, required bool isNew}) async {
    final body = <String, dynamic>{
      'title': n.title,
      'summary': n.summary,
      'content': n.content,
      'category': n.category.key,
      'author': n.author,
      'campaign_id': int.tryParse(n.campaignId ?? ''),
    };
    final assetId = await _api.resolveAssetId(n.imageAsset, cover, group: 'news');
    if (assetId != null) body['image_asset_id'] = assetId;

    if (isNew) {
      await _api.createNews(body);
    } else {
      await _api.updateNews(n.id, body);
    }
    await load();
  }

  Future<void> remove(String id) async {
    await _api.deleteNews(id);
    await load();
  }
}