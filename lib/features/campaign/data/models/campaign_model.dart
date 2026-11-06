import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/features/campaign/domain/entities/campaign.dart';

class CampaignModel extends Campaign {
  const CampaignModel({
    required super.id,
    required super.title,
    required super.description,
    required super.category,
    required super.targetAmount,
    required super.collectedAmount,
    required super.deadline,
    required super.location,
    super.imageAsset,
  });

  /// Nama key JSON mengikuti rencana respons API Laravel.
  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    return CampaignModel(
      id: json['id'].toString(),
      title: json['title'] as String,
      description: json['description'] as String,
      category: ProgramCategory.fromKey(json['category'] as String),
      targetAmount: (json['target_amount'] as num).toInt(),
      collectedAmount: (json['collected_amount'] as num).toInt(),
      deadline: DateTime.parse(json['deadline'] as String),
      location: json['location'] as String,
      imageAsset: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.key,
        'target_amount': targetAmount,
        'collected_amount': collectedAmount,
        'deadline': deadline.toIso8601String(),
        'location': location,
        'image': imageAsset,
      };
}
