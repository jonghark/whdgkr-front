import 'package:dio/dio.dart';
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
  ));

  Future<Member> signup({
    required String loginId,
    required String password,
    required String name,
    required String email,
  }) async {
    print('[SIGNUP] AuthRepository.signup() called');
    const endpoint = '/auth/signup';
    const method = 'POST';
    final body = {
      'loginId': loginId,
      'password': password,
      'name': name,
      'email': email,
    };

    print('[SIGNUP] Request body: loginId=$loginId, name=$name, email=$email');
    await AuthLogger.logRequest(endpoint: endpoint, method: method, body: body);

    try {
      print('[SIGNUP] Sending POST request to $endpoint...');
      final response = await _dio.post(endpoint, data: body);
      print('[SIGNUP] Response received: statusCode=${response.statusCode}');

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
