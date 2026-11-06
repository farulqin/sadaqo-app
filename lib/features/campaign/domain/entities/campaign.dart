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
    this.subType,
    this.unitPrice,
    this.unitLabel,
    this.slotTotal,
    this.slotFilled,
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

  /// Jenis di dalam kategori, contoh: Masjid/Mushola, Banjir, Panti Jompo, Kolektif.
  final String? subType;

  /// Harga tetap per unit (qurban per orang/kolektif). Kosong = nominal bebas.
  final int? unitPrice;
  final String? unitLabel; // 'ekor' / 'slot'

  /// Kuota slot (qurban kolektif). Kosong = tanpa batas slot.
  final int? slotTotal;
  final int? slotFilled;

  bool get isZakat => category == ProgramCategory.zakat;
  bool get isFixedPrice => unitPrice != null;
  bool get isSlotBased => slotTotal != null;

  int get slotsLeft {
    if (!isSlotBased) return 0;
    final left = slotTotal! - (slotFilled ?? 0);
    return left < 0 ? 0 : left;
  }

  bool get isFull => isSlotBased && slotsLeft <= 0;

  /// Batas jumlah unit sekali pesan.
  int get maxUnits => isSlotBased ? slotsLeft : 10;

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
        subType,
        unitPrice,
        unitLabel,
        slotTotal,
        slotFilled,
      ];
}