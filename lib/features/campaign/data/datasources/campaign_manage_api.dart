import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/core/network/api_error.dart';

/// Panggilan API untuk mengelola program (pengelola dan admin).
/// Semua kegagalan dilempar sebagai ServerException dengan pesan dari server.
class CampaignManageApi {
  const CampaignManageApi(this._dio);

  final Dio _dio;

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