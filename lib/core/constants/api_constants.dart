/// Konfigurasi API.
/// - Emulator Android Studio mengakses komputer lewat 10.0.2.2 (bukan localhost).
/// - Selama backend Laravel belum jadi, aplikasi memakai datasource MOCK.
///   Pergantian ke API asli cukup dilakukan di injection_container.dart.
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://10.0.2.2:8000/api';
}
