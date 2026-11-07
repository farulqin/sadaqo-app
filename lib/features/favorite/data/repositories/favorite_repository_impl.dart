import 'package:dartz/dartz.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/features/favorite/data/datasources/favorite_local_datasource.dart';
import 'package:sadaqo/features/favorite/domain/repositories/favorite_repository.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  const FavoriteRepositoryImpl(this._local);

  final FavoriteLocalDataSource _local;

  @override
  Future<Either<Failure, Set<String>>> getIds() async {
    try {
      return Right(await _local.getIds());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Set<String>>> toggle(String campaignId) async {
    try {
      return Right(await _local.toggle(campaignId));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}