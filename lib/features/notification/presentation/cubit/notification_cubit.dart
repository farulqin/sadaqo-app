import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/usecases/usecase.dart';
import 'package:sadaqo/features/notification/domain/entities/app_notification.dart';
import 'package:sadaqo/features/notification/domain/usecases/notification_usecases.dart';

class NotificationState extends Equatable {
  const NotificationState({this.items = const <AppNotification>[]});

  final List<AppNotification> items;

  int get unread => items.where((n) => !n.isRead).length;

  @override
  List<Object?> get props => [items];
}

class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit({
    required GetNotifications getNotifications,
    required AddNotification addNotification,
    required MarkAllNotificationsRead markAllRead,
    bool Function()? isEnabled,
  })  : _get = getNotifications,
        _add = addNotification,
        _markAll = markAllRead,
        _isEnabled = isEnabled ?? (() => true),
        super(const NotificationState());

  final GetNotifications _get;
  final AddNotification _add;
  final MarkAllNotificationsRead _markAll;

  /// Dibaca dari Pengaturan: jika dimatikan, notifikasi baru tidak dicatat.
  final bool Function() _isEnabled;

  Future<void> load() async {
    final result = await _get(const NoParams());
    result.fold((_) {}, (items) => emit(NotificationState(items: items)));
  }

  /// Ucapan sambutan setelah masuk atau daftar.
  Future<void> addWelcome() => add(
        title: 'Ahlan wa sahlan di SADAQO',
        body: 'Bismillah, mari tebar benih kebaikan hari ini.',
      );

  Future<void> add({
    required String title,
    required String body,
    bool important = false,
  }) async {
    // Pemberitahuan penting (mis. pelanggaran) tetap dicatat walau notifikasi dimatikan.
    if (!important && !_isEnabled()) return;
    final result = await _add(AddNotificationParams(title: title, body: body));
    if (result.isRight()) await load();
  }

  Future<void> markAllRead() async {
    final result = await _markAll(const NoParams());
    if (result.isRight()) await load();
  }
}