import 'package:dio/dio.dart';
import 'package:sadaqo/core/navigation/session_guard.dart';

import 'api_client.dart';
import 'token_storage.dart';

/// Pembuat instance Dio: base URL dari api_config.dart, token login otomatis,
/// dan sesi berakhir (401) diteruskan ke SessionGuard.
class DioClient {
  DioClient._();

  static Dio create({
    TokenStorage? tokenStorage,
    void Function()? onUnauthorized,
  }) {
    return ApiClient(
      tokenStorage: tokenStorage ?? TokenStorage(),
      onUnauthorized: onUnauthorized ?? SessionGuard.notifyExpired,
    ).dio;
  }
}