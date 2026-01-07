import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:whdgkr/core/theme/app_theme.dart';
import 'package:whdgkr/presentation/providers/trip_provider.dart';
import 'package:whdgkr/presentation/screens/trip_detail_screen.dart';

// 3자리 콤마 포매터
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    final digitsOnly = newValue.text.replaceAll(',', '');
    if (digitsOnly.isEmpty) return const TextEditingValue(text: '');

    final number = int.tryParse(digitsOnly);
    if (number == null) return oldValue;

    final formatted = NumberFormat('#,###').format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class AddExpenseScreen extends ConsumerStatefulWidget {
  final int tripId;

  const AddExpenseScreen({super.key, required this.tripId});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _expenseDate;
  bool _isLoading = false;

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

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPayerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결제자를 선택해주세요'), backgroundColor: AppTheme.negativeRed),
      );
      return;
    }

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

    if (_expenseDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('날짜를 선택해주세요'), backgroundColor: AppTheme.negativeRed),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final totalAmount = _parseAmount(_amountController.text);

      // payments 구성 - 결제자가 전액 지불
      final payments = [
        {'participantId': _selectedPayerId, 'amount': totalAmount}
      ];

      // shares 구성
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
      await repository.createExpense(widget.tripId, expenseData);

      // 화면 갱신
      ref.invalidate(tripDetailProvider(widget.tripId));
      ref.invalidate(settlementProvider(widget.tripId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('지출이 추가되었습니다!'), backgroundColor: AppTheme.positiveGreen),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e'), backgroundColor: AppTheme.negativeRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripDetailProvider(widget.tripId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('지출 추가', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: tripAsync.when(
        data: (trip) {
          // 활성 참가자만 필터링
          final activeParticipants = trip.activeParticipants;

          // 초기화
          if (_selectedShareholders.isEmpty) {
            for (var participant in activeParticipants) {
              _selectedShareholders[participant.id] = true;
              _customShareControllers[participant.id] = TextEditingController();
            }
          }
          _expenseDate ??= trip.startDate;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 지출 정보 카드
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
                              child: const Icon(Icons.receipt_long, color: AppTheme.primaryGreen),
                            ),
                            const SizedBox(width: 12),
                            const Text('지출 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: '설명',
                            hintText: '예: 저녁 식사',
                            prefixIcon: Icon(Icons.edit),
                          ),
                          validator: (value) => (value == null || value.isEmpty) ? '설명을 입력해주세요' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: '금액',
                            hintText: '0',
                            prefixIcon: Icon(Icons.payments),
                            suffixText: '원',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            ThousandsSeparatorInputFormatter(),
                          ],
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
                            if (date != null) {
                              setState(() => _expenseDate = date);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: '날짜',
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(_expenseDate != null ? _dateFormat.format(_expenseDate!) : '날짜 선택'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 결제자 선택 카드
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

                // 분배 카드
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
                            setState(() => _splitType = selection.first);
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
                                    decoration: const InputDecoration(
                                      hintText: '금액',
                                      isDense: true,
                                      suffixText: '원',
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      ThousandsSeparatorInputFormatter(),
                                    ],
                                  ),
                            value: _selectedShareholders[participant.id] ?? false,
                            activeColor: AppTheme.primaryGreen,
                            onChanged: (value) {
                              setState(() {
                                _selectedShareholders[participant.id] = value ?? false;
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 저장 버튼
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveExpense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentOrange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('지출 저장', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
