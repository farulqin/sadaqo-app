import 'package:flutter/foundation.dart';
import 'package:sadaqo/admin/data/admin_user_store.dart';
import 'package:sadaqo/pengelola/core/pengelola_config.dart';

/// Data akun Pengelola (di memori selama backend belum siap): nama, nomor
/// telepon, dan password.
///
/// Nama dan nomor telepon WAJIB diisi karena pengelola adalah tim teknis SADAQO
/// yang harus bisa dihubungi admin. Datanya otomatis tampil di Kelola Pengguna
/// (admin) dengan label "Pengelola".
class PengelolaAccountStore extends ChangeNotifier {
  PengelolaAccountStore(this._directory) {
    _syncToAdmin();
  }

  static const int minPasswordLength = 8;

  final AdminUserStore _directory;

  String _name = PengelolaConfig.name;
  String _phone = '';
  String _password = PengelolaConfig.password;
  bool _notifications = true;

  String get name => _name;
  String get phone => _phone;
  String? get phoneOrNull => _phone.isEmpty ? null : _phone;
  bool get notificationsEnabled => _notifications;

  /// Profil lengkap = nama dan nomor telepon sudah valid.
  bool get isProfileComplete =>
      validateName(_name) == null && validatePhone(_phone) == null;

  bool verify(String password) => password == _password;

  static String? validateName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Nama wajib diisi';
    if (v.length < 3) return 'Nama minimal 3 karakter';
    return null;
  }

  static String? validatePhone(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return 'Nomor telepon wajib diisi';
    if (raw.length > 16) return 'Nomor telepon terlalu panjang';
    final digits = raw.replaceAll(RegExp(r'[\s\-]'), '');
    if (!RegExp(r'^(\+62|62|0)8\d{8,11}$').hasMatch(digits)) {
      return 'Gunakan nomor HP Indonesia, contoh 0812-3456-7890';
    }
    return null;
  }

  void saveProfile({required String name, required String phone}) {
    _name = name.trim();
    _phone = phone.trim();
    _syncToAdmin();
    notifyListeners();
  }

  void setNotifications(bool value) {
    if (_notifications == value) return;
    _notifications = value;
    notifyListeners();
  }

  /// Mengembalikan pesan error, atau null jika berhasil.
  String? changePassword({
    required String current,
    required String next,
    required String confirm,
  }) {
    if (current != _password) return 'Password saat ini salah';
    if (next.length < minPasswordLength) {
      return 'Password baru minimal $minPasswordLength karakter';
    }
    if (next == current) return 'Password baru harus berbeda dari yang lama';
    if (next != confirm) return 'Konfirmasi password tidak sama';
    _password = next;
    notifyListeners();
    return null;
  }

  /// Mencatat data pengelola ke daftar pengguna dashboard admin.
  void _syncToAdmin() {
    _directory.registerFromAuth(
      id: PengelolaConfig.accountId,
      name: _name,
      email: PengelolaConfig.email,
      phone: phoneOrNull,
      isManager: true,
    );
  }
}