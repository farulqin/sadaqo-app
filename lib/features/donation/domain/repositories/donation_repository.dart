import 'package:dartz/dartz.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/features/donation/domain/entities/donation.dart';

abstract class DonationRepository {
  Future<Either<Failure, List<Donation>>> getHistory();

  Future<Either<Failure, Donation>> createDonation({
    required String campaignId,
    required String campaignTitle,
    required ProgramCategory category,
    required int amount,
    required PaymentMethod paymentMethod,
  });
}
