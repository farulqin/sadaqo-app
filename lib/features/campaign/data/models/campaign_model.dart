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
    super.subType,
    super.unitPrice,
    super.unitLabel,
    super.slotTotal,
    super.slotFilled,
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
      subType: json['sub_type'] as String?,
      unitPrice: (json['unit_price'] as num?)?.toInt(),
      unitLabel: json['unit_label'] as String?,
      slotTotal: (json['slot_total'] as num?)?.toInt(),
      slotFilled: (json['slot_filled'] as num?)?.toInt(),
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
        'sub_type': subType,
        'unit_price': unitPrice,
        'unit_label': unitLabel,
        'slot_total': slotTotal,
        'slot_filled': slotFilled,
      };

  CampaignModel copyWith({int? collectedAmount, int? slotFilled}) {
    return CampaignModel(
      id: id,
      title: title,
      description: description,
      category: category,
      targetAmount: targetAmount,
      collectedAmount: collectedAmount ?? this.collectedAmount,
      deadline: deadline,
      location: location,
      imageAsset: imageAsset,
      subType: subType,
      unitPrice: unitPrice,
      unitLabel: unitLabel,
      slotTotal: slotTotal,
      slotFilled: slotFilled ?? this.slotFilled,
    );
  }
}