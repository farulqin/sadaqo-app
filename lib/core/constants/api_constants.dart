/// Konfigurasi API.
/// - Emulator Android Studio mengakses komputer lewat 10.0.2.2 (bukan localhost).
/// - Selama backend belum jadi, set [useMock] = true agar data dummy dipakai.
class ApiConstants {
  ApiConstants._();

  static const bool useMock = true;
  static const String baseUrl = 'http://10.0.2.2:8000/api';
}
