import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whdgkr/core/theme/app_theme.dart';
import 'package:whdgkr/core/utils/phone_formatter.dart';
import 'package:whdgkr/presentation/providers/trip_provider.dart';
import 'package:whdgkr/presentation/providers/friend_provider.dart';

class ParticipantInput {
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  int? friendId;

  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
  }
}

class CreateTripScreen extends ConsumerStatefulWidget {
  const CreateTripScreen({super.key});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  final List<ParticipantInput> _participants = [ParticipantInput()];
  int _ownerIndex = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    for (var p in _participants) {
      p.dispose();
    }
    super.dispose();
  }

  void _addParticipant() {
    setState(() {
      _participants.add(ParticipantInput());
    });
  }

  void _showAddParticipantOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.people, color: AppTheme.primaryGreen),
              title: const Text('친구 목록에서 선택'),
              onTap: () {
                Navigator.pop(context);
                _showFriendSelectionDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.primaryGreen),
              title: const Text('직접 입력'),
              onTap: () {
                Navigator.pop(context);
                _addParticipant();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFriendSelectionDialog() {
    final friendsAsync = ref.read(friendsProvider);

    friendsAsync.when(
      data: (friends) {
        if (friends.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('등록된 친구가 없습니다'),
              backgroundColor: AppTheme.negativeRed,
            ),
          );
          return;
        }

        final selectedFriendIds = _participants
            .where((p) => p.friendId != null)
            .map((p) => p.friendId!)
            .toSet();

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('친구 선택'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  final isAlreadyAdded = selectedFriendIds.contains(friend.id);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isAlreadyAdded ? Colors.grey : AppTheme.lightGreen,
                      child: Text(
                        friend.name[0],
                        style: TextStyle(
                          color: isAlreadyAdded ? Colors.white : AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(friend.name),
                    subtitle: Text(
                      [friend.email, friend.phone].where((e) => e != null && e.isNotEmpty).join(' • '),
                    ),
                    trailing: isAlreadyAdded
                        ? const Chip(
                            label: Text('이미 추가됨', style: TextStyle(fontSize: 10)),
                            backgroundColor: Colors.grey,
                          )
                        : null,
                    enabled: !isAlreadyAdded,
                    onTap: isAlreadyAdded
                        ? null
                        : () {
                            Navigator.pop(context);
                            _addParticipantFromFriend(friend);
                          },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
            ],
          ),
        );
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('친구 목록 로딩 중...')),
        );
      },
      error: (error, stack) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('친구 목록 로딩 실패: $error'),
            backgroundColor: AppTheme.negativeRed,
          ),
        );
      },
    );
  }

  void _addParticipantFromFriend(friend) {
    setState(() {
      final participant = ParticipantInput();
      participant.friendId = friend.id;
      participant.nameController.text = friend.name;
      participant.phoneController.text = friend.phone ?? '';
      participant.emailController.text = friend.email ?? '';
      _participants.add(participant);
    });
  }

  void _removeParticipant(int index) {
    if (_participants.length <= 1) return;

    setState(() {
      _participants[index].dispose();
      _participants.removeAt(index);
      if (_ownerIndex >= _participants.length) {
        _ownerIndex = 0;
      } else if (_ownerIndex == index) {
        _ownerIndex = 0;
      } else if (_ownerIndex > index) {
        _ownerIndex--;
      }
    });
  }

  Future<void> _createTrip() async {
    if (!_formKey.currentState!.validate()) return;

    final participantsList = _participants.asMap().entries
        .map((entry) {
          final index = entry.key;
          final p = entry.value;
          final name = p.nameController.text.trim();
          if (name.isEmpty) return null;
          // 전화번호는 숫자만 저장
          final phoneNormalized = PhoneNumberFormatter.normalize(p.phoneController.text);
          final result = {
            'name': name,
            'phone': phoneNormalized.isEmpty ? null : phoneNormalized,
            'email': p.emailController.text.trim().isEmpty ? null : p.emailController.text.trim(),
            'isOwner': index == _ownerIndex,
          };
          if (p.friendId != null) {
            result['friendId'] = p.friendId;
          }
          return result;
        })
        .where((p) => p != null)
        .toList();

    if (participantsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('동행자를 한 명 이상 추가해주세요'),
          backgroundColor: AppTheme.negativeRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(tripRepositoryProvider);
      await repository.createTrip({
        'name': _nameController.text,
        'startDate': _startDate.toIso8601String().split('T')[0],
        'endDate': _endDate.toIso8601String().split('T')[0],
        'participants': participantsList,
      });

      if (mounted) {
        ref.invalidate(tripsProvider);
        // 여행 생성 시 동행자가 친구 목록에도 자동 등록됨 (API에서 처리)
        ref.invalidate(friendsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('여행이 생성되었습니다!'),
            backgroundColor: AppTheme.positiveGreen,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('여행 생성 실패: $e'),
            backgroundColor: AppTheme.negativeRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 여행 만들기', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Trip Name Card
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
                            Icons.card_travel,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '여행 정보',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '여행 이름',
                        hintText: '예: 도쿄 여행',
                        prefixIcon: Icon(Icons.edit),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '여행 이름을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dates Card
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
                            Icons.calendar_today,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '일정',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('시작일'),
                      subtitle: Text(_startDate.toString().split(' ')[0]),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setState(() => _startDate = date);
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('종료일'),
                      subtitle: Text(_endDate.toString().split(' ')[0]),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: _startDate,
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setState(() => _endDate = date);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Participants Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              '동행자',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: AppTheme.primaryGreen),
                          onPressed: _showAddParticipantOptions,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '대표를 선택해주세요. 나눠떨어지지 않는 금액은 대표에게 귀속됩니다.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ..._participants.asMap().entries.map((entry) {
                      final index = entry.key;
                      final participant = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _ownerIndex == index ? AppTheme.primaryGreen : Colors.grey.shade300,
                            width: _ownerIndex == index ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Radio<int>(
                                  value: index,
                                  groupValue: _ownerIndex,
                                  activeColor: AppTheme.primaryGreen,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _ownerIndex = value);
                                    }
                                  },
                                ),
                                const SizedBox(width: 4),
                                if (_ownerIndex == index)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.lightGreen,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      '대표',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                  ),
                                if (participant.friendId != null) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.people, size: 12, color: Colors.blue.shade700),
                                        const SizedBox(width: 2),
                                        Text(
                                          '친구',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                if (_participants.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle, color: AppTheme.negativeRed, size: 20),
                                    onPressed: () => _removeParticipant(index),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: participant.nameController,
                              decoration: InputDecoration(
                                labelText: '이름 *',
                                hintText: '동행자 이름',
                                prefixIcon: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppTheme.lightGreen,
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: AppTheme.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                isDense: true,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
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
                                    controller: participant.phoneController,
                                    decoration: const InputDecoration(
                                      labelText: '전화번호',
                                      hintText: '010-0000-0000',
                                      prefixIcon: Icon(Icons.phone, size: 20),
                                      isDense: true,
                                    ),
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
                                      PhoneNumberFormatter(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: participant.emailController,
                                    decoration: const InputDecoration(
                                      labelText: '이메일',
                                      hintText: 'email@example.com',
                                      prefixIcon: Icon(Icons.email, size: 20),
                                      isDense: true,
                                    ),
                                    keyboardType: TextInputType.emailAddress,
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
            const SizedBox(height: 24),

            // Create Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        '여행 만들기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
