import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whdgkr/core/network/api_client.dart';
import 'package:whdgkr/data/models/trip.dart';
import 'package:whdgkr/data/repositories/trip_repository.dart';

final apiClientProvider = Provider((ref) => ApiClient());

final tripRepositoryProvider = Provider((ref) {
  return TripRepository(ref.watch(apiClientProvider));
});

final tripsProvider = FutureProvider<List<Trip>>((ref) async {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.getAllTrips();
});

final tripDetailProvider = FutureProvider.family<Trip, int>((ref, tripId) async {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.getTripById(tripId);
});
