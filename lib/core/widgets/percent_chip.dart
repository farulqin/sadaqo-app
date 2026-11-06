import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_colors.dart';

/// Label kecil "75% Terkumpul".
class PercentChip extends StatelessWidget {
  const PercentChip({super.key, required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.limeGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$percent% Terkumpul',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.forestGreen,
        ),
      ),
    );
  }
}
