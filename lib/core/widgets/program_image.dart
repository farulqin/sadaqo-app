import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/core/network/api_config.dart';
import 'package:sadaqo/core/widgets/category_icon.dart';

/// Gambar program. Sumber bisa berupa:
/// - aset bawaan aplikasi ("assets/images/...")
/// - URL penuh ("http://.../storage/uploads/...")
/// - path unggahan dari server ("uploads/program/xxx.png")
/// Jika kosong atau gagal dimuat, ditampilkan gradient + icon kategori.
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
        child: _image(),
      ),
    );
  }

  Widget _image() {
    final src = imageAsset?.replaceAll(r'\/', '/');
    if (src == null || src.isEmpty) return _placeholder();

    if (src.startsWith('http://') || src.startsWith('https://')) {
      return _network(ApiConfig.resolveMediaUrl(src));
    }
    if (src.startsWith('uploads/') || src.startsWith('/storage/')) {
      return _network(_storageUrl(src));
    }
    return Image.asset(
      src,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  Widget _network(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _placeholder(),
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  /// Contoh: `uploads/program/x.png` menjadi `http://HOST_SERVER/storage/uploads/program/x.png`.
  String _storageUrl(String path) {
    final base = Uri.parse(ApiConfig.baseUrl);
    final origin = '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}';
    final clean = path.startsWith('/') ? path : '/storage/$path';
    return '$origin$clean';
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
        child: CategoryIcon(category, size: size, color: Colors.white70),
      ),
    );
  }
}