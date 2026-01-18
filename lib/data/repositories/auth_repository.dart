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
    // [A-3] HTTP 요청/응답 강화된 로깅 인터셉터
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final fullUrl = '${options.baseUrl}${options.path}';
        final hasAuth = options.headers.containsKey('Authorization');

        debugPrint('[HTTP_REQ] ${options.method} $fullUrl');
        debugPrint('[HTTP_REQ] path=${options.path}');
        debugPrint('[HTTP_REQ] baseUrl=${options.baseUrl}');
        debugPrint('[HTTP_REQ] authHeader=${hasAuth ? 'YES' : 'NO'}');
        debugPrint('[HTTP_REQ] body=${options.data}');

        handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('[HTTP_RES] ${response.statusCode} ${response.requestOptions.path}');
        debugPrint('[HTTP_RES] body=${response.data}');

        handler.next(response);
      },
      onError: (error, handler) {
        final statusCode = error.response?.statusCode;
        final path = error.requestOptions.path;
        final message = error.message ?? 'No message';
        final body = error.response?.data;

        debugPrint('[HTTP_ERR] ${statusCode ?? 'NO_STATUS'} $path');
        debugPrint('[HTTP_ERR] message=$message');
        debugPrint('[HTTP_ERR] body=$body');
        debugPrint('[HTTP_ERR] type=${error.type}');

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
    // [A-4] path는 /auth/signup만 사용 (baseUrl에 이미 /api 포함)
    const endpoint = '/auth/signup';
    const method = 'POST';
    final body = {
      'loginId': loginId,
      'password': password,
      'name': name,
      'email': email,
    };

    // URL 중복 방지 확인 로그
    debugPrint('[REGISTER_URL] ${_dio.options.baseUrl}$endpoint');

    await AuthLogger.logRequest(endpoint: endpoint, method: method, body: body);

    try {
      final response = await _dio.post(endpoint, data: body);

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
