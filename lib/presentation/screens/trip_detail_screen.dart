import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whdgkr/core/theme/app_theme.dart';
import 'package:whdgkr/presentation/providers/trip_provider.dart';
import 'package:whdgkr/data/models/settlement.dart';
import 'package:whdgkr/data/models/trip.dart';
import 'package:intl/intl.dart';

final settlementProvider = FutureProvider.family<Settlement, int>((ref, tripId) async {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.getSettlement(tripId);
});

class TripDetailScreen extends ConsumerWidget {
  final int tripId;

  const TripDetailScreen({super.key, required this.tripId});

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  void _showParticipantManagement(BuildContext context, WidgetRef ref, Trip trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ParticipantManagementSheet(tripId: tripId, trip: trip),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripDetailProvider(tripId));
    final settlementAsync = ref.watch(settlementProvider(tripId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('여행 상세', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: '참가자 관리',
            onPressed: () {
              final trip = tripAsync.valueOrNull;
              if (trip != null) {
                _showParticipantManagement(context, ref, trip);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            onPressed: () {
              context.push('/trip/$tripId/settlement');
            },
          ),
        ],
      ),
      body: tripAsync.when(
        data: (trip) {
          final dateFormat = DateFormat('yyyy-MM-dd');
          final activeParticipants = trip.activeParticipants;

          return Column(
            children: [
              // Trip Header Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.card_travel,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trip.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${dateFormat.format(trip.startDate)} - ${dateFormat.format(trip.endDate)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Owner info
                      if (trip.owner != null)
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Owner: ${trip.owner!.name}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.people, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${activeParticipants.length}명 참가: ${activeParticipants.map((p) => p.name).join(", ")}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Summary Cards with Settlement Data
              settlementAsync.when(
                data: (settlement) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Total Expense Card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.lightGreen,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long,
                                    color: AppTheme.primaryGreen,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '총 지출',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${settlement.formattedTotalExpense}원',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Participant Balances
                        if (settlement.balances.isNotEmpty) ...[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.lightGreen,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.people,
                                          color: AppTheme.primaryGreen,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        '참여자별 정산',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  ...settlement.balances.map((balance) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: balance.isOwed
                                                ? AppTheme.lightGreen
                                                : (balance.isOwing ? Colors.orange.shade50 : Colors.grey.shade200),
                                            child: Text(
                                              balance.participantName[0],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: balance.isOwed
                                                    ? AppTheme.primaryGreen
                                                    : (balance.isOwing ? AppTheme.accentOrange : Colors.grey),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  balance.participantName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  '지출: ${balance.formattedPaidTotal}원 / 부담: ${balance.formattedShareTotal}원',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${balance.formattedNetBalance}원',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: balance.isOwed
                                                      ? AppTheme.positiveGreen
                                                      : (balance.isOwing ? AppTheme.negativeRed : AppTheme.neutralGray),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: balance.isOwed
                                                      ? AppTheme.lightGreen
                                                      : (balance.isOwing ? Colors.orange.shade50 : Colors.grey.shade200),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  balance.isOwed ? '받을 돈' : (balance.isOwing ? '보낼 돈' : '정산완료'),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: balance.isOwed
                                                        ? AppTheme.primaryGreen
                                                        : (balance.isOwing ? AppTheme.accentOrange : Colors.grey),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.receipt_long, color: AppTheme.primaryGreen, size: 32),
                          const SizedBox(height: 8),
                          const Text('총 지출', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          const Text('0원', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Expenses List
              Expanded(
                child: trip.expenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '지출 내역이 없습니다',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '+ 버튼을 눌러 첫 지출을 추가하세요',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: trip.expenses.length,
                        itemBuilder: (context, index) {
                          final expense = trip.expenses[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              onTap: () => context.push('/trip/$tripId/expense/${expense.id}'),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.lightGreen,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.receipt,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              title: Text(
                                expense.title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                DateFormat('yyyy-MM-dd').format(expense.occurredAt),
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                              trailing: Text(
                                expense.formattedAmount,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
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
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/trip/$tripId/add-expense');
        },
        icon: const Icon(Icons.add),
        label: const Text('지출 추가'),
      ),
    );
  }
}

class ParticipantManagementSheet extends ConsumerStatefulWidget {
  final int tripId;
  final Trip trip;

  const ParticipantManagementSheet({super.key, required this.tripId, required this.trip});

  @override
  ConsumerState<ParticipantManagementSheet> createState() => _ParticipantManagementSheetState();
}

class _ParticipantManagementSheetState extends ConsumerState<ParticipantManagementSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _addParticipant() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력해주세요'), backgroundColor: AppTheme.negativeRed),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(tripRepositoryProvider);
      await repository.addParticipant(widget.tripId, {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      });

      ref.invalidate(tripDetailProvider(widget.tripId));
      ref.invalidate(settlementProvider(widget.tripId));

      if (mounted) {
        _nameController.clear();
        _phoneController.clear();
        _emailController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('참가자가 추가되었습니다'), backgroundColor: AppTheme.positiveGreen),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('추가 실패: $e'), backgroundColor: AppTheme.negativeRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteParticipant(Participant participant) async {
    if (participant.isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Owner는 삭제할 수 없습니다'), backgroundColor: AppTheme.negativeRed),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('참가자 삭제'),
        content: Text('${participant.name}을(를) 삭제하시겠습니까?\n기존 지출 내역은 유지됩니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: AppTheme.negativeRed)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(tripRepositoryProvider);
      await repository.deleteParticipant(widget.tripId, participant.id);

      ref.invalidate(tripDetailProvider(widget.tripId));
      ref.invalidate(settlementProvider(widget.tripId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('참가자가 삭제되었습니다'), backgroundColor: AppTheme.positiveGreen),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e'), backgroundColor: AppTheme.negativeRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '참가자 관리',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Add participant form
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('새 참가자 추가', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '이름 *',
                          isDense: true,
                          prefixIcon: Icon(Icons.person, size: 20),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: '전화번호',
                                isDense: true,
                                prefixIcon: Icon(Icons.phone, size: 20),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: '이메일',
                                isDense: true,
                                prefixIcon: Icon(Icons.email, size: 20),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _addParticipant,
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                          child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('추가'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Current participants
              const Text('현재 참가자', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: widget.trip.participants.length,
                  itemBuilder: (context, index) {
                    final participant = widget.trip.participants[index];
                    final isDeleted = participant.deleteYn == 'Y';

                    return Card(
                      color: isDeleted ? Colors.grey.shade200 : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: participant.isOwner ? Colors.amber.shade100 : AppTheme.lightGreen,
                          child: participant.isOwner
                              ? const Icon(Icons.star, color: Colors.amber)
                              : Text(
                                  participant.name[0],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDeleted ? Colors.grey : AppTheme.primaryGreen,
                                  ),
                                ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              participant.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: isDeleted ? TextDecoration.lineThrough : null,
                                color: isDeleted ? Colors.grey : null,
                              ),
                            ),
                            if (participant.isOwner) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Owner',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                                ),
                              ),
                            ],
                            if (isDeleted) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '삭제됨',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: participant.phone != null || participant.email != null
                            ? Text(
                                [participant.phone, participant.email].where((e) => e != null).join(' / '),
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              )
                            : null,
                        trailing: !participant.isOwner && !isDeleted
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppTheme.negativeRed),
                                onPressed: () => _deleteParticipant(participant),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
