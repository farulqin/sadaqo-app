import 'package:sadaqo/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:sadaqo/features/auth/data/models/user_model.dart';

/// Data dummy selama backend Laravel belum siap.
/// Email apa saja dan password >= 6 karakter dianggap berhasil.
class AuthMockDataSource implements AuthRemoteDataSource {
  @override
  Future<UserModel> login(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return UserModel(id: '1', name: 'Farid Ulil Yaqin', email: email);
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}
