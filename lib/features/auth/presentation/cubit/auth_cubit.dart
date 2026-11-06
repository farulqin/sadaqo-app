import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/usecases/usecase.dart';
import 'package:sadaqo/features/auth/domain/entities/app_user.dart';
import 'package:sadaqo/features/auth/domain/usecases/login_user.dart';
import 'package:sadaqo/features/auth/domain/usecases/logout_user.dart';
import 'package:sadaqo/features/auth/presentation/cubit/auth_state.dart';

/// Cubit = Bloc versi ringkas (tanpa event class). Alurnya sama:
/// UI -> Cubit -> UseCase -> Repository -> DataSource.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required LoginUser loginUser, required LogoutUser logoutUser})
      : _loginUser = loginUser,
        _logoutUser = logoutUser,
        super(const AuthInitial());

  final LoginUser _loginUser;
  final LogoutUser _logoutUser;

  AppUser? get user {
    final s = state;
    return s is AuthAuthenticated ? s.user : null;
  }

  Future<void> login(String email, String password) async {
    emit(const AuthLoading());
    final result = await _loginUser(
      LoginParams(email: email, password: password),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> logout() async {
    await _logoutUser(const NoParams());
    emit(const AuthUnauthenticated());
  }
}
