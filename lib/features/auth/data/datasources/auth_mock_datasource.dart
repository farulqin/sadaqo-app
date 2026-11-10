import 'package:sadaqo/admin/core/admin_config.dart';
import 'package:sadaqo/admin/data/admin_credentials_store.dart';
import 'package:sadaqo/admin/data/admin_user_store.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:sadaqo/features/auth/data/models/user_model.dart';
import 'package:sadaqo/features/auth/domain/entities/gender.dart';

/// Data dummy selama backend Laravel belum siap.
/// - Login: email apa saja dan password >= 6 karakter dianggap berhasil.
///   Jika email pernah didaftarkan/diubah, nama, nomor HP, dan jenis kelamin dipakai.
/// - Daftar: email yang sama tidak boleh didaftarkan dua kali (selama aplikasi hidup).
/// - Google/Apple: disimulasikan dengan akun contoh.
/// - Admin: hanya 2 email di AdminConfig yang bisa masuk sebagai admin, dengan
///   password yang diperiksa ke AdminCredentialsStore (bisa diganti di Pengaturan admin).
class AuthMockDataSource implements AuthRemoteDataSource {
  AuthMockDataSource({AdminCredentialsStore? adminGate, AdminUserStore? directory})
      : _adminGate = adminGate,
        _directory = directory;

  final AdminCredentialsStore? _adminGate;
  final AdminUserStore? _directory; // daftar pengguna untuk dashboard admin

  final Map<String, String> _names = {}; // email -> nama
  final Map<String, String> _phones = {}; // email -> nomor HP
  final Map<String, Gender> _genders = {}; // email -> jenis kelamin

  UserModel _build(String email) {
    final key = email.trim().toLowerCase();
    final user = UserModel(
      id: 'u-${key.hashCode.abs()}',
      name: _names[key] ?? 'Farid Ulil Yaqin',
      email: email.trim(),
      phone: _phones[key],
      gender: _genders[key],
    );
    // Catat ke daftar pengguna dashboard admin.
    _directory?.registerFromAuth(
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
    );
    return user;
  }

  @override
  Future<UserModel> login(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final gate = _adminGate;
    if (gate != null && gate.isAdminEmail(email)) {
      // Dua email admin: wajib password yang benar. Satu id akun untuk keduanya
      // agar dashboard admin selalu sama.
      if (!gate.verify(email, password)) {
        throw const ServerException('Email atau password admin salah');
      }
      return UserModel(
        id: AdminConfig.accountId,
        name: gate.adminName,
        email: email.trim().toLowerCase(),
        isAdmin: true,
      );
    }
    return _build(email);
  }

  @override
  Future<UserModel> register(String name, String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final key = email.trim().toLowerCase();
    if (_adminGate?.isAdminEmail(email) ?? false) {
      throw const ServerException('Email ini tidak dapat didaftarkan');
    }
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
  Future<UserModel> updateProfile(
    String email,
    String name,
    String? phone,
    Gender? gender,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final key = email.trim().toLowerCase();
    _names[key] = name;
    if (phone == null) {
      _phones.remove(key);
    } else {
      _phones[key] = phone;
    }
    if (gender != null) _genders[key] = gender;
    return _build(email);
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}