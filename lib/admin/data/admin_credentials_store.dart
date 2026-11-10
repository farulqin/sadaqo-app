import 'package:flutter/foundation.dart';
import 'package:sadaqo/admin/core/admin_config.dart';

/// Penyimpanan kredensial admin (di memori selama backend belum siap).
///
/// Dua email admin berbagi SATU password dan SATU profil, sehingga mengganti
/// password lewat Pengaturan otomatis berlaku untuk kedua email.
/// Nanti diganti autentikasi server (hash password, token, dll).
class AdminCredentialsStore extends ChangeNotifier {
  String _password = AdminConfig.defaultPassword;
  String _name = AdminConfig.defaultName;

  String get adminName => _name;

  bool isAdminEmail(String email) =>
      AdminConfig.emails.contains(email.trim().toLowerCase());

  bool verify(String email, String password) =>
      isAdminEmail(email) && password == _password;

  void setName(String name) {
    final n = name.trim();
    if (n.isEmpty || n == _name) return;
    _name = n;
    notifyListeners();
  }

  /// Mengembalikan pesan error, atau null jika berhasil.
  String? changePassword({
    required String current,
    required String next,
    required String confirm,
  }) {
    if (current != _password) return 'Password saat ini salah';
    if (next.length < AdminConfig.minPasswordLength) {
      return 'Password baru minimal ${AdminConfig.minPasswordLength} karakter';
    }
    if (next == current) return 'Password baru harus berbeda dari yang lama';
    if (next != confirm) return 'Konfirmasi password tidak sama';
    _password = next;
    notifyListeners();
    return null;
  }
}
