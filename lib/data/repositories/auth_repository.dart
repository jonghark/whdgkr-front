import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:whdgkr/core/config/app_config.dart';
import 'package:whdgkr/core/storage/secure_storage.dart';
import 'package:whdgkr/core/utils/auth_logger.dart';
import 'package:whdgkr/data/models/member.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository() : _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
    headers: {'Content-Type': 'application/json'},
  )) {
    // 최소 로깅 인터셉터 (signup/login 요청만)
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.path.contains('/auth/signup') || options.path.contains('/auth/login')) {
          print('[AUTH_DIO] ${options.method} ${options.path}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (response.requestOptions.path.contains('/auth/signup') ||
            response.requestOptions.path.contains('/auth/login')) {
          print('[AUTH_DIO] ${response.requestOptions.method} ${response.requestOptions.path} -> ${response.statusCode}');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (error.requestOptions.path.contains('/auth/signup') ||
            error.requestOptions.path.contains('/auth/login')) {
          print('[AUTH_DIO] ${error.requestOptions.method} ${error.requestOptions.path} -> ERROR ${error.response?.statusCode ?? "NO_RESPONSE"}');
        }
        handler.next(error);
      },
    ));
  }

  Future<Member> signup({
    required String loginId,
    required String password,
    required String name,
    required String email,
  }) async {
    // [OBS] REPO 레이어 진입 확인
    debugPrint('[OBS] REPO_ENTER signup');
    const endpoint = '/auth/signup';
    const method = 'POST';
    final body = {
      'loginId': loginId,
      'password': password,
      'name': name,
      'email': email,
    };

    await AuthLogger.logRequest(endpoint: endpoint, method: method, body: body);

    try {
      // [OBS] NET 레이어 - 요청 직전
      debugPrint('[OBS] NET_SEND /auth/signup');
      final response = await _dio.post(endpoint, data: body);
      // [OBS] NET 레이어 - 응답 수신
      debugPrint('[OBS] NET_RESP status=${response.statusCode} error=null');

      await AuthLogger.logResponse(
        endpoint: endpoint,
        method: method,
        statusCode: response.statusCode ?? 200,
        responseBody: response.data,
      );

      return Member.fromJson(response.data);
    } on DioException catch (e, stackTrace) {
      // [OBS] NET 레이어 - 에러 응답
      debugPrint('[OBS] NET_RESP status=${e.response?.statusCode} error=${e.message}');
      await AuthLogger.logError(
        endpoint: endpoint,
        method: method,
        statusCode: e.response?.statusCode,
        responseBody: e.response?.data,
        errorMessage: e.message ?? 'Unknown error',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<LoginResponse> login({
    required String loginId,
    required String password,
  }) async {
    const endpoint = '/auth/login';
    const method = 'POST';
    final body = {
      'loginId': loginId,
      'password': password,
    };

    await AuthLogger.logRequest(endpoint: endpoint, method: method, body: body);

    try {
      final response = await _dio.post(endpoint, data: body);

      await AuthLogger.logResponse(
        endpoint: endpoint,
        method: method,
        statusCode: response.statusCode ?? 200,
        responseBody: response.data,
      );

      final loginResponse = LoginResponse.fromJson(response.data);

      await SecureStorage.saveTokens(
        accessToken: loginResponse.accessToken,
        refreshToken: loginResponse.refreshToken,
      );

      return loginResponse;
    } on DioException catch (e, stackTrace) {
      await AuthLogger.logError(
        endpoint: endpoint,
        method: method,
        statusCode: e.response?.statusCode,
        responseBody: e.response?.data,
        errorMessage: e.message ?? 'Unknown error',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<TokenResponse> refresh() async {
    const endpoint = '/auth/refresh';
    const method = 'POST';

    final refreshToken = await SecureStorage.getRefreshToken();
    if (refreshToken == null) {
      throw Exception('No refresh token');
    }

    final body = {'refreshToken': refreshToken};
    await AuthLogger.logRequest(endpoint: endpoint, method: method, body: body);

    try {
      final response = await _dio.post(endpoint, data: body);

      await AuthLogger.logResponse(
        endpoint: endpoint,
        method: method,
        statusCode: response.statusCode ?? 200,
        responseBody: response.data,
      );

      final tokenResponse = TokenResponse.fromJson(response.data);

      await SecureStorage.saveTokens(
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
      );

      return tokenResponse;
    } on DioException catch (e, stackTrace) {
      await AuthLogger.logError(
        endpoint: endpoint,
        method: method,
        statusCode: e.response?.statusCode,
        responseBody: e.response?.data,
        errorMessage: e.message ?? 'Unknown error',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    const endpoint = '/auth/logout';
    const method = 'POST';

    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken != null) {
        final body = {'refreshToken': refreshToken};
        await AuthLogger.logRequest(endpoint: endpoint, method: method, body: body);
        await _dio.post(endpoint, data: body);
      }
    } catch (e) {
      await AuthLogger.logError(
        endpoint: endpoint,
        method: method,
        errorMessage: e.toString(),
      );
    } finally {
      await SecureStorage.clearTokens();
    }
  }

  Future<Member> getMe(String accessToken) async {
    const endpoint = '/members/me';
    const method = 'GET';

    await AuthLogger.logRequest(endpoint: endpoint, method: method);

    try {
      final response = await _dio.get(
        endpoint,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      await AuthLogger.logResponse(
        endpoint: endpoint,
        method: method,
        statusCode: response.statusCode ?? 200,
        responseBody: response.data,
      );

      return Member.fromJson(response.data);
    } on DioException catch (e, stackTrace) {
      await AuthLogger.logError(
        endpoint: endpoint,
        method: method,
        statusCode: e.response?.statusCode,
        responseBody: e.response?.data,
        errorMessage: e.message ?? 'Unknown error',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
