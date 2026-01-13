import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whdgkr/core/storage/secure_storage.dart';
import 'package:whdgkr/data/models/member.dart';
import 'package:whdgkr/data/repositories/auth_repository.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final Member? member;
  final String? error;

  AuthState({
    this.status = AuthStatus.initial,
    this.member,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    Member? member,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      member: member ?? this.member,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthState());

  Future<void> checkAuth() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final hasTokens = await SecureStorage.hasTokens();
      if (!hasTokens) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      final accessToken = await SecureStorage.getAccessToken();
      if (accessToken == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      try {
        final member = await _authRepository.getMe(accessToken);
        state = state.copyWith(status: AuthStatus.authenticated, member: member);
      } catch (e) {
        // access token 만료 시 refresh 시도
        try {
          await _authRepository.refresh();
          final newAccessToken = await SecureStorage.getAccessToken();
          if (newAccessToken != null) {
            final member = await _authRepository.getMe(newAccessToken);
            state = state.copyWith(status: AuthStatus.authenticated, member: member);
          } else {
            state = state.copyWith(status: AuthStatus.unauthenticated);
          }
        } catch (e) {
          await SecureStorage.clearTokens();
          state = state.copyWith(status: AuthStatus.unauthenticated);
        }
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, error: e.toString());
    }
  }

  Future<bool> login(String loginId, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);

    try {
      final response = await _authRepository.login(
        loginId: loginId,
        password: password,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        member: response.member,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: '로그인에 실패했습니다',
      );
      return false;
    }
  }

  Future<bool> signup({
    required String loginId,
    required String password,
    required String name,
    required String email,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);

    try {
      await _authRepository.signup(
        loginId: loginId,
        password: password,
        name: name,
        email: email,
      );
      // 회원가입 후 자동 로그인
      return await login(loginId, password);
    } catch (e) {
      String errorMessage = '회원가입에 실패했습니다';
      if (e.toString().contains('409')) {
        errorMessage = '이미 사용 중인 아이디 또는 이메일입니다';
      }
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: errorMessage,
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final authRepositoryProvider = Provider((ref) => AuthRepository());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
