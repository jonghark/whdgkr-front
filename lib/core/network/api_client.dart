import 'package:dio/dio.dart';
import 'package:whdgkr/core/config/app_config.dart';
import 'package:whdgkr/core/network/auth_interceptor.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
    _dio.interceptors.add(AuthInterceptor(_dio));
  }

  Dio get dio => _dio;
}
