import 'package:dartz/dartz.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/core/usecases/usecase.dart';
import 'package:sadaqo/features/profile/domain/entities/profile_photo.dart';
import 'package:sadaqo/features/profile/domain/repositories/profile_repository.dart';

class GetProfilePhoto implements UseCase<ProfilePhoto?, NoParams> {
  const GetProfilePhoto(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, ProfilePhoto?>> call(NoParams params) {
    return _repository.getPhoto();
  }
}