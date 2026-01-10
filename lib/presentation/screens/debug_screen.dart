import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whdgkr/presentation/providers/dev_provider.dart';
import 'package:whdgkr/presentation/providers/trip_provider.dart';
import 'package:whdgkr/presentation/providers/friend_provider.dart';

/// 개발/테스트 전용 디버그 화면
/// - 운영 환경에서는 노출 금지
/// - 데이터 초기화 등 개발 편의 기능 제공
class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dataStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('개발자 도구'),
        backgroundColor: Colors.red.shade100,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 경고 배너
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '개발/테스트 전용 기능입니다.\n운영 환경에서는 사용하지 마세요.',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 데이터 통계
              Text(
                '현재 데이터 현황',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: statsAsync.when(
                    data: (stats) => Column(
                      children: [
                        _buildStatRow('여행', stats['trips'] ?? 0),
                        _buildStatRow('동행자', stats['participants'] ?? 0),
                        _buildStatRow('지출', stats['expenses'] ?? 0),
                        _buildStatRow('결제 내역', stats['expense_payments'] ?? 0),
                        _buildStatRow('분담 내역', stats['expense_shares'] ?? 0),
                        _buildStatRow('친구', stats['friends'] ?? 0),
                      ],
                    ),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => Text(
                      '통계 로드 실패: $e',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => ref.invalidate(dataStatsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('새로고침'),
              ),
              const SizedBox(height: 32),

              // 초기화 버튼
              Text(
                '데이터 초기화',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '앱 최초 설치 상태로 초기화',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '모든 여행, 동행자, 지출, 친구 데이터가 삭제됩니다.',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _showResetConfirmDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.delete_forever),
                          label: Text(_isLoading ? '초기화 중...' : '전체 초기화'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, dynamic count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '$count건',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// 1단계: 첫 번째 확인 다이얼로그
  Future<void> _showResetConfirmDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text('데이터 초기화'),
          ],
        ),
        content: const Text(
          '모든 데이터가 삭제됩니다.\n\n'
          '- 모든 여행\n'
          '- 모든 동행자\n'
          '- 모든 지출 내역\n'
          '- 모든 친구\n\n'
          '정말 초기화하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('초기화'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _showFinalConfirmDialog();
    }
  }

  /// 2단계: 최종 확인 다이얼로그
  Future<void> _showFinalConfirmDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text('최종 확인'),
          ],
        ),
        content: const Text(
          '되돌릴 수 없습니다.\n\n'
          '삭제된 데이터는 복구할 수 없습니다.\n'
          '정말로 진행하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제 진행'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _performReset();
    }
  }

  /// 실제 초기화 수행
  Future<void> _performReset() async {
    setState(() => _isLoading = true);

    try {
      final devRepository = ref.read(devRepositoryProvider);
      final result = await devRepository.resetAllData();

      // 모든 provider 새로고침
      ref.invalidate(tripsProvider);
      ref.invalidate(friendsProvider);
      ref.invalidate(dataStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('초기화 완료: ${result['message']}'),
            backgroundColor: Colors.green,
          ),
        );

        // 홈으로 이동
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('초기화 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
