import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/program_category.dart';

/// Ikon kategori. Memakai gambar ikon (mis. kepala sapi untuk Qurban)
/// jika ada, selain itu memakai ikon bawaan Flutter. Warna mengikuti [color].
class CategoryIcon extends StatelessWidget {
  const CategoryIcon(this.category, {super.key, this.size = 24, this.color});

  final ProgramCategory category;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final asset = category.iconAsset;
    if (asset != null) {
      return ImageIcon(AssetImage(asset), size: size, color: color);
    }
    return Icon(category.icon, size: size, color: color);
  }
}