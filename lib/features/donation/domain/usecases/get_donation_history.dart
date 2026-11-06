import 'package:dartz/dartz.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/core/usecases/usecase.dart';
import 'package:sadaqo/features/donation/domain/entities/donation.dart';
import 'package:sadaqo/features/donation/domain/repositories/donation_repository.dart';

class GetDonationHistory implements UseCase<List<Donation>, NoParams> {
  const GetDonationHistory(this._repository);

  final DonationRepository _repository;

  @override
  Future<Either<Failure, List<Donation>>> call(NoParams params) {
    return _repository.getHistory();
  }
}
