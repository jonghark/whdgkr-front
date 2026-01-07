import 'package:flutter/foundation.dart';
import 'package:whdgkr/core/network/api_client.dart';
import 'package:whdgkr/data/models/friend.dart';

class FriendRepository {
  final ApiClient _apiClient;

  FriendRepository(this._apiClient);

  void _logError(String method, dynamic error, [StackTrace? stackTrace]) {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🔴 [FriendRepository.$method] 에러 발생');
    debugPrint('에러: $error');
    if (stackTrace != null) {
      debugPrint('스택트레이스: $stackTrace');
    }
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  Future<List<Friend>> getAllFriends() async {
    try {
      debugPrint('📡 [FriendRepository.getAllFriends] API 호출 시작');
      final response = await _apiClient.dio.get('/friends');
      debugPrint('✅ [FriendRepository.getAllFriends] 성공: ${response.data}');
      return (response.data as List).map((f) => Friend.fromJson(f)).toList();
    } catch (e, stackTrace) {
      _logError('getAllFriends', e, stackTrace);
      throw Exception('Failed to load friends: $e');
    }
  }

  Future<Friend> getFriendById(int id) async {
    try {
      debugPrint('📡 [FriendRepository.getFriendById] API 호출: id=$id');
      final response = await _apiClient.dio.get('/friends/$id');
      debugPrint('✅ [FriendRepository.getFriendById] 성공: ${response.data}');
      return Friend.fromJson(response.data);
    } catch (e, stackTrace) {
      _logError('getFriendById', e, stackTrace);
      throw Exception('Failed to load friend: $e');
    }
  }

  Future<Friend> createFriend(Map<String, dynamic> friendData) async {
    try {
      debugPrint('📡 [FriendRepository.createFriend] API 호출: $friendData');
      final response = await _apiClient.dio.post('/friends', data: friendData);
      debugPrint('✅ [FriendRepository.createFriend] 성공: ${response.data}');
      return Friend.fromJson(response.data);
    } catch (e, stackTrace) {
      _logError('createFriend', e, stackTrace);
      throw Exception('Failed to create friend: $e');
    }
  }

  Future<Friend> updateFriend(int id, Map<String, dynamic> friendData) async {
    try {
      debugPrint('📡 [FriendRepository.updateFriend] API 호출: id=$id, data=$friendData');
      final response = await _apiClient.dio.put('/friends/$id', data: friendData);
      debugPrint('✅ [FriendRepository.updateFriend] 성공: ${response.data}');
      return Friend.fromJson(response.data);
    } catch (e, stackTrace) {
      _logError('updateFriend', e, stackTrace);
      throw Exception('Failed to update friend: $e');
    }
  }

  Future<void> deleteFriend(int id) async {
    try {
      debugPrint('📡 [FriendRepository.deleteFriend] API 호출: id=$id');
      await _apiClient.dio.delete('/friends/$id');
      debugPrint('✅ [FriendRepository.deleteFriend] 성공');
    } catch (e, stackTrace) {
      _logError('deleteFriend', e, stackTrace);
      throw Exception('Failed to delete friend: $e');
    }
  }
}
