/// Pengaturan dasar admin. Ubah di sini jika email admin berganti.
class AdminConfig {
  AdminConfig._();

  /// Hanya dua email ini yang bisa masuk sebagai admin.
  /// Keduanya memakai password yang SAMA dan membuka dashboard yang SAMA
  /// (satu akun admin, dua pintu masuk cadangan).
  static const List<String> emails = [
    'sadaqo.admin@gmail.com',
    'admin.amanahsdq@gmail.com',
  ];

  /// Password awal (bisa diganti admin di menu Pengaturan).
  static const String defaultPassword = 'adminamanahsdq99';

  /// Satu id akun untuk kedua email, agar data dashboard selalu sama.
  static const String accountId = 'admin-sadaqo';
  static const String defaultName = 'Admin SADAQO';
  static const String roleLabel = 'Administrator';

  static const int minPasswordLength = 8;
}
