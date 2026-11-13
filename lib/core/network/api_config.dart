import 'package:flutter/foundation.dart';

class ApiConfig {
  // Bisa ditimpa saat run: flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://127.0.0.1:8000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api'; // emulator Android
    }
    return 'http://127.0.0.1:8000/api';
  }

  /// Backend mengirim URL gambar berhost 127.0.0.1. Di emulator Android alamat itu
  /// menunjuk ke emulator sendiri, jadi host-nya disamakan dengan baseUrl.
  static String resolveMediaUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    if (uri.host == '127.0.0.1' || uri.host == 'localhost') {
      final base = Uri.parse(baseUrl);
      return uri
          .replace(scheme: base.scheme, host: base.host, port: base.port)
          .toString();
    }
    return url;
  }
}