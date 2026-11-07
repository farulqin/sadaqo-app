import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/features/donation/data/models/donation_model.dart';
import 'package:sadaqo/features/donation/domain/entities/donation.dart';

abstract class DonationRemoteDataSource {
  Future<List<DonationModel>> getHistory();

  Future<DonationModel> createDonation({
    required String campaignId,
    required String campaignTitle,
    required ProgramCategory category,
    required int amount,
    required PaymentMethod paymentMethod,
    String? paymentProvider,
    required String donorName,
  });
}