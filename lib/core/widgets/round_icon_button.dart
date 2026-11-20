// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/widgets/pressable_scale.dart';

/// Tombol ikon bulat putih (kembali, bagikan) di atas gambar header.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.88,
      child: Material(
        color: AppColors.surface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: AppColors.brandInk),
          ),
        ),
      ),
    );
  }
}