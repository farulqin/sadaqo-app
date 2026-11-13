import 'package:dio/dio.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/core/network/api_client.dart';
import 'package:sadaqo/core/network/token_storage.dart';
import 'package:sadaqo/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:sadaqo/features/auth/data/models/user_model.dart';
import 'package:sadaqo/features/auth/domain/entities/gender.dart';

/// Implementasi auth yang memakai backend Laravel (Sanctum).
/// Token disimpan di TokenStorage; interceptor di ApiClient menempelkannya
/// otomatis ke setiap permintaan berikutnya.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dio, this._tokenStorage);

  final Dio _dio;
  final TokenStorage _tokenStorage;

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final res = await _dio.post(
        '/login',
        data: {'email': email.trim(), 'password': password},
      );
      return await _saveSession(res.data);
    } on DioException catch (e) {
      throw ServerException(_messageFrom(e));
    }
  }

  @override
  Future<UserModel> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final res = await _dio.post(
        '/register',
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          'password_confirmation': password,
        },
      );
      return await _saveSession(res.data);
    } on DioException catch (e) {
      throw ServerException(_messageFrom(e));
    }
  }

  @override
  Future<UserModel> loginWithProvider(String provider) async {
    // Backend belum punya endpoint Google/Apple.
    throw const ServerException(
      'Masuk lewat Google/Apple belum tersedia di server. Gunakan email dan password.',
    );
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post('/logout');
    } on DioException {
      // Abaikan: token tetap dihapus di perangkat.
    } finally {
      await _tokenStorage.clear();
    }
  }

  @override
  Future<UserModel> updateProfile(
    String email,
    String name,
    String? phone,
    Gender? gender,
  ) async {
    // Server mengenali pengguna dari token, jadi [email] tidak dikirim.
    try {
      final res = await _dio.put(
        '/me',
        data: {
          'name': name.trim(),
          'phone': phone,
          if (gender != null) 'gender': gender.key,
        },
      );
      return _userFrom(_userJson(res.data));
    } on DioException catch (e) {
      throw ServerException(_messageFrom(e));
    }
  }

  // ---------- helper ----------

  Future<UserModel> _saveSession(dynamic body) async {
    final map = body as Map<String, dynamic>;
    final token = map['token'];
    if (token is String && token.isNotEmpty) {
      await _tokenStorage.save(token);
    }
    return _userFrom(_userJson(map));
  }

  Map<String, dynamic> _userJson(dynamic body) {
    final map = body as Map<String, dynamic>;
    final inner = map['user'] ?? map['data'] ?? map;
    return inner as Map<String, dynamic>;
  }

  UserModel _userFrom(Map<String, dynamic> j) {
    final role = j['role'];
    return UserModel(
      id: '${j['id']}',
      name: (j['name'] ?? '') as String,
      email: (j['email'] ?? '') as String,
      phone: j['phone'] as String?,
      gender: Gender.fromKey(j['gender'] as String?),
      isAdmin: j['is_admin'] == true || role == 'admin',
      isManager: j['is_manager'] == true || role == 'pengelola',
    );
  }

  /// Pesan error: pakai galat validasi pertama kalau ada, lalu "message" server.
  String _messageFrom(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['errors'] is Map) {
      final errors = data['errors'] as Map;
      for (final v in errors.values) {
        if (v is List && v.isNotEmpty) return '${v.first}';
      }
    }
    return ApiClient.messageFrom(e);
  }
}