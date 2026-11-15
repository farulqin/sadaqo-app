import 'package:dio/dio.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/core/network/api_error.dart';
import 'package:sadaqo/features/favorite/data/datasources/favorite_local_datasource.dart';

/// Program favorit dari backend Laravel (tabel favorites).
class FavoriteRemoteDataSourceImpl implements FavoriteLocalDataSource {
  const FavoriteRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  Set<String> _ids(dynamic body) {
    final raw = body is Map ? body['data'] : body;
    if (raw is! List) return <String>{};
    return {for (final id in raw) '$id'};
  }

  @override
  Future<Set<String>> getIds() async {
    try {
      final res = await _dio.get('/favorites');
      return _ids(res.data);
    } on DioException catch (e) {
      throw ServerException(ApiError.message(e));
    }
  }

  @override
  Future<Set<String>> toggle(String campaignId) async {
    try {
      final res = await _dio.post('/favorites/$campaignId');
      return _ids(res.data);
    } on DioException catch (e) {
      throw ServerException(ApiError.message(e));
    }
  }
}