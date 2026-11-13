import 'package:dio/dio.dart';

import 'api_client.dart';
import 'token_storage.dart';

/// Pembuat instance Dio. Sekarang sudah memakai interceptor token
/// (lihat api_client.dart) dan base URL dari api_config.dart.
class DioClient {
  DioClient._();

  static Dio create({
    TokenStorage? tokenStorage,
    void Function()? onUnauthorized,
  }) {
    return ApiClient(
      tokenStorage: tokenStorage ?? TokenStorage(),
      onUnauthorized: onUnauthorized,
    ).dio;
  }
}