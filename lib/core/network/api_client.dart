import 'package:dio/dio.dart';

import 'api_config.dart';
import 'token_storage.dart';

class ApiClient {
  final Dio dio;
  final TokenStorage tokenStorage;

  /// Dipanggil saat server membalas 401 (token habis/tidak valid).
  /// Nanti dipakai untuk mengembalikan pengguna ke halaman login.
  void Function()? onUnauthorized;

  ApiClient({required this.tokenStorage, this.onUnauthorized})
      : dio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {'Accept': 'application/json'},
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.read();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final is401 = error.response?.statusCode == 401;
          final isLogin = error.requestOptions.path.endsWith('/login');
          if (is401 && !isLogin) {
            await tokenStorage.clear();
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  /// Mengubah error Dio menjadi pesan yang bisa ditampilkan ke pengguna.
  static String messageFrom(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      switch (error.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return 'Tidak dapat terhubung ke server. Pastikan server berjalan.';
        default:
          return 'Terjadi kesalahan. Coba lagi.';
      }
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}