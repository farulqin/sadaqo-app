import 'package:dartz/dartz.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/features/auth/domain/entities/app_user.dart';

/// Kontrak: domain hanya tahu "apa" yang dibutuhkan, bukan "bagaimana".
abstract class AuthRepository {
  Future<Either<Failure, AppUser>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, AppUser>> register({
    required String name,
    required String email,
    required String password,
  });

  /// [provider]: 'Google' atau 'Apple'.
  Future<Either<Failure, AppUser>> loginWithProvider(String provider);

  Future<Either<Failure, Unit>> logout();
}