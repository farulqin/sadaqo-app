import 'package:equatable/equatable.dart';
import 'package:sadaqo/core/constants/program_category.dart';

enum PaymentMethod {
  qris('QRIS'),
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
    this.paymentProvider,
    this.donorName = anonymousName,
  });

  /// Nama yang dipakai bila donatur memilih menyembunyikan identitas.
  static const String anonymousName = 'Hamba Allah';

  final String id;
  final String campaignId;
  final String campaignTitle;
  final ProgramCategory category;
  final int amount;
  final PaymentMethod paymentMethod;

  /// Nama e-wallet atau bank (kosong untuk QRIS).
  final String? paymentProvider;
  final DonationStatus status;
  final DateTime createdAt;

  /// Nama yang ditampilkan: nama donatur atau "Hamba Allah".
  final String donorName;

  /// Contoh: "E-Wallet • DANA", "Transfer Bank • BCA", "QRIS".
  String get paymentLabel => paymentProvider == null
      ? paymentMethod.label
      : '${paymentMethod.label} • $paymentProvider';

  @override
  List<Object?> get props => [
        id,
        campaignId,
        campaignTitle,
        category,
        amount,
        paymentMethod,
        paymentProvider,
        status,
        createdAt,
        donorName,
      ];
}