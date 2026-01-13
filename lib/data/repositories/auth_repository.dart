import 'package:dio/dio.dart';
import 'package:whdgkr/core/config/app_config.dart';
import 'package:whdgkr/core/storage/secure_storage.dart';
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
    print('[AuthRepository.signup] Request: POST /auth/signup');
    print('[AuthRepository.signup] Body: loginId=$loginId, name=$name, email=$email');
    try {
      final response = await _dio.post('/auth/signup', data: {
        'loginId': loginId,
        'password': password,
        'name': name,
        'email': email,
      });
      print('[AuthRepository.signup] Success: statusCode=${response.statusCode}');
      return Member.fromJson(response.data);
    } on DioException catch (e) {
      print('[AuthRepository.signup] Error: statusCode=${e.response?.statusCode}');
      print('[AuthRepository.signup] Error body: ${e.response?.data}');
      print('[AuthRepository.signup] Error message: ${e.message}');
      rethrow;
    }
  }

  Future<LoginResponse> login({
    required String loginId,
    required String password,
  }) async {
    print('[AuthRepository.login] Request: POST /auth/login');
    try {
      final response = await _dio.post('/auth/login', data: {
        'loginId': loginId,
        'password': password,
      });
      print('[AuthRepository.login] Success: statusCode=${response.statusCode}');
      final loginResponse = LoginResponse.fromJson(response.data);

      await SecureStorage.saveTokens(
        accessToken: loginResponse.accessToken,
        refreshToken: loginResponse.refreshToken,
      );

      return loginResponse;
    } on DioException catch (e) {
      print('[AuthRepository.login] Error: statusCode=${e.response?.statusCode}');
      print('[AuthRepository.login] Error body: ${e.response?.data}');
      rethrow;
    }
  }

  Future<TokenResponse> refresh() async {
    print('[AuthRepository.refresh] API call');
    final refreshToken = await SecureStorage.getRefreshToken();
    if (refreshToken == null) {
      throw Exception('No refresh token');
    }

    final response = await _dio.post('/auth/refresh', data: {
      'refreshToken': refreshToken,
    });
    print('[AuthRepository.refresh] Success');
    final tokenResponse = TokenResponse.fromJson(response.data);

    await SecureStorage.saveTokens(
      accessToken: tokenResponse.accessToken,
      refreshToken: tokenResponse.refreshToken,
    );

    return tokenResponse;
  }

  Future<void> logout() async {
    print('[AuthRepository.logout] API call');
    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken != null) {
        await _dio.post('/auth/logout', data: {
          'refreshToken': refreshToken,
        });
      }
    } catch (e) {
      print('[AuthRepository.logout] Error: $e');
    } finally {
      await SecureStorage.clearTokens();
    }
    print('[AuthRepository.logout] Done');
  }

  Future<Member> getMe(String accessToken) async {
    print('[AuthRepository.getMe] API call');
    final response = await _dio.get(
      '/members/me',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    print('[AuthRepository.getMe] Success');
    return Member.fromJson(response.data);
  }
}
