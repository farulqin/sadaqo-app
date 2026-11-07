import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/features/donation/domain/entities/donation.dart';

class DonationModel extends Donation {
  const DonationModel({
    required super.id,
    required super.campaignId,
    required super.campaignTitle,
    required super.category,
    required super.amount,
    required super.paymentMethod,
    required super.status,
    required super.createdAt,
    super.paymentProvider,
    super.donorName = Donation.anonymousName,
  });

  factory DonationModel.fromJson(Map<String, dynamic> json) {
    return DonationModel(
      id: json['id'].toString(),
      campaignId: json['campaign_id'].toString(),
      campaignTitle: json['campaign_title'] as String,
      category: ProgramCategory.fromKey(json['category'] as String),
      amount: (json['amount'] as num).toInt(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (m) => m.name == json['payment_method'],
        orElse: () => PaymentMethod.qris,
      ),
      paymentProvider: json['payment_provider'] as String?,
      status: DonationStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => DonationStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      donorName: (json['donor_name'] as String?) ?? Donation.anonymousName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'campaign_id': campaignId,
        'campaign_title': campaignTitle,
        'category': category.key,
        'amount': amount,
        'payment_method': paymentMethod.name,
        'payment_provider': paymentProvider,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
        'donor_name': donorName,
      };
}