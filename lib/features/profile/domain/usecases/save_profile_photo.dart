import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/core/usecases/usecase.dart';
import 'package:sadaqo/features/profile/domain/entities/profile_photo.dart';
import 'package:sadaqo/features/profile/domain/repositories/profile_repository.dart';

class SaveProfilePhoto implements UseCase<Unit, SavePhotoParams> {
  const SaveProfilePhoto(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SavePhotoParams params) {
    return _repository.savePhoto(params.photo);
  }
}

class SavePhotoParams extends Equatable {
  const SavePhotoParams(this.photo);

  /// null = hapus foto.
  final ProfilePhoto? photo;

  @override
  List<Object?> get props => [photo];
}