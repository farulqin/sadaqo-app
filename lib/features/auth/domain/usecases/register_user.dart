import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/core/usecases/usecase.dart';
import 'package:sadaqo/features/auth/domain/entities/app_user.dart';
import 'package:sadaqo/features/auth/domain/repositories/auth_repository.dart';

class RegisterUser implements UseCase<AppUser, RegisterParams> {
  const RegisterUser(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, AppUser>> call(RegisterParams params) async {
    // Aturan bisnis ada di sini, bukan di UI.
    final name = params.name.trim();
    final email = params.email.trim();
    if (name.length < 3) {
      return Left(ValidationFailure('Nama minimal 3 karakter'));
    }
    if (!email.contains('@') || !email.contains('.')) {
      return Left(ValidationFailure('Format email tidak valid'));
    }
    if (params.password.length < 6) {
      return Left(ValidationFailure('Password minimal 6 karakter'));
    }
    if (params.password != params.confirmPassword) {
      return Left(ValidationFailure('Konfirmasi password tidak sama'));
    }
    return _repository.register(name: name, email: email, password: params.password);
  }
}

class RegisterParams extends Equatable {
  const RegisterParams({
    required this.name,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });

  final String name;
  final String email;
  final String password;
  final String confirmPassword;

  @override
  List<Object?> get props => [name, email, password, confirmPassword];
}