import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/core/network/api_error.dart';
import 'package:sadaqo/core/constants/program_category.dart';

/// Panggilan API untuk mengelola program (pengelola dan admin).
/// Semua kegagalan dilempar sebagai ServerException dengan pesan dari server.
class CampaignManageApi {
      CampaignManageApi(this._dio);

  final Dio _dio;
  Map<String, int>? _assetIds;
  Future<List<Map<String, dynamic>>> list(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.get(path, queryParameters: query);
      return ApiError.list(res.data);
    } on DioException catch (e) {
      throw ServerException(ApiError.message(e));
    }
  }

  /// Peta path aset -> id (registri tabel assets), untuk memasang gambar bawaan ke program.
  Future<Map<String, int>> assetIdsByPath() async {
    final rows = await list('/assets');
    return {
      for (final r in rows)
        if (r['path'] is String && r['id'] is num)
          r['path'] as String: (r['id'] as num).toInt(),
    };
  }

    /// Id aset untuk dipasang ke program/berita/kategori: mengunggah [cover] bila ada,
  /// atau mencari id gambar bawaan dari [ref] (path aset). null = tidak berubah.
  Future<int?> resolveAssetId(
    String? ref,
    Uint8List? cover, {
    String group = 'program',
  }) async {
    if (cover != null) return uploadImage(cover, group: group);
    if (ref == null || ref.isEmpty || ref.startsWith('http')) return null;
    final ids = _assetIds ??= await assetIdsByPath();
    final id = ids[ref];
    if (id == null) {
      throw const ServerException(
        'Gambar ini belum terdaftar di server. Pilih gambar lain atau unggah foto baru.',
      );
    }
    return id;
  }

  // ---------- Berita ----------
  Future<Map<String, dynamic>> createNews(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post('/news', data: body);
      return ApiError.object(res.data);
    } on DioException catch (e) {
      throw ServerException(ApiError.message(e));
    }
  }

  Future<Map<String, dynamic>> updateNews(String id, Map<String, dynamic> body) async {
    try {
      final res = await _dio.put('/news/$id', data: body);
      return ApiError.object(res.data);
    } on DioException catch (e) {
      throw ServerException(ApiError.message(e));
    }
  }

  Future<void> deleteNews(String id) async {
    try {
      await _dio.delete('/news/$id');
    } on DioException catch (e) {
      throw ServerException(ApiError.message(e));
    }
  }

  // ---------- Kategori ----------
  Future<List<Map<String, dynamic>>> categories() => list('/categories');

  /// Menyimpan nama, nama singkat, dan ikon kategori ([key] = ProgramCategory.key).
  Future<void> saveCategory(
    String key, {
    required String label,
    required String shortLabel,
    String? iconPath,
  }) async {
    final rows = await categories();
    final row = rows.firstWhere(
      (r) => r['key'] == key,
      orElse: () => const <String, dynamic>{},
    );
    final id = row['id'];
    if (id is! num) {
      throw const ServerException('Kategori tidak ditemukan di server.');
    }
    final body = <String, dynamic>{'label': label, 'short_label': shortLabel};
    final iconId = await resolveAssetId(iconPath, null);
    if (iconId != null) body['icon_asset_id'] = iconId;
    try {
      await _dio.put('/categories/${id.toInt()}', data: body);
    } on DioException catch (e) {
      throw ServerException(ApiError.message(e));
    }
  }

  /// Mengisi CategoryOverrides dari server, supaya nama dan ikon kategori
  /// mengikuti pengaturan admin.
  Future<void> applyCategoryOverrides() async {
    for (final r in await categories()) {
      final key = r['key'];
      if (key is! String) continue;
      final label = r['label'];
      final short = r['short_label'];
      final icon = r['icon'];
      if (label is String) CategoryOverrides.labels[key] = label;
      if (short is String) CategoryOverrides.shortLabels[key] = short;
      if (icon is String && icon.startsWith('assets/')) {
        CategoryOverrides.iconAssets[key] = icon;
      }
    }
  }

  /// Mengunggah gambar ke registri aset, mengembalikan id aset.
  Future<int> uploadImage(
    Uint8List bytes, {
    String group = 'program',
    String filename = 'foto.jpg',
  }) async {
    try {
      final form = FormData.fromMap({
        'group': group,
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final res = await _dio.post('/assets', data: form);
      return (ApiError.object(res.data)['id'] as num).toInt();
    } on DioException catch (e) {
      throw ServerException(ApiError.message(e));
    }
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post('/campaigns', data: body);
      return ApiError.object(res.data);
    } on DioException catch (e) {
      throw ServerException(ApiError.message(e));
    }
  }

  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> body) async {
    try {
      final res = await _dio.put('/campaigns/$id', data: body);
      return ApiError.object(res.data);
    } on DioException catch (e) {
      throw ServerException(ApiError.message(e));
    }
  }

  Future<void> review(String id, {required bool approve, String? note}) async {
    try {
      await _dio.patch(
        '/campaigns/$id/review',
        data: {
          'decision': approve ? 'approve' : 'reject',
          'note': ?note,
        },
      );
    } on DioException catch (e) {
      throw ServerException(ApiError.message(e));
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/campaigns/$id');
    } on DioException catch (e) {
      throw ServerException(ApiError.message(e));
    }
  }
}