import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whdgkr/core/network/api_client.dart';
import 'package:whdgkr/data/repositories/dev_repository.dart';
import 'package:whdgkr/presentation/providers/trip_provider.dart';

final devRepositoryProvider = Provider((ref) {
  return DevRepository(ref.watch(apiClientProvider));
});

final dataStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(devRepositoryProvider);
  return repository.getDataStats();
});
