import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/usecases/usecase.dart';
import 'package:sadaqo/features/auth/domain/entities/app_user.dart';
import 'package:sadaqo/features/auth/domain/usecases/login_user.dart';
import 'package:sadaqo/features/auth/domain/usecases/login_with_provider.dart';
import 'package:sadaqo/features/auth/domain/usecases/logout_user.dart';
import 'package:sadaqo/features/auth/domain/usecases/register_user.dart';
import 'package:sadaqo/features/auth/presentation/cubit/auth_state.dart';

/// Alur: UI -> Cubit -> UseCase -> Repository -> DataSource.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required LoginUser loginUser,
    required RegisterUser registerUser,
    required LoginWithProvider loginWithProvider,
    required LogoutUser logoutUser,
  })  : _loginUser = loginUser,
        _registerUser = registerUser,
        _loginWithProvider = loginWithProvider,
        _logoutUser = logoutUser,
        super(const AuthInitial());

  final LoginUser _loginUser;
  final RegisterUser _registerUser;
  final LoginWithProvider _loginWithProvider;
  final LogoutUser _logoutUser;

  AppUser? get user {
    final s = state;
    return s is AuthAuthenticated ? s.user : null;
  }

  Future<void> login(String email, String password) async {
    emit(const AuthLoading());
    final result = await _loginUser(LoginParams(email: email, password: password));
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    emit(const AuthLoading());
    final result = await _registerUser(
      RegisterParams(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      ),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> loginWithProvider(String provider) async {
    emit(const AuthLoading());
    final result = await _loginWithProvider(provider);
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