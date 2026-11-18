import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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

  // Konfigurasi dikirim saat menjalankan aplikasi:
  // flutter run -d chrome --dart-define=GOOGLE_CLIENT_ID=xxxx.apps.googleusercontent.com
  static const _googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
  static const _appleServiceId = String.fromEnvironment('APPLE_SERVICE_ID');
  static const _appleRedirectUri = String.fromEnvironment('APPLE_REDIRECT_URI');

  @override
  Future<UserModel> loginWithProvider(String provider) async {
    try {
      switch (provider) {
        case 'Google':
          return await _loginGoogle();
        case 'Apple':
          return await _loginApple();
      }
      throw ServerException('Penyedia login $provider tidak dikenal');
    } on DioException catch (e) {
      throw ServerException(_messageFrom(e));
    } on PlatformException catch (e) {
      throw ServerException('Gagal masuk dengan $provider: ${e.message ?? e.code}');
    }
  }

  Future<UserModel> _loginGoogle() async {
    if (_googleClientId.isEmpty) {
      throw const ServerException(
        'Login Google belum dikonfigurasi. Jalankan aplikasi dengan --dart-define=GOOGLE_CLIENT_ID=<client id>.',
      );
    }
    final google = GoogleSignIn(
      scopes: const ['email', 'profile'],
      clientId: kIsWeb ? _googleClientId : null,
      serverClientId: kIsWeb ? null : _googleClientId,
    );
    final account = await google.signIn();
    if (account == null) throw const ServerException('Masuk dengan Google dibatalkan');
    final auth = await account.authentication;
    if (auth.idToken == null && auth.accessToken == null) {
      throw const ServerException('Google tidak mengirim token. Coba lagi.');
    }
    final res = await _dio.post(
      '/auth/google',
      data: {
        if (auth.idToken != null) 'id_token': auth.idToken,
        if (auth.accessToken != null) 'access_token': auth.accessToken,
      },
    );
    return _saveSession(res.data);
  }

  Future<UserModel> _loginApple() async {
    final native = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS);
    if (!native && (_appleServiceId.isEmpty || _appleRedirectUri.isEmpty)) {
      throw const ServerException(
        'Login Apple langsung tersedia di iPhone/iPad/Mac. Di Android dan web perlu APPLE_SERVICE_ID dan APPLE_REDIRECT_URI.',
      );
    }
    try {
      final cred = await SignInWithApple.getAppleIDCredential(
        scopes: const [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        webAuthenticationOptions: native
            ? null
            : WebAuthenticationOptions(clientId: _appleServiceId, redirectUri: Uri.parse(_appleRedirectUri)),
      );
      final token = cred.identityToken;
      if (token == null) throw const ServerException('Apple tidak mengirim token. Coba lagi.');
      final res = await _dio.post(
        '/auth/apple',
        data: {
          'identity_token': token,
          if (cred.givenName != null) 'given_name': cred.givenName,
          if (cred.familyName != null) 'family_name': cred.familyName,
        },
      );
      return await _saveSession(res.data);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const ServerException('Masuk dengan Apple dibatalkan');
      }
      throw ServerException('Gagal masuk dengan Apple: ${e.message}');
    }
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
  Future<UserModel?> restoreSession() async {
    final token = await _tokenStorage.read();
    if (token == null || token.isEmpty) return null;
    try {
      final res = await _dio.get('/me');
      return _userFrom(_userJson(res.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _tokenStorage.clear();
        return null;
      }
      throw ServerException(_messageFrom(e));
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