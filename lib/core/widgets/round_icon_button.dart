import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_colors.dart';

/// Tombol ikon bulat putih (kembali, bagikan) di atas gambar header.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: AppColors.forestGreen),
        ),
      ),
    );
  }
}
