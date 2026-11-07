import 'package:dartz/dartz.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/core/usecases/usecase.dart';
import 'package:sadaqo/features/auth/domain/entities/app_user.dart';
import 'package:sadaqo/features/auth/domain/repositories/auth_repository.dart';

/// Masuk dengan akun Google atau Apple. Parameter: nama penyedia.
class LoginWithProvider implements UseCase<AppUser, String> {
  const LoginWithProvider(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, AppUser>> call(String provider) {
    return _repository.loginWithProvider(provider);
  }
}