import 'package:dartz/dartz.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/core/usecases/usecase.dart';
import 'package:sadaqo/features/auth/domain/entities/app_user.dart';
import 'package:sadaqo/features/auth/domain/repositories/auth_repository.dart';

/// Memulihkan sesi dari token yang tersimpan. Right(null) = tidak ada sesi.
class RestoreSession implements UseCase<AppUser?, NoParams> {
  const RestoreSession(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, AppUser?>> call(NoParams params) =>
      _repository.restoreSession();
}