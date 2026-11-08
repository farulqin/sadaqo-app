import 'package:sadaqo/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String name, String email, String password);
  Future<UserModel> loginWithProvider(String provider);
  Future<void> logout();
  Future<UserModel> updateProfile(String email, String name, String? phone);
}