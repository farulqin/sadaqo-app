import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/program_category.dart';

/// Gambar program. Jika [imageAsset] kosong atau file tidak ditemukan,
/// ditampilkan gradient + icon sesuai kategori (tidak akan error).
class ProgramImage extends StatelessWidget {
  const ProgramImage({
    super.key,
    required this.category,
    this.imageAsset,
    this.height,
    this.width,
    this.borderRadius = BorderRadius.zero,
  });

  final ProgramCategory category;
  final String? imageAsset;
  final double? height;
  final double? width;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        width: width,
        child: imageAsset == null
            ? _placeholder()
            : Image.asset(
                imageAsset!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _placeholder(),
              ),
      ),
    );
  }

  Widget _placeholder() {
    final size = ((height ?? width ?? 80) * 0.42).clamp(20.0, 72.0);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [category.colorStart, category.colorEnd],
        ),
      ),
      child: Center(
        child: Icon(category.icon, size: size, color: Colors.white70),
      ),
    );
  }
}
