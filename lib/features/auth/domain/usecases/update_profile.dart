import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/core/usecases/usecase.dart';
import 'package:sadaqo/features/auth/domain/entities/app_user.dart';
import 'package:sadaqo/features/auth/domain/repositories/auth_repository.dart';

class UpdateProfile implements UseCase<AppUser, UpdateProfileParams> {
  const UpdateProfile(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, AppUser>> call(UpdateProfileParams params) {
    final name = params.name.trim();
    final phone = params.phone?.trim();

    if (name.length < 3) {
      return Future.value(Left(ValidationFailure('Nama minimal 3 karakter')));
    }
    if (phone != null &&
        phone.isNotEmpty &&
        !RegExp(r'^[0-9+\-\s]{9,16}$').hasMatch(phone)) {
      return Future.value(Left(ValidationFailure('Nomor HP tidak valid')));
    }
    return _repository.updateProfile(
      email: params.email,
      name: name,
      phone: (phone == null || phone.isEmpty) ? null : phone,
    );
  }
}

class UpdateProfileParams extends Equatable {
  const UpdateProfileParams({required this.email, required this.name, this.phone});

  final String email;
  final String name;
  final String? phone;

  @override
  List<Object?> get props => [email, name, phone];
}