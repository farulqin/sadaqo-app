import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/core/usecases/usecase.dart';
import 'package:sadaqo/features/notification/domain/entities/app_notification.dart';
import 'package:sadaqo/features/notification/domain/repositories/notification_repository.dart';

class GetNotifications implements UseCase<List<AppNotification>, NoParams> {
  const GetNotifications(this._repository);

  final NotificationRepository _repository;

  @override
  Future<Either<Failure, List<AppNotification>>> call(NoParams params) =>
      _repository.getAll();
}

class AddNotification implements UseCase<Unit, AddNotificationParams> {
  const AddNotification(this._repository);

  final NotificationRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(AddNotificationParams params) =>
      _repository.add(title: params.title, body: params.body);
}

class AddNotificationParams extends Equatable {
  const AddNotificationParams({required this.title, required this.body});

  final String title;
  final String body;

  @override
  List<Object?> get props => [title, body];
}

class MarkAllNotificationsRead implements UseCase<Unit, NoParams> {
  const MarkAllNotificationsRead(this._repository);

  final NotificationRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repository.markAllRead();
}