/// Pengaturan akun Pengelola Kampanye (data contoh sampai backend Laravel siap).
class PengelolaConfig {
  PengelolaConfig._();

  static const String email = 'sadaqo.pengelola@gmail.com';
  static const String password = 'pengelolaamanahsdq99';
  static const String accountId = 'pengelola-sadaqo';
  static const String name = 'Pengelola SADAQO';
  static const String roleLabel = 'Pengelola Kampanye';

  static bool isPengelolaEmail(String value) => value.trim().toLowerCase() == email;
}