import 'package:dio/dio.dart';
import 'package:sadaqo/core/network/api_client.dart';

class ApiError {
  ApiError._();

  /// Pakai galat validasi pertama (422) bila ada, lalu "message" dari server.
  static String message(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['errors'] is Map) {
      for (final v in (data['errors'] as Map).values) {
        if (v is List && v.isNotEmpty) return '${v.first}';
      }
    }
    return ApiClient.messageFrom(e);
  }

  /// Isi daftar bisa langsung berupa list, atau dibungkus {"data": [...]}.
  static List<Map<String, dynamic>> list(dynamic body) {
    final raw = body is Map ? body['data'] : body;
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  /// Satu objek langsung, atau dibungkus {"data": {...}}.
  static Map<String, dynamic> object(dynamic body) {
    final map = body as Map<String, dynamic>;
    final inner = map['data'];
    return inner is Map<String, dynamic> ? inner : map;
  }
}