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
    print('[AuthRepository.signup] API call');
    final response = await _dio.post('/api/auth/signup', data: {
      'loginId': loginId,
      'password': password,
      'name': name,
      'email': email,
    });
    print('[AuthRepository.signup] Success');
    return Member.fromJson(response.data);
  }

  Future<LoginResponse> login({
    required String loginId,
    required String password,
  }) async {
    print('[AuthRepository.login] API call');
    final response = await _dio.post('/api/auth/login', data: {
      'loginId': loginId,
      'password': password,
    });
    print('[AuthRepository.login] Success');
    final loginResponse = LoginResponse.fromJson(response.data);

    await SecureStorage.saveTokens(
      accessToken: loginResponse.accessToken,
      refreshToken: loginResponse.refreshToken,
    );

    return loginResponse;
  }

  Future<TokenResponse> refresh() async {
    print('[AuthRepository.refresh] API call');
    final refreshToken = await SecureStorage.getRefreshToken();
    if (refreshToken == null) {
      throw Exception('No refresh token');
    }

    final response = await _dio.post('/api/auth/refresh', data: {
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
        await _dio.post('/api/auth/logout', data: {
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
      '/api/members/me',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    print('[AuthRepository.getMe] Success');
    return Member.fromJson(response.data);
  }
}
