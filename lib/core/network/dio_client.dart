import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

/// Pembuat instance Dio. Token autentikasi akan ditambahkan
/// lewat interceptor saat fitur auth dibuat.
class DioClient {
  DioClient._();

  static Dio create() {
    return Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Accept': 'application/json'},
      ),
    );
  }
}
