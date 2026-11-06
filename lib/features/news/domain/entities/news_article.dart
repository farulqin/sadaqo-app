import 'package:equatable/equatable.dart';
import 'package:sadaqo/core/constants/program_category.dart';

class NewsArticle extends Equatable {
  const NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.category,
    required this.author,
    required this.publishedAt,
    this.campaignId,
    this.imageAsset,
  });

  /// Batas isi berita (kata). Dipakai untuk validasi di sisi aplikasi.
  static const int maxWords = 1000;

  final String id;
  final String title;
  final String summary;
  final String content; // paragraf dipisah baris kosong
  final ProgramCategory category;
  final String author;
  final DateTime publishedAt;

  /// Program terkait: dipakai tombol "Donasi Sekarang" di halaman berita.
  final String? campaignId;
  final String? imageAsset;

  int get wordCount => content.trim().isEmpty
      ? 0
      : content.trim().split(RegExp(r'\s+')).length;

  /// Perkiraan waktu baca (200 kata per menit), minimal 1 menit.
  int get readMinutes {
    final minutes = (wordCount / 200).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        summary,
        content,
        category,
        author,
        publishedAt,
        campaignId,
        imageAsset,
      ];
}
