import 'package:flutter/foundation.dart';
import 'package:whdgkr/core/network/api_client.dart';

/// 개발/테스트 전용 Repository
/// - 운영 환경에서는 사용 금지
/// - 데이터 초기화 등 개발 편의 기능 제공
class DevRepository {
  final ApiClient _apiClient;

  DevRepository(this._apiClient);

  /// 모든 데이터 초기화 (앱 최초 설치 상태로 복원)
  /// - DELETE 방식 사용 (TRUNCATE/DROP 절대 금지)
  Future<Map<String, dynamic>> resetAllData() async {
    try {
      debugPrint('[DevRepository.resetAllData] API call start');
      final response = await _apiClient.dio.post('/dev/reset');
      debugPrint('[DevRepository.resetAllData] Success: ${response.data}');
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      debugPrint('[DevRepository.resetAllData] Error: $e');
      debugPrint('StackTrace: $stackTrace');
      throw Exception('Failed to reset data: $e');
    }
  }

  /// 현재 데이터 통계 조회
  Future<Map<String, dynamic>> getDataStats() async {
    try {
      debugPrint('[DevRepository.getDataStats] API call start');
      final response = await _apiClient.dio.get('/dev/stats');
      debugPrint('[DevRepository.getDataStats] Success: ${response.data}');
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      debugPrint('[DevRepository.getDataStats] Error: $e');
      debugPrint('StackTrace: $stackTrace');
      throw Exception('Failed to get stats: $e');
    }
  }
}
