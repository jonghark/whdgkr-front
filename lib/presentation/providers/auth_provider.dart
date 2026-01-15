import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whdgkr/core/storage/secure_storage.dart';
import 'package:whdgkr/core/utils/auth_logger.dart';
import 'package:whdgkr/data/models/member.dart';
import 'package:whdgkr/data/repositories/auth_repository.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

/// 에러 상세 정보 (개발모드 '자세히 보기'용)
class AuthErrorDetails {
  final int? statusCode;
  final String? responseBody;
  final String? errorMessage;
  final DateTime timestamp;

  AuthErrorDetails({
    this.statusCode,
    this.responseBody,
    this.errorMessage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String toDisplayString() {
    final sb = StringBuffer();
    sb.writeln('Time: $timestamp');
    sb.writeln('Status: ${statusCode ?? "N/A"}');
    sb.writeln('Response: ${responseBody ?? "N/A"}');
    sb.writeln('Error: ${errorMessage ?? "N/A"}');
    return sb.toString();
  }
}

class AuthState {
  final AuthStatus status;
  final Member? member;
  final String? error;
  final AuthErrorDetails? errorDetails;

  AuthState({
    this.status = AuthStatus.initial,
    this.member,
    this.error,
    this.errorDetails,
  });

  AuthState copyWith({
    AuthStatus? status,
    Member? member,
    String? error,
    AuthErrorDetails? errorDetails,
  }) {
    return AuthState(
      status: status ?? this.status,
      member: member ?? this.member,
      error: error,
      errorDetails: errorDetails,
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
    state = state.copyWith(status: AuthStatus.loading, error: null, errorDetails: null);

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
      final statusCode = e.response?.statusCode;
      final responseBody = e.response?.data?.toString();
      final errorMessage = e.message;

      String displayMessage;
      if (statusCode == 401) {
        displayMessage = '아이디 또는 비밀번호가 올바르지 않습니다';
      } else if (statusCode == 400) {
        displayMessage = '입력값을 확인해주세요';
      } else if (statusCode == 500) {
        displayMessage = '서버 오류가 발생했습니다 (잠시 후 재시도)';
      } else if (e.type == DioExceptionType.connectionError ||
                 e.type == DioExceptionType.connectionTimeout) {
        displayMessage = '서버에 연결할 수 없습니다 (주소/포트 확인)';
      } else {
        displayMessage = '오류가 발생했습니다: ${statusCode ?? "알 수 없음"}';
      }

      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: displayMessage,
        errorDetails: AuthErrorDetails(
          statusCode: statusCode,
          responseBody: responseBody,
          errorMessage: errorMessage,
        ),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: '로그인에 실패했습니다',
        errorDetails: AuthErrorDetails(
          errorMessage: e.toString(),
        ),
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
    // [OBS] STATE 레이어 진입 확인
    debugPrint('[OBS] STATE_ENTER signup');
    state = state.copyWith(status: AuthStatus.loading, error: null, errorDetails: null);

    try {
      debugPrint('[OBS] STATE_CALL_REPO signup');
      await _authRepository.signup(
        loginId: loginId,
        password: password,
        name: name,
        email: email,
      );
      // 회원가입 후 자동 로그인
      return await login(loginId, password);
    } on DioException catch (e) {
      debugPrint('[OBS] STATE_ERROR signup status=${e.response?.statusCode}');
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;
      final responseBody = responseData?.toString();
      final errorMessage = e.message;

      String displayMessage;
      if (statusCode == 409) {
        // 서버 응답에서 구체적인 메시지 추출
        final serverMessage = responseData is Map ? responseData['message'] ?? responseData['error'] : null;
        if (serverMessage != null && serverMessage.toString().toLowerCase().contains('email')) {
          displayMessage = '이미 사용 중인 이메일입니다';
        } else if (serverMessage != null && serverMessage.toString().toLowerCase().contains('login')) {
          displayMessage = '이미 사용 중인 아이디입니다';
        } else {
          displayMessage = '이미 사용 중인 아이디 또는 이메일입니다';
        }
      } else if (statusCode == 400) {
        displayMessage = '입력값을 확인해주세요';
      } else if (statusCode == 500) {
        displayMessage = '서버 오류가 발생했습니다 (잠시 후 재시도)';
      } else if (e.type == DioExceptionType.connectionError ||
                 e.type == DioExceptionType.connectionTimeout) {
        displayMessage = '서버에 연결할 수 없습니다 (주소/포트 확인)';
      } else {
        displayMessage = '오류가 발생했습니다: ${statusCode ?? "알 수 없음"}';
      }

      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: displayMessage,
        errorDetails: AuthErrorDetails(
          statusCode: statusCode,
          responseBody: responseBody,
          errorMessage: errorMessage,
        ),
      );
      return false;
    } catch (e) {
      debugPrint('[OBS] STATE_ERROR signup unknown=$e');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: '회원가입에 실패했습니다',
        errorDetails: AuthErrorDetails(
          errorMessage: e.toString(),
        ),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(error: null, errorDetails: null);
  }
}

final authRepositoryProvider = Provider((ref) => AuthRepository());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
