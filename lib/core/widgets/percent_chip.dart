// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/widgets/count_up_text.dart';

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
      child: CountUpText(
        value: percent,
        duration: const Duration(milliseconds: 800),
        format: (v) => '${v.round()}% Terkumpul',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.onLime,
        ),
      ),
    );
  }
}