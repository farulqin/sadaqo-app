import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:sadaqo/features/auth/data/models/user_model.dart';

/// Data dummy selama backend Laravel belum siap.
/// - Login: email apa saja dan password >= 6 karakter dianggap berhasil.
///   Jika email pernah didaftarkan, nama yang dipakai adalah nama saat daftar.
/// - Daftar: email yang sama tidak boleh didaftarkan dua kali (selama aplikasi hidup).
/// - Google/Apple: disimulasikan dengan akun contoh.
class AuthMockDataSource implements AuthRemoteDataSource {
  final Map<String, String> _registeredNames = {}; // email -> nama

  @override
  Future<UserModel> login(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final key = email.trim().toLowerCase();
    final name = _registeredNames[key] ?? 'Farid Ulil Yaqin';
    return UserModel(id: 'u-${key.hashCode.abs()}', name: name, email: email.trim());
  }

  @override
  Future<UserModel> register(String name, String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final key = email.trim().toLowerCase();
    if (_registeredNames.containsKey(key)) {
      throw const ServerException('Email sudah terdaftar, silakan masuk');
    }
    _registeredNames[key] = name;
    return UserModel(id: 'u-${key.hashCode.abs()}', name: name, email: email.trim());
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
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}