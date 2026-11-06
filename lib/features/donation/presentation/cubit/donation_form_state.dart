import 'package:equatable/equatable.dart';
import 'package:sadaqo/features/donation/domain/entities/donation.dart';

abstract class DonationFormState extends Equatable {
  const DonationFormState();

  @override
  List<Object?> get props => [];
}

class DonationFormInitial extends DonationFormState {
  const DonationFormInitial();
}

class DonationFormSubmitting extends DonationFormState {
  const DonationFormSubmitting();
}

class DonationFormSuccess extends DonationFormState {
  const DonationFormSuccess(this.donation);

  final Donation donation;

  @override
  List<Object?> get props => [donation];
}

class DonationFormError extends DonationFormState {
  const DonationFormError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
