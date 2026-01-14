import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whdgkr/presentation/providers/auth_provider.dart';

/// 영문 소문자와 숫자만 허용하는 TextInputFormatter
class LowercaseAlphanumericFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 대문자를 소문자로 변환하고, 영문 소문자와 숫자만 허용
    final lowercased = newValue.text.toLowerCase();
    final filtered = lowercased.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}

/// 이메일용 TextInputFormatter (영문 소문자, 숫자, @, ., _, %, +, - 허용)
class LowercaseEmailFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final lowercased = newValue.text.toLowerCase();
    final filtered = lowercased.replaceAll(RegExp(r'[^a-z0-9._%+\-@]'), '');
    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showErrorDetails(BuildContext context, AuthErrorDetails details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bug_report, color: Colors.orange),
            SizedBox(width: 8),
            Text('에러 상세 (DEV)'),
          ],
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            details.toDisplayString(),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).signup(
      loginId: _loginIdController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
    );

    if (success && mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // DEV 모드 테스트 계정 안내
                if (kDebugMode) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.amber),
                            SizedBox(width: 4),
                            Text(
                              '테스트용 예시 계정 정보 (DEV)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '이름: user1\n아이디: user1\n이메일: user1@example.com\n비밀번호: 1234',
                          style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '※ 자동으로 가입되거나 입력되지 않습니다.\n※ 직접 입력 후 회원가입을 진행해주세요.',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // 아이디 필드
                TextFormField(
                  controller: _loginIdController,
                  decoration: const InputDecoration(
                    labelText: '아이디',
                    hintText: '영문 소문자, 숫자만',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  inputFormatters: [
                    LowercaseAlphanumericFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '아이디를 입력해주세요';
                    }
                    if (value.trim().length < 4) {
                      return '아이디는 4자 이상이어야 합니다';
                    }
                    if (!RegExp(r'^[a-z0-9]+$').hasMatch(value)) {
                      return '아이디는 영문 소문자와 숫자만 가능합니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 이름 필드
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '이름',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '이름을 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 이메일 필드
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    hintText: '영문 소문자만 가능',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  inputFormatters: [
                    LowercaseEmailFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '이메일을 입력해주세요';
                    }
                    if (!RegExp(r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$').hasMatch(value)) {
                      return '이메일 형식을 확인해주세요(영문만 가능)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 비밀번호 필드 (숫자 4자리 PIN)
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: '비밀번호 (숫자 4자리)',
                    hintText: '숫자 4자리 입력',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요';
                    }
                    if (!RegExp(r'^[0-9]{4}$').hasMatch(value)) {
                      return '비밀번호는 숫자 4자리만 가능합니다';
                    }
                    return null;
                  },
                ),

                if (authState.error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          authState.error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                          textAlign: TextAlign.center,
                        ),
                        if (kDebugMode && authState.errorDetails != null) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => _showErrorDetails(context, authState.errorDetails!),
                            icon: const Icon(Icons.bug_report, size: 16),
                            label: const Text('자세히 보기 (DEV)'),
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: authState.status == AuthStatus.loading ? null : _signup,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: authState.status == AuthStatus.loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('회원가입', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('이미 계정이 있으신가요? 로그인'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
