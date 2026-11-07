import 'package:dartz/dartz.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/features/profile/domain/entities/profile_photo.dart';

abstract class ProfileRepository {
  Future<Either<Failure, ProfilePhoto?>> getPhoto();

  /// [photo] null = hapus foto.
  Future<Either<Failure, Unit>> savePhoto(ProfilePhoto? photo);
}