import 'package:equatable/equatable.dart';
import 'package:sadaqo/core/constants/program_category.dart';

enum PaymentMethod {
  ewallet('E-Wallet'),
  transfer('Transfer Bank');

  const PaymentMethod(this.label);
  final String label;
}

enum DonationStatus {
  success('Berhasil'),
  pending('Menunggu');

  const DonationStatus(this.label);
  final String label;
}

class Donation extends Equatable {
  const Donation({
    required this.id,
    required this.campaignId,
    required this.campaignTitle,
    required this.category,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String campaignId;
  final String campaignTitle;
  final ProgramCategory category;
  final int amount;
  final PaymentMethod paymentMethod;
  final DonationStatus status;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        campaignId,
        campaignTitle,
        category,
        amount,
        paymentMethod,
        status,
        createdAt,
      ];
}
