import 'package:dio/dio.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/core/network/api_error.dart';
import 'package:sadaqo/features/news/data/datasources/news_remote_datasource.dart';
import 'package:sadaqo/features/news/data/models/news_model.dart';

/// Berita dari backend Laravel (GET /api/news, publik).
class NewsRemoteDataSourceImpl implements NewsRemoteDataSource {
  const NewsRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<NewsModel>> getNews() async {
    try {
      final res = await _dio.get('/news');
      return ApiError.list(res.data).map(NewsModel.fromJson).toList();
    } on DioException catch (e) {
      throw ServerException(ApiError.message(e));
    }
  }
}