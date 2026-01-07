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

  void _showCompanionManagement(BuildContext context, WidgetRef ref, Trip trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CompanionManagementSheet(tripId: tripId, trip: trip),
    );
  }

  void _showDateEditDialog(BuildContext context, WidgetRef ref, Trip trip) {
    showDialog(
      context: context,
      builder: (context) => DateEditDialog(tripId: tripId, trip: trip),
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
            icon: const Icon(Icons.calculate_outlined),
            tooltip: '정산 상세',
            onPressed: () {
              context.push('/trip/$tripId/settlement');
            },
          ),
        ],
      ),
      body: tripAsync.when(
        data: (trip) {
          final dateFormat = DateFormat('yyyy-MM-dd');
          final activeCompanions = trip.activeParticipants;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.card_travel,
                                  color: Colors.white,
                                  size: 28,
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
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    InkWell(
                                      onTap: () => _showDateEditDialog(context, ref, trip),
                                      borderRadius: BorderRadius.circular(4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${dateFormat.format(trip.startDate)} - ${dateFormat.format(trip.endDate)}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white.withValues(alpha: 0.9),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.edit,
                                            size: 14,
                                            color: Colors.white.withValues(alpha: 0.7),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Owner info
                          if (trip.owner != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Owner: ${trip.owner!.name}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Companions row with management button
                          Row(
                            children: [
                              const Icon(Icons.people, color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '동행자 ${activeCompanions.length}명: ${activeCompanions.map((p) => p.name).join(", ")}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _showCompanionManagement(context, ref, trip),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.settings, color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        '관리',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Settlement Summary & Expense Cards
                  settlementAsync.when(
                    data: (settlement) {
                      final needsSettlement = settlement.balances.where((b) => b.netBalance != 0).length;

                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            // Total Expense Card
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.lightGreen,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.receipt_long,
                                        color: AppTheme.primaryGreen,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '총 지출',
                                            style: TextStyle(fontSize: 13, color: Colors.grey),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${settlement.formattedTotalExpense}원',
                                            style: const TextStyle(
                                              fontSize: 22,
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
                            const SizedBox(height: 8),

                            // Settlement Summary Card (NEW)
                            if (settlement.balances.isNotEmpty)
                              Card(
                                color: needsSettlement > 0 ? Colors.orange.shade50 : AppTheme.lightGreen,
                                child: InkWell(
                                  onTap: () => context.push('/trip/$tripId/settlement'),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: needsSettlement > 0
                                                ? Colors.orange.shade100
                                                : AppTheme.primaryGreen.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            needsSettlement > 0 ? Icons.sync_alt : Icons.check_circle,
                                            color: needsSettlement > 0 ? AppTheme.accentOrange : AppTheme.primaryGreen,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                needsSettlement > 0
                                                    ? '정산이 필요해요!'
                                                    : '정산 완료',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: needsSettlement > 0
                                                      ? AppTheme.accentOrange
                                                      : AppTheme.primaryGreen,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                needsSettlement > 0
                                                    ? '$needsSettlement명이 정산을 기다리고 있어요'
                                                    : '모든 동행자가 정산을 완료했어요',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right,
                                          color: Colors.grey[400],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),

                            // Companion Balances
                            if (settlement.balances.isNotEmpty) ...[
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: AppTheme.lightGreen,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Icon(
                                              Icons.people,
                                              color: AppTheme.primaryGreen,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            '동행자별 정산',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      ...settlement.balances.map((balance) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 16,
                                                backgroundColor: balance.isOwed
                                                    ? AppTheme.lightGreen
                                                    : (balance.isOwing ? Colors.orange.shade50 : Colors.grey.shade200),
                                                child: Text(
                                                  balance.participantName[0],
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    color: balance.isOwed
                                                        ? AppTheme.primaryGreen
                                                        : (balance.isOwing ? AppTheme.accentOrange : Colors.grey),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      balance.participantName,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    Text(
                                                      '지출: ${balance.formattedPaidTotal}원 / 부담: ${balance.formattedShareTotal}원',
                                                      style: TextStyle(
                                                        fontSize: 10,
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
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: balance.isOwed
                                                          ? AppTheme.positiveGreen
                                                          : (balance.isOwing ? AppTheme.negativeRed : AppTheme.neutralGray),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: balance.isOwed
                                                          ? AppTheme.lightGreen
                                                          : (balance.isOwing ? Colors.orange.shade50 : Colors.grey.shade200),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      balance.isOwed ? '받을 돈' : (balance.isOwing ? '보낼 돈' : '정산완료'),
                                                      style: TextStyle(
                                                        fontSize: 9,
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
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, stack) => Padding(
                      padding: const EdgeInsets.all(12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              const Icon(Icons.receipt_long, color: AppTheme.primaryGreen, size: 28),
                              const SizedBox(height: 6),
                              const Text('총 지출', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 2),
                              const Text('0원', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Expenses List
                  if (trip.expenses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 56,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '지출 내역이 없습니다',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '+ 버튼을 눌러 첫 지출을 추가하세요',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: trip.expenses.map((expense) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            child: ListTile(
                              dense: true,
                              onTap: () => context.push('/trip/$tripId/expense/${expense.id}'),
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.lightGreen,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.receipt,
                                  color: AppTheme.primaryGreen,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                expense.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(
                                '${DateFormat('yyyy-MM-dd').format(expense.occurredAt)} · ${expense.payerSummaryText}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 11),
                              ),
                              trailing: Text(
                                expense.formattedAmount,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
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

class CompanionManagementSheet extends ConsumerStatefulWidget {
  final int tripId;
  final Trip trip;

  const CompanionManagementSheet({super.key, required this.tripId, required this.trip});

  @override
  ConsumerState<CompanionManagementSheet> createState() => _CompanionManagementSheetState();
}

class _CompanionManagementSheetState extends ConsumerState<CompanionManagementSheet> {
  final _formKey = GlobalKey<FormState>();
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

  String _sanitizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  bool _isValidEmail(String email) {
    if (email.isEmpty) return true;
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _addCompanion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(tripRepositoryProvider);
      final phone = _sanitizePhone(_phoneController.text.trim());

      await repository.addParticipant(widget.tripId, {
        'name': _nameController.text.trim(),
        'phone': phone.isEmpty ? null : phone,
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim().toLowerCase(),
      });

      ref.invalidate(tripDetailProvider(widget.tripId));
      ref.invalidate(settlementProvider(widget.tripId));
      ref.invalidate(tripsProvider);

      if (mounted) {
        _nameController.clear();
        _phoneController.clear();
        _emailController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('동행자가 추가되었습니다'), backgroundColor: AppTheme.positiveGreen),
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

  Future<void> _deleteCompanion(Participant companion) async {
    if (companion.isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Owner는 삭제할 수 없습니다'), backgroundColor: AppTheme.negativeRed),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('동행자 삭제'),
        content: Text('${companion.name}을(를) 삭제하시겠습니까?\n기존 지출 내역은 유지됩니다.'),
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
      await repository.deleteParticipant(widget.tripId, companion.id);

      ref.invalidate(tripDetailProvider(widget.tripId));
      ref.invalidate(settlementProvider(widget.tripId));
      ref.invalidate(tripsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('동행자가 삭제되었습니다'), backgroundColor: AppTheme.positiveGreen),
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
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SafeArea(
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 16 + bottomPadding,
            ),
            children: [
              // Handle
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
              const SizedBox(height: 12),

              // Title
              const Text(
                '동행자 관리',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Add companion form
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('새 동행자 추가', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: '이름 *',
                            isDense: true,
                            prefixIcon: Icon(Icons.person, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '이름을 입력해주세요';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  labelText: '전화번호',
                                  hintText: '010-1234-5678',
                                  isDense: true,
                                  prefixIcon: Icon(Icons.phone, size: 20),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: '이메일',
                                  isDense: true,
                                  prefixIcon: Icon(Icons.email, size: 20),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty && !_isValidEmail(value)) {
                                    return '올바른 이메일 형식이 아닙니다';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _addCompanion,
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
              ),
              const SizedBox(height: 16),

              // Current companions section
              const Text('현재 동행자', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // Companion list items
              ...widget.trip.participants.map((companion) {
                final isDeleted = companion.deleteYn == 'Y';

                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  color: isDeleted ? Colors.grey.shade200 : null,
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: companion.isOwner ? Colors.amber.shade100 : AppTheme.lightGreen,
                      child: companion.isOwner
                          ? const Icon(Icons.star, color: Colors.amber, size: 18)
                          : Text(
                              companion.name[0],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDeleted ? Colors.grey : AppTheme.primaryGreen,
                              ),
                            ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          companion.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            decoration: isDeleted ? TextDecoration.lineThrough : null,
                            color: isDeleted ? Colors.grey : null,
                          ),
                        ),
                        if (companion.isOwner) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Owner',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber),
                            ),
                          ),
                        ],
                        if (isDeleted) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '삭제됨',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: companion.phone != null || companion.email != null
                        ? Text(
                            [companion.phone, companion.email].where((e) => e != null).join(' / '),
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          )
                        : null,
                    trailing: !companion.isOwner && !isDeleted
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.negativeRed, size: 20),
                            onPressed: () => _deleteCompanion(companion),
                          )
                        : null,
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class DateEditDialog extends ConsumerStatefulWidget {
  final int tripId;
  final Trip trip;

  const DateEditDialog({super.key, required this.tripId, required this.trip});

  @override
  ConsumerState<DateEditDialog> createState() => _DateEditDialogState();
}

class _DateEditDialogState extends ConsumerState<DateEditDialog> {
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isLoading = false;
  final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _startDate = widget.trip.startDate;
    _endDate = widget.trip.endDate;
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _saveDate() async {
    if (_startDate.isAfter(_endDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('시작일은 종료일보다 이후일 수 없습니다'),
          backgroundColor: AppTheme.negativeRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(tripRepositoryProvider);
      await repository.updateTrip(widget.tripId, {
        'startDate': _dateFormat.format(_startDate),
        'endDate': _dateFormat.format(_endDate),
      });

      ref.invalidate(tripDetailProvider(widget.tripId));
      ref.invalidate(tripsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('여행 일정이 수정되었습니다'),
            backgroundColor: AppTheme.positiveGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수정 실패: $e'), backgroundColor: AppTheme.negativeRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasChanges = _startDate != widget.trip.startDate || _endDate != widget.trip.endDate;
    final isValid = !_startDate.isAfter(_endDate);
    final canSave = hasChanges && isValid && !_isLoading;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_month, color: AppTheme.primaryGreen, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('일정 수정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                        Text('여행 기간을 변경할 수 있어요', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 20, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Period Section
              const Text('기간', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Start Date
                    InkWell(
                      onTap: _selectStartDate,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                            const SizedBox(width: 12),
                            const Text('시작일', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            const Spacer(),
                            Text(
                              _dateFormat.format(_startDate),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),
                    // End Date
                    InkWell(
                      onTap: _selectEndDate,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                            const SizedBox(width: 12),
                            const Text('종료일', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            const Spacer(),
                            Text(
                              _dateFormat.format(_endDate),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Validation message
              if (!isValid)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 14, color: AppTheme.negativeRed),
                      const SizedBox(width: 4),
                      Text(
                        '시작일은 종료일 이전이어야 합니다',
                        style: TextStyle(fontSize: 12, color: AppTheme.negativeRed),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('취소', style: TextStyle(color: Colors.grey[600])),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: canSave ? _saveDate : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('저장', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
