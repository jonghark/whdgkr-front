import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whdgkr/core/theme/app_theme.dart';
import 'package:whdgkr/presentation/providers/trip_provider.dart';
import 'package:intl/intl.dart';

class TripListScreen extends ConsumerWidget {
  const TripListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripsProvider);
    final matchedTripsAsync = ref.watch(matchedTripsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 여행', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            onPressed: () {
              context.push('/create-trip');
            },
          ),
        ],
      ),
      body: tripsAsync.when(
        data: (trips) {
          // 여행이 없으면 빈 상태 UI 표시
          if (trips.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.card_travel_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '아직 여행이 없습니다',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '새 여행을 만들어보세요!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/create-trip'),
                    icon: const Icon(Icons.add),
                    label: const Text('새 여행 만들기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          // 매칭된 여행 ID Set 생성 (빠른 조회를 위해)
          final matchedTripIds = matchedTripsAsync.maybeWhen(
            data: (matchedTrips) => matchedTrips.map((t) => t.id).toSet(),
            orElse: () => <int>{},
          );

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              final dateFormat = DateFormat('yyyy-MM-dd');
              final isMatched = matchedTripIds.contains(trip.id);

              return Dismissible(
                key: Key('trip_${trip.id}'),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('여행 삭제'),
                      content: Text('${trip.name}을(를) 삭제하시겠습니까?\n모든 지출 내역도 함께 삭제됩니다.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.negativeRed,
                          ),
                          child: const Text('삭제'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) async {
                  try {
                    final repository = ref.read(tripRepositoryProvider);
                    await repository.deleteTrip(trip.id);
                    ref.invalidate(tripsProvider);
                    ref.invalidate(matchedTripsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${trip.name}이(가) 삭제되었습니다'),
                          backgroundColor: AppTheme.positiveGreen,
                        ),
                      );
                    }
                  } catch (e) {
                    ref.invalidate(tripsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('삭제 실패: $e'),
                          backgroundColor: AppTheme.negativeRed,
                        ),
                      );
                    }
                  }
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.negativeRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete, color: Colors.white, size: 32),
                      SizedBox(height: 4),
                      Text('삭제', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                child: Card(
                  child: InkWell(
                    onTap: () {
                      context.push('/trip/${trip.id}');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.lightGreen,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.card_travel,
                                color: AppTheme.primaryGreen,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    trip.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${dateFormat.format(trip.startDate)} - ${dateFormat.format(trip.endDate)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '동행자 ${trip.activeParticipants.length}명',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            if (isMatched) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.group,
                                      size: 14,
                                      color: Colors.blue[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '친구 매칭',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.lightGreen,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '진행중',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('오류: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(tripsProvider),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
      // 여행이 1건 이상일 때만 FAB 노출 (0건일 때는 Empty State 버튼만 사용)
      floatingActionButton: tripsAsync.maybeWhen(
        data: (trips) => trips.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () => context.push('/create-trip'),
                icon: const Icon(Icons.add),
                label: const Text('새 여행'),
              )
            : null,
        orElse: () => null,
      ),
    );
  }
}
