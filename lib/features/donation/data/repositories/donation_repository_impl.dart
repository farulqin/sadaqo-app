import 'package:dartz/dartz.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/features/donation/data/datasources/donation_remote_datasource.dart';
import 'package:sadaqo/features/donation/domain/entities/donation.dart';
import 'package:sadaqo/features/donation/domain/repositories/donation_repository.dart';

class DonationRepositoryImpl implements DonationRepository {
  const DonationRepositoryImpl(this._remote);

  final DonationRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Donation>>> getHistory() async {
    try {
      final items = await _remote.getHistory();
      return Right(items);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Donation>> createDonation({
    required String campaignId,
    required String campaignTitle,
    required ProgramCategory category,
    required int amount,
    required PaymentMethod paymentMethod,
  }) async {
    try {
      final donation = await _remote.createDonation(
        campaignId: campaignId,
        campaignTitle: campaignTitle,
        category: category,
        amount: amount,
        paymentMethod: paymentMethod,
      );
      return Right(donation);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
