import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/core/usecases/usecase.dart';
import 'package:sadaqo/core/utils/formatter.dart';
import 'package:sadaqo/features/donation/domain/entities/donation.dart';
import 'package:sadaqo/features/donation/domain/repositories/donation_repository.dart';

class CreateDonation implements UseCase<Donation, CreateDonationParams> {
  const CreateDonation(this._repository);

  /// Minimal semua transaksi. Zakat dikecualikan (nominal dari kalkulator).
  static const int minimumAmount = 5000;

  final DonationRepository _repository;

  @override
  Future<Either<Failure, Donation>> call(CreateDonationParams params) {
    if (params.category == ProgramCategory.zakat) {
      if (params.amount <= 0) {
        return Future.value(Left(ValidationFailure('Nominal zakat tidak valid')));
      }
    } else if (params.amount < minimumAmount) {
      return Future.value(
        Left(ValidationFailure('Minimal transaksi ${Formatter.rupiah(minimumAmount)}')),
      );
    }
    return _repository.createDonation(
      campaignId: params.campaignId,
      campaignTitle: params.campaignTitle,
      category: params.category,
      amount: params.amount,
      paymentMethod: params.paymentMethod,
    );
  }
}

class CreateDonationParams extends Equatable {
  const CreateDonationParams({
    required this.campaignId,
    required this.campaignTitle,
    required this.category,
    required this.amount,
    required this.paymentMethod,
  });

  final String campaignId;
  final String campaignTitle;
  final ProgramCategory category;
  final int amount;
  final PaymentMethod paymentMethod;

  @override
  List<Object?> get props =>
      [campaignId, campaignTitle, category, amount, paymentMethod];
}