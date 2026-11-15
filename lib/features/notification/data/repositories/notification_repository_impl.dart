import 'package:dartz/dartz.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/features/notification/data/datasources/notification_local_datasource.dart';
import 'package:sadaqo/features/notification/domain/entities/app_notification.dart';
import 'package:sadaqo/features/notification/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(this._local);

  final NotificationLocalDataSource _local;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<AppNotification>>> getAll() => _guard(_local.getAll);

  @override
  Future<Either<Failure, Unit>> add({required String title, required String body}) =>
      _guard(() async {
        await _local.add(title, body);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> markAllRead() => _guard(() async {
        await _local.markAllRead();
        return unit;
      });
}