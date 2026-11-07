import 'package:sadaqo/features/notification/domain/entities/app_notification.dart';

abstract class NotificationLocalDataSource {
  Future<List<AppNotification>> getAll();
  Future<void> add(String title, String body);
  Future<void> markAllRead();
}

/// Penyimpanan di memori selama backend belum siap (hilang saat aplikasi ditutup).
class NotificationMemoryDataSource implements NotificationLocalDataSource {
  List<AppNotification> _items = [];

  @override
  Future<List<AppNotification>> getAll() async => List.unmodifiable(_items);

  @override
  Future<void> add(String title, String body) async {
    final item = AppNotification(
      id: 'n${_items.length + 1}',
      title: title,
      body: body,
      createdAt: DateTime.now(),
    );
    _items = [item, ..._items]; // terbaru di atas
  }

  @override
  Future<void> markAllRead() async {
    _items = [for (final n in _items) n.copyWith(isRead: true)];
  }
}