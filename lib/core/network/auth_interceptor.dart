import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:whdgkr/core/config/app_config.dart';
import 'package:whdgkr/core/storage/secure_storage.dart';
import 'package:whdgkr/presentation/providers/dev_diagnostic_provider.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;
  final List<({RequestOptions options, ErrorInterceptorHandler handler})> _pendingRequests = [];

  AuthInterceptor(this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // DEV 모드에서 요청 기록
    if (kDebugMode) {
      DevDiagnosticNotifier.recordRequest(options.path);
    }
    final accessToken = await SecureStorage.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // DEV 모드에서 응답 기록
    if (kDebugMode) {
      DevDiagnosticNotifier.recordHttp(
        response.statusCode ?? 0,
        response.requestOptions.path,
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // DEV 모드에서 에러 기록
    if (kDebugMode) {
      final statusCode = err.response?.statusCode ?? 0;
      final endpoint = err.requestOptions.path;
      String? errorMessage;
      if (err.type == DioExceptionType.connectionTimeout ||
          err.type == DioExceptionType.connectionError) {
        DevDiagnosticNotifier.recordNetworkError(endpoint, '백엔드 연결 실패');
      } else {
        errorMessage = err.response?.data?.toString() ?? err.message;
        DevDiagnosticNotifier.recordHttp(statusCode, endpoint, errorMessage: errorMessage);
      }
    }
    if (err.response?.statusCode == 401) {
      final requestOptions = err.requestOptions;

      // auth 엔드포인트는 refresh 시도하지 않음
      if (requestOptions.path.contains('/auth/')) {
        return handler.next(err);
      }

      if (_isRefreshing) {
        // 이미 refresh 중이면 대기열에 추가
        _pendingRequests.add((options: requestOptions, handler: handler));
        return;
      }

      _isRefreshing = true;

      try {
        final refreshToken = await SecureStorage.getRefreshToken();
        if (refreshToken == null) {
          await _handleAuthFailure();
          return handler.next(err);
        }

        // refresh 요청
        final refreshDio = Dio(BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          headers: {'Content-Type': 'application/json'},
        ));

        final response = await refreshDio.post('/auth/refresh', data: {
          'refreshToken': refreshToken,
        });

        final newAccessToken = response.data['accessToken'] as String;
        final newRefreshToken = response.data['refreshToken'] as String;

        await SecureStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        // 원래 요청 재시도
        requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(requestOptions);
        handler.resolve(retryResponse);

        // 대기 중인 요청들 처리
        for (final pending in _pendingRequests) {
          pending.options.headers['Authorization'] = 'Bearer $newAccessToken';
          try {
            final response = await _dio.fetch(pending.options);
            pending.handler.resolve(response);
          } catch (e) {
            pending.handler.reject(DioException(requestOptions: pending.options, error: e));
          }
        }
        _pendingRequests.clear();
      } catch (e) {
        await _handleAuthFailure();
        // 대기 중인 요청들 모두 실패 처리
        for (final pending in _pendingRequests) {
          pending.handler.reject(DioException(requestOptions: pending.options, error: e));
        }
        _pendingRequests.clear();
        handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
  }

  Future<void> _handleAuthFailure() async {
    await SecureStorage.clearTokens();
    // 로그인 화면으로 이동하는 로직은 Provider에서 처리
  }
}
