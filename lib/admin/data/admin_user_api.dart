import 'package:dio/dio.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/core/network/api_error.dart';

/// Panggilan API kelola pengguna (khusus admin). Semua kegagalan dilempar
/// sebagai ServerException dengan pesan dari server.
class AdminUserApi {
  const AdminUserApi(this._dio);

  final Dio _dio;

  Future<T> _run<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ServerException(ApiError.message(e));
    }
  }

  Future<List<Map<String, dynamic>>> list() =>
      _run(() async => ApiError.list((await _dio.get('/admin/users')).data));

  Future<void> create(Map<String, dynamic> body) =>
      _run(() => _dio.post('/admin/users', data: body));

  Future<void> update(String id, Map<String, dynamic> body) =>
      _run(() => _dio.put('/admin/users/$id', data: body));

  Future<void> delete(String id) => _run(() => _dio.delete('/admin/users/$id'));

  Future<void> warn(String id, String note) =>
      _run(() => _dio.post('/admin/users/$id/warn', data: {'note': note}));

  Future<void> ban(String id, {int? days, String? reason}) => _run(
        () => _dio.post(
          '/admin/users/$id/ban',
          data: {
            'days': days,
            if (reason != null && reason.isNotEmpty) 'reason': reason,
          },
        ),
      );

  Future<void> lift(String id) => _run(() => _dio.post('/admin/users/$id/lift'));
}