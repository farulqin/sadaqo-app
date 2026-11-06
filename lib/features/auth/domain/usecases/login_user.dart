import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/core/usecases/usecase.dart';
import 'package:sadaqo/features/auth/domain/entities/app_user.dart';
import 'package:sadaqo/features/auth/domain/repositories/auth_repository.dart';

class LoginUser implements UseCase<AppUser, LoginParams> {
  const LoginUser(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, AppUser>> call(LoginParams params) async {
    // Aturan bisnis ada di sini, bukan di UI.
    final email = params.email.trim();
    if (!email.contains('@')) {
      return Left(ValidationFailure('Format email tidak valid'));
    }
    if (params.password.length < 6) {
      return Left(ValidationFailure('Password minimal 6 karakter'));
    }
    return _repository.login(email: email, password: params.password);
  }
}

class LoginParams extends Equatable {
  const LoginParams({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}
