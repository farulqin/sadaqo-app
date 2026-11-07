import 'package:dartz/dartz.dart';
import 'package:sadaqo/core/error/failures.dart';

abstract class FavoriteRepository {
  Future<Either<Failure, Set<String>>> getIds();

  /// Tambah jika belum favorit, hapus jika sudah. Mengembalikan daftar terbaru.
  Future<Either<Failure, Set<String>>> toggle(String campaignId);
}