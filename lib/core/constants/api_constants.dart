import 'package:sadaqo/core/network/api_config.dart';

/// Konfigurasi API.
/// - Alamat server diatur di core/network/api_config.dart
///   (emulator Android: 10.0.2.2, web/desktop: 127.0.0.1,
///   HP asli: flutter run --dart-define=API_BASE_URL=http://IP_LAPTOP:8000/api).
/// - Pergantian dari datasource MOCK ke API asli dilakukan
///   di injection_container.dart.
class ApiConstants {
  ApiConstants._();

  static String get baseUrl => ApiConfig.baseUrl;
}