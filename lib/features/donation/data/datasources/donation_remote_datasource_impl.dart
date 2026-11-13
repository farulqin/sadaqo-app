import 'package:dio/dio.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/core/network/api_error.dart';
import 'package:sadaqo/features/donation/data/datasources/donation_remote_datasource.dart';
import 'package:sadaqo/features/donation/data/models/donation_model.dart';
import 'package:sadaqo/features/donation/domain/entities/donation.dart';

/// Donasi lewat backend Laravel. Pembayaran masih simulasi (status langsung success).
class DonationRemoteDataSourceImpl implements DonationRemoteDataSource {
  const DonationRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<DonationModel>> getHistory() async {
    try {
      final res = await _dio.get('/donations');
      return ApiError.list(res.data).map(DonationModel.fromJson).toList();
    } on DioException catch (e) {
      throw ServerException(ApiError.message(e));
    }
  }

  @override
  Future<DonationModel> createDonation({
    required String campaignId,
    required String campaignTitle,
    required ProgramCategory category,
    required int amount,
    required PaymentMethod paymentMethod,
    String? paymentProvider,
    required String donorName,
  }) async {
    try {
      final res = await _dio.post(
        '/donations',
        data: {
          'campaign_id': int.tryParse(campaignId) ?? campaignId,
          'amount': amount,
          'payment_method': paymentMethod.name,
          'payment_provider': ?paymentProvider,
          'donor_name': donorName,
        },
      );
      return DonationModel.fromJson(ApiError.object(res.data));
    } on DioException catch (e) {
      throw ServerException(ApiError.message(e));
    }
  }
}