import 'package:equatable/equatable.dart';
import 'package:sadaqo/core/constants/program_category.dart';

class Campaign extends Equatable {
  const Campaign({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.targetAmount,
    required this.collectedAmount,
    required this.deadline,
    required this.location,
    this.imageAsset,
  });

  final String id;
  final String title;
  final String description;
  final ProgramCategory category;
  final int targetAmount;
  final int collectedAmount;
  final DateTime deadline;
  final String location;
  final String? imageAsset;

  /// 0.0 - 1.0
  double get progress {
    if (targetAmount <= 0) return 0;
    return (collectedAmount / targetAmount).clamp(0.0, 1.0);
  }

  int get progressPercent => (progress * 100).round();

  int get daysLeft {
    final days = deadline.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        targetAmount,
        collectedAmount,
        deadline,
        location,
        imageAsset,
      ];
}
