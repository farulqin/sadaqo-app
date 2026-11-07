import 'package:dartz/dartz.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:sadaqo/features/auth/domain/entities/app_user.dart';
import 'package:sadaqo/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Future<Either<Failure, AppUser>> login({
    required String email,
    required String password,
  }) async {
    try {
      return Right(await _remote.login(email, password));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, AppUser>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      return Right(await _remote.register(name, email, password));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, AppUser>> loginWithProvider(String provider) async {
    try {
      return Right(await _remote.loginWithProvider(provider));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await _remote.logout();
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}