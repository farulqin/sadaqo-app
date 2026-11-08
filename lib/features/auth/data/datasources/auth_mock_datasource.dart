import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:sadaqo/features/auth/data/models/user_model.dart';

/// Data dummy selama backend Laravel belum siap.
/// - Login: email apa saja dan password >= 6 karakter dianggap berhasil.
///   Jika email pernah didaftarkan/diubah, nama dan nomor HP yang tersimpan dipakai.
/// - Daftar: email yang sama tidak boleh didaftarkan dua kali (selama aplikasi hidup).
/// - Google/Apple: disimulasikan dengan akun contoh.
class AuthMockDataSource implements AuthRemoteDataSource {
  final Map<String, String> _names = {}; // email -> nama
  final Map<String, String> _phones = {}; // email -> nomor HP

  UserModel _build(String email) {
    final key = email.trim().toLowerCase();
    return UserModel(
      id: 'u-${key.hashCode.abs()}',
      name: _names[key] ?? 'Farid Ulil Yaqin',
      email: email.trim(),
      phone: _phones[key],
    );
  }

  @override
  Future<UserModel> login(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return _build(email);
  }

  @override
  Future<UserModel> register(String name, String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final key = email.trim().toLowerCase();
    if (_names.containsKey(key)) {
      throw const ServerException('Email sudah terdaftar, silakan masuk');
    }
    _names[key] = name;
    return _build(email);
  }

  @override
  Future<UserModel> loginWithProvider(String provider) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return UserModel(
      id: 'p-${provider.toLowerCase()}',
      name: 'Pengguna $provider',
      email: '${provider.toLowerCase()}.demo@example.com',
    );
  }

  @override
  Future<UserModel> updateProfile(String email, String name, String? phone) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final key = email.trim().toLowerCase();
    _names[key] = name;
    if (phone == null) {
      _phones.remove(key);
    } else {
      _phones[key] = phone;
    }
    return _build(email);
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}