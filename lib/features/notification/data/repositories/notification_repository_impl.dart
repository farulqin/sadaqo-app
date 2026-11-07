import 'package:dartz/dartz.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/features/notification/data/datasources/notification_local_datasource.dart';
import 'package:sadaqo/features/notification/domain/entities/app_notification.dart';
import 'package:sadaqo/features/notification/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(this._local);

  final NotificationLocalDataSource _local;

  @override
  Future<Either<Failure, List<AppNotification>>> getAll() async {
    try {
      return Right(await _local.getAll());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> add({required String title, required String body}) async {
    try {
      await _local.add(title, body);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> markAllRead() async {
    try {
      await _local.markAllRead();
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}