import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whdgkr/data/models/friend.dart';
import 'package:whdgkr/data/repositories/friend_repository.dart';
import 'package:whdgkr/presentation/providers/trip_provider.dart';

final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FriendRepository(apiClient);
});

final friendsProvider = FutureProvider<List<Friend>>((ref) async {
  final repository = ref.watch(friendRepositoryProvider);
  return repository.getAllFriends();
});

final friendDetailProvider = FutureProvider.family<Friend, int>((ref, id) async {
  final repository = ref.watch(friendRepositoryProvider);
  return repository.getFriendById(id);
});
