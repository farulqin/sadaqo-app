import 'package:dio/dio.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/core/network/api_error.dart';
import 'package:sadaqo/features/campaign/data/datasources/campaign_remote_datasource.dart';
import 'package:sadaqo/features/campaign/data/models/campaign_model.dart';

/// Daftar program dari backend Laravel (GET /api/campaigns, hanya yang aktif).
class CampaignRemoteDataSourceImpl implements CampaignRemoteDataSource {
  const CampaignRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<CampaignModel>> getCampaigns() async {
    try {
      final res = await _dio.get('/campaigns');
      return ApiError.list(res.data).map(CampaignModel.fromJson).toList();
    } on DioException catch (e) {
      throw ServerException(ApiError.message(e));
    }
  }
}