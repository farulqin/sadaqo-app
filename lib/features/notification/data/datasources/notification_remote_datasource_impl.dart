import 'package:dio/dio.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/core/network/api_error.dart';
import 'package:sadaqo/features/notification/data/datasources/notification_local_datasource.dart';
import 'package:sadaqo/features/notification/domain/entities/app_notification.dart';

/// Notifikasi dari backend Laravel. Server juga membuat notifikasi otomatis
/// (donasi berhasil, program disetujui/ditolak, laporan terbit).
class NotificationRemoteDataSourceImpl implements NotificationLocalDataSource {
  const NotificationRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<AppNotification>> getAll() async {
    try {
      final res = await _dio.get('/notifications');
      return ApiError.list(res.data)
          .map(
            (j) => AppNotification(
              id: '${j['id']}',
              title: (j['title'] ?? '') as String,
              body: (j['body'] ?? '') as String,
              createdAt:
                  DateTime.tryParse('${j['created_at']}')?.toLocal() ?? DateTime.now(),
              isRead: j['is_read'] == true,
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw ServerException(ApiError.message(e));
    }
  }

  @override
  Future<void> add(String title, String body) async {
    try {
      await _dio.post('/notifications', data: {'title': title, 'body': body});
    } on DioException catch (e) {
      throw ServerException(ApiError.message(e));
    }
  }

  @override
  Future<void> markAllRead() async {
    try {
      await _dio.post('/notifications/read-all');
    } on DioException catch (e) {
      throw ServerException(ApiError.message(e));
    }
  }
}