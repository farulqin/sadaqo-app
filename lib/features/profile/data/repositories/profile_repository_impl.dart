import 'package:dartz/dartz.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:sadaqo/features/profile/domain/entities/profile_photo.dart';
import 'package:sadaqo/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._local);

  final ProfileLocalDataSource _local;

  @override
  Future<Either<Failure, ProfilePhoto?>> getPhoto() async {
    try {
      return Right(await _local.getPhoto());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> savePhoto(ProfilePhoto? photo) async {
    try {
      await _local.savePhoto(photo);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}