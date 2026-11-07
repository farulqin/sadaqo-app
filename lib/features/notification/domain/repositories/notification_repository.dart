import 'package:dartz/dartz.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/features/notification/domain/entities/app_notification.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<AppNotification>>> getAll();

  Future<Either<Failure, Unit>> add({required String title, required String body});

  Future<Either<Failure, Unit>> markAllRead();
}