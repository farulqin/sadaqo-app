import 'package:equatable/equatable.dart';
import 'package:sadaqo/features/donation/domain/entities/donation.dart';

abstract class DonationHistoryState extends Equatable {
  const DonationHistoryState();

  @override
  List<Object?> get props => [];
}

class DonationHistoryInitial extends DonationHistoryState {
  const DonationHistoryInitial();
}

class DonationHistoryLoading extends DonationHistoryState {
  const DonationHistoryLoading();
}

class DonationHistoryLoaded extends DonationHistoryState {
  const DonationHistoryLoaded(this.donations);

  final List<Donation> donations;

  /// Total donasi yang berstatus berhasil.
  int get totalSuccess => donations
      .where((d) => d.status == DonationStatus.success)
      .fold(0, (sum, d) => sum + d.amount);

  @override
  List<Object?> get props => [donations];
}

class DonationHistoryError extends DonationHistoryState {
  const DonationHistoryError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
