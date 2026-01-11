import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:whdgkr/core/theme/app_theme.dart';
import 'package:whdgkr/presentation/providers/trip_provider.dart';
import 'package:whdgkr/presentation/screens/add_expense_screen.dart';

enum ExpenseViewMode { view, edit }

class EditExpenseScreen extends ConsumerStatefulWidget {
  final int tripId;
  final int expenseId;

  const EditExpenseScreen({super.key, required this.tripId, required this.expenseId});

  @override
  ConsumerState<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends ConsumerState<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _expenseDate;
  bool _isLoading = false;
  bool _isInitialized = false;
  ExpenseViewMode _viewMode = ExpenseViewMode.view;

  String _splitType = 'equal';
  int? _selectedPayerId;
  Map<int, bool> _selectedShareholders = {};
  Map<int, TextEditingController> _customShareControllers = {};

  final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    for (var controller in _customShareControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int _parseAmount(String text) {
    return int.tryParse(text.replaceAll(',', '')) ?? 0;
  }

  String _formatAmount(int amount) {
    return NumberFormat('#,###').format(amount);
  }

  /// 직접입력 모드에서 체크박스 변경 시 균등 분배 재계산
  void _recalculateCustomShares(List<dynamic> activeParticipants) {
    final totalAmount = _parseAmount(_amountController.text);
    if (totalAmount <= 0) return;

    // 선택된 동행자 목록
    final selectedIds = _selectedShareholders.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedIds.isEmpty) return;

    // 균등 분배 계산
    final shareAmount = totalAmount ~/ selectedIds.length;
    final remainder = totalAmount % selectedIds.length;

    // 나머지는 대표에게, 대표가 없으면 이름순 첫 번째 동행자에게
    int? ownerId;
    String? firstParticipantName;
    int? firstParticipantId;

    for (var p in activeParticipants) {
      if (selectedIds.contains(p.id)) {
        if (p.isOwner == true) {
          ownerId = p.id;
        }
        if (firstParticipantName == null || p.name.compareTo(firstParticipantName) < 0) {
          firstParticipantName = p.name;
          firstParticipantId = p.id;
        }
      }
    }

    final remainderRecipientId = ownerId ?? firstParticipantId;

    // 각 컨트롤러에 금액 설정
    for (var entry in _selectedShareholders.entries) {
      final controller = _customShareControllers[entry.key];
      if (controller != null) {
        if (entry.value) {
          // 선택된 경우
          final extra = (entry.key == remainderRecipientId && remainder > 0) ? remainder : 0;
          final amount = shareAmount + extra;
          controller.text = _formatAmount(amount);
        } else {
          // 선택 해제된 경우 비우기
          controller.text = '';
        }
      }
    }
  }

  Future<void> _updateExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPayerId == null || _expenseDate == null) return;

    final selectedShareholderIds = _selectedShareholders.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedShareholderIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('나눌 사람을 한 명 이상 선택해주세요'), backgroundColor: AppTheme.negativeRed),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final totalAmount = _parseAmount(_amountController.text);
      final payments = [{'participantId': _selectedPayerId, 'amount': totalAmount}];

      List<Map<String, dynamic>> shares;
      if (_splitType == 'equal') {
        final shareAmount = totalAmount ~/ selectedShareholderIds.length;
        final remainder = totalAmount % selectedShareholderIds.length;
        shares = selectedShareholderIds.asMap().entries.map((entry) {
          final extra = entry.key < remainder ? 1 : 0;
          return {'participantId': entry.value, 'amount': shareAmount + extra};
        }).toList();
      } else {
        shares = selectedShareholderIds.map((id) {
          final controller = _customShareControllers[id];
          final amount = controller != null ? _parseAmount(controller.text) : 0;
          return {'participantId': id, 'amount': amount};
        }).toList();

        // 직접입력 모드일 때 분배 금액 합계 검증
        final shareSum = shares.fold<int>(0, (sum, s) => sum + (s['amount'] as int));
        if (shareSum != totalAmount) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('분배 금액 합계($shareSum원)가 총액($totalAmount원)과 일치하지 않습니다'),
              backgroundColor: AppTheme.negativeRed,
            ),
          );
          return;
        }
      }

      final expenseData = {
        'title': _titleController.text.trim(),
        'occurredAt': '${_dateFormat.format(_expenseDate!)}T12:00:00',
        'totalAmount': totalAmount,
        'currency': 'KRW',
        'payments': payments,
        'shares': shares,
      };

      final repository = ref.read(tripRepositoryProvider);
      await repository.updateExpense(widget.expenseId, expenseData);

      ref.invalidate(tripDetailProvider(widget.tripId));
      ref.invalidate(settlementProvider(widget.tripId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('지출이 수정되었습니다'), backgroundColor: AppTheme.positiveGreen),
        );
        context.pop();
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

  Future<void> _deleteExpense() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('지출 삭제'),
        content: const Text('이 지출을 삭제하시겠습니까?'),
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
      await repository.deleteExpense(widget.expenseId);

      ref.invalidate(tripDetailProvider(widget.tripId));
      ref.invalidate(settlementProvider(widget.tripId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('지출이 삭제되었습니다'), backgroundColor: AppTheme.positiveGreen),
        );
        context.pop();
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
    final tripAsync = ref.watch(tripDetailProvider(widget.tripId));

    final isViewMode = _viewMode == ExpenseViewMode.view;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isViewMode ? '지출 상세' : '지출 수정',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (!isViewMode) {
              setState(() => _viewMode = ExpenseViewMode.view);
            } else {
              context.pop();
            }
          },
        ),
        actions: [
          if (isViewMode)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryGreen),
              onPressed: () => setState(() => _viewMode = ExpenseViewMode.edit),
            )
          else
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.negativeRed),
              onPressed: _isLoading ? null : _deleteExpense,
            ),
        ],
      ),
      body: tripAsync.when(
        data: (trip) {
          // 활성 동행자만 필터링
          final activeParticipants = trip.activeParticipants;

          // 초기화
          if (!_isInitialized) {
            for (var participant in activeParticipants) {
              _selectedShareholders[participant.id] = false;
              _customShareControllers[participant.id] = TextEditingController();
            }

            // 기존 지출 데이터 로드
            final expense = trip.expenses.firstWhere((e) => e.id == widget.expenseId);
            _titleController.text = expense.title;
            _amountController.text = _formatAmount(expense.totalAmount);
            _expenseDate = expense.occurredAt;

            if (expense.payments.isNotEmpty) {
              _selectedPayerId = expense.payments.first.participantId;
            }

            for (var share in expense.shares) {
              _selectedShareholders[share.participantId] = true;
              _customShareControllers[share.participantId]?.text = _formatAmount(share.amount);
            }

            _isInitialized = true;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
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
                              decoration: BoxDecoration(color: AppTheme.lightGreen, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.receipt_long, color: AppTheme.primaryGreen),
                            ),
                            const SizedBox(width: 12),
                            const Text('지출 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(labelText: '설명', hintText: '예: 저녁 식사', prefixIcon: Icon(Icons.edit)),
                          validator: (value) => (value == null || value.isEmpty) ? '설명을 입력해주세요' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(labelText: '금액', hintText: '0', prefixIcon: Icon(Icons.payments), suffixText: '원'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsSeparatorInputFormatter()],
                          validator: (value) {
                            if (value == null || value.isEmpty) return '금액을 입력해주세요';
                            if (_parseAmount(value) <= 0) return '0보다 큰 금액을 입력해주세요';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _expenseDate ?? trip.startDate,
                              firstDate: trip.startDate,
                              lastDate: trip.endDate,
                            );
                            if (date != null) setState(() => _expenseDate = date);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: '날짜', prefixIcon: Icon(Icons.calendar_today)),
                            child: Text(_expenseDate != null ? _dateFormat.format(_expenseDate!) : '날짜 선택'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

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
                              decoration: BoxDecoration(color: AppTheme.lightGreen, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.account_balance_wallet, color: AppTheme.primaryGreen),
                            ),
                            const SizedBox(width: 12),
                            const Text('누가 결제했나요?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...activeParticipants.map((participant) {
                          return RadioListTile<int>(
                            title: Text(participant.name),
                            value: participant.id,
                            groupValue: _selectedPayerId,
                            activeColor: AppTheme.primaryGreen,
                            onChanged: (value) => setState(() => _selectedPayerId = value),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

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
                              decoration: BoxDecoration(color: AppTheme.lightGreen, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.pie_chart, color: AppTheme.primaryGreen),
                            ),
                            const SizedBox(width: 12),
                            const Text('누구와 나눌까요?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'equal', label: Text('균등'), icon: Icon(Icons.people)),
                            ButtonSegment(value: 'custom', label: Text('직접 입력'), icon: Icon(Icons.tune)),
                          ],
                          selected: {_splitType},
                          onSelectionChanged: (Set<String> selection) {
                            setState(() {
                              _splitType = selection.first;
                              // 직접입력 모드로 전환 시 균등 분배값으로 초기화
                              if (_splitType == 'custom') {
                                _recalculateCustomShares(activeParticipants);
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        ...activeParticipants.map((participant) {
                          return CheckboxListTile(
                            title: Text(participant.name),
                            subtitle: _splitType == 'equal'
                                ? null
                                : TextField(
                                    controller: _customShareControllers[participant.id],
                                    decoration: const InputDecoration(hintText: '금액', isDense: true, suffixText: '원'),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsSeparatorInputFormatter()],
                                  ),
                            value: _selectedShareholders[participant.id] ?? false,
                            activeColor: AppTheme.primaryGreen,
                            onChanged: (value) {
                              setState(() {
                                _selectedShareholders[participant.id] = value ?? false;
                                // 직접입력 모드에서 체크 변경 시 균등 분배 재계산
                                if (_splitType == 'custom') {
                                  _recalculateCustomShares(activeParticipants);
                                }
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateExpense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentOrange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('수정 저장', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('오류: $error')),
      ),
    );
  }
}
