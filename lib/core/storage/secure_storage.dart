import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  // DEV 모드 폴백용 in-memory 저장소 (macOS -34018 대응)
  static final Map<String, String> _memoryFallback = {};
  static bool _useFallback = false;

  static bool _isKeychainError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('-34018') || errorStr.contains('keychain');
  }

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (_useFallback) {
      _memoryFallback[_accessTokenKey] = accessToken;
      _memoryFallback[_refreshTokenKey] = refreshToken;
      return;
    }

    try {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    } catch (e) {
      if (_isKeychainError(e)) {
        if (kDebugMode) {
          // DEV: in-memory 폴백
          print('[SecureStorage] fallback_to_memory due to -34018');
          _useFallback = true;
          _memoryFallback[_accessTokenKey] = accessToken;
          _memoryFallback[_refreshTokenKey] = refreshToken;
        } else {
          // 릴리즈: 에러 throw
          throw Exception('macOS 키체인 권한 문제로 로그인 정보를 저장할 수 없습니다.');
        }
      } else {
        print('[SecureStorage] saveTokens failed: $e');
        rethrow;
      }
    }
  }

  static Future<String?> getAccessToken() async {
    if (_useFallback) {
      return _memoryFallback[_accessTokenKey];
    }

    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      if (_isKeychainError(e) && kDebugMode) {
        print('[SecureStorage] fallback_to_memory due to -34018');
        _useFallback = true;
        return _memoryFallback[_accessTokenKey];
      }
      print('[SecureStorage] getAccessToken failed: $e');
      return null;
    }
  }

  static Future<String?> getRefreshToken() async {
    if (_useFallback) {
      return _memoryFallback[_refreshTokenKey];
    }

    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      if (_isKeychainError(e) && kDebugMode) {
        print('[SecureStorage] fallback_to_memory due to -34018');
        _useFallback = true;
        return _memoryFallback[_refreshTokenKey];
      }
      print('[SecureStorage] getRefreshToken failed: $e');
      return null;
    }
  }

  static Future<void> clearTokens() async {
    if (_useFallback) {
      _memoryFallback.clear();
      return;
    }

    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
    } catch (e) {
      if (_isKeychainError(e) && kDebugMode) {
        print('[SecureStorage] fallback_to_memory due to -34018');
        _useFallback = true;
        _memoryFallback.clear();
      } else {
        print('[SecureStorage] clearTokens failed: $e');
      }
    }
  }

  static Future<bool> hasTokens() async {
    try {
      final accessToken = await getAccessToken();
      return accessToken != null && accessToken.isNotEmpty;
    } catch (e) {
      print('[SecureStorage] hasTokens failed: $e');
      return false;
    }
  }
}
