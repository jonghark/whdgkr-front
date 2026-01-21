import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whdgkr/core/network/api_client.dart';
import 'package:whdgkr/data/models/trip.dart';
import 'package:whdgkr/data/models/settlement.dart';
import 'package:whdgkr/data/models/statistics.dart';
import 'package:whdgkr/data/repositories/trip_repository.dart';
import 'package:whdgkr/presentation/providers/auth_provider.dart';

final apiClientProvider = Provider((ref) => ApiClient());

final tripRepositoryProvider = Provider((ref) {
  return TripRepository(ref.watch(apiClientProvider));
});

final tripsProvider = FutureProvider<List<Trip>>((ref) async {
  // 로그인 전에는 보호 API 호출 차단
  final authState = ref.watch(authProvider);
  if (authState.status != AuthStatus.authenticated) {
    return [];
  }

  final repository = ref.watch(tripRepositoryProvider);
  return repository.getAllTrips();
});

final matchedTripsProvider = FutureProvider<List<Trip>>((ref) async {
  // 로그인 전에는 보호 API 호출 차단
  final authState = ref.watch(authProvider);
  if (authState.status != AuthStatus.authenticated) {
    return [];
  }

  final repository = ref.watch(tripRepositoryProvider);
  return repository.getMatchedTrips();
});

final tripDetailProvider = FutureProvider.family<Trip, int>((ref, tripId) async {
  // 로그인 전에는 보호 API 호출 차단
  final authState = ref.watch(authProvider);
  if (authState.status != AuthStatus.authenticated) {
    throw Exception('로그인이 필요합니다');
  }

  final repository = ref.watch(tripRepositoryProvider);
  return repository.getTripById(tripId);
});

/// 정산 데이터 Provider - 모든 화면에서 공통으로 사용
final settlementProvider = FutureProvider.family<Settlement, int>((ref, tripId) async {
  // 로그인 전에는 보호 API 호출 차단
  final authState = ref.watch(authProvider);
  if (authState.status != AuthStatus.authenticated) {
    throw Exception('로그인이 필요합니다');
  }

  final repository = ref.watch(tripRepositoryProvider);
  return repository.getSettlement(tripId);
});

/// 통계 데이터 Provider
final statisticsProvider = FutureProvider.family<Statistics, int>((ref, tripId) async {
  // 로그인 전에는 보호 API 호출 차단
  final authState = ref.watch(authProvider);
  if (authState.status != AuthStatus.authenticated) {
    throw Exception('로그인이 필요합니다');
  }

  final repository = ref.watch(tripRepositoryProvider);
  return repository.getStatistics(tripId);
});
