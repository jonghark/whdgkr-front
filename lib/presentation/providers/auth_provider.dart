import 'package:dio/dio.dart';
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
    } on DioException catch (e) {
      print('[AuthNotifier.login] DioException: ${e.response?.statusCode}');

      String errorMessage;
      final statusCode = e.response?.statusCode;

      if (statusCode == 401) {
        errorMessage = '아이디 또는 비밀번호가 일치하지 않습니다';
      } else if (e.type == DioExceptionType.connectionError ||
                 e.type == DioExceptionType.connectionTimeout) {
        errorMessage = '서버에 연결할 수 없습니다';
      } else {
        errorMessage = '로그인에 실패했습니다';
      }

      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: errorMessage,
      );
      return false;
    } catch (e) {
      print('[AuthNotifier.login] Exception: $e');
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
    } on DioException catch (e) {
      print('[AuthNotifier.signup] DioException: ${e.response?.statusCode}');
      print('[AuthNotifier.signup] Response data: ${e.response?.data}');

      String errorMessage;
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;

      if (statusCode == 409) {
        // 서버 응답에서 구체적인 메시지 추출
        final serverMessage = responseData is Map ? responseData['message'] ?? responseData['error'] : null;
        if (serverMessage != null && serverMessage.toString().toLowerCase().contains('email')) {
          errorMessage = '이미 사용 중인 이메일입니다';
        } else if (serverMessage != null && serverMessage.toString().toLowerCase().contains('login')) {
          errorMessage = '이미 사용 중인 아이디입니다';
        } else {
          errorMessage = '이미 사용 중인 아이디 또는 이메일입니다';
        }
      } else if (statusCode == 400) {
        errorMessage = '입력값을 확인해주세요';
      } else if (statusCode == 500) {
        errorMessage = '서버 오류가 발생했습니다';
      } else if (e.type == DioExceptionType.connectionError ||
                 e.type == DioExceptionType.connectionTimeout) {
        errorMessage = '서버에 연결할 수 없습니다';
      } else {
        errorMessage = '회원가입에 실패했습니다';
      }

      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: errorMessage,
      );
      return false;
    } catch (e) {
      print('[AuthNotifier.signup] Exception: $e');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: '회원가입에 실패했습니다',
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
