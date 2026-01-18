import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whdgkr/presentation/providers/auth_provider.dart';
import 'package:whdgkr/presentation/providers/dev_diagnostic_provider.dart';

/// 영문 소문자와 숫자만 허용하는 TextInputFormatter
class LowercaseAlphanumericFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final lowercased = newValue.text.toLowerCase();
    final filtered = lowercased.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auth 화면에서는 health check 실행 안 함 (회원가입 요청과 혼선 방지)
  }

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
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

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildDiagnosticPanel(DevDiagnosticState diagState) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.terminal, size: 14, color: Colors.green),
              SizedBox(width: 4),
              Text('DEV 진단 패널 (Auth 화면에서는 stats 호출 안 함)', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(color: Colors.grey, height: 8),
          Text('Action: ${diagState.lastAction}', style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace')),
          Text('Endpoint: ${diagState.lastEndpoint ?? '-'}', style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace')),
          Text('Status: ${diagState.lastStatusCode ?? '-'}', style: TextStyle(color: _getStatusColor(diagState.lastStatusCode), fontSize: 10, fontFamily: 'monospace')),
          Text('Error: ${diagState.lastErrorMessage ?? '-'}', style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Color _getStatusColor(int? statusCode) {
    if (statusCode == null) return Colors.white70;
    if (statusCode >= 200 && statusCode < 300) return Colors.green;
    if (statusCode >= 400 && statusCode < 500) return Colors.orange;
    if (statusCode >= 500) return Colors.red;
    return Colors.white70;
  }

  Future<void> _login() async {
    // [A-1] 버튼 클릭 첫 줄 로그 (무조건 실행)
    debugPrint('LOGIN_CLICK');

    try {
      // 클릭 즉시 반응
      ref.read(devDiagnosticProvider.notifier).buttonClicked('LOGIN');
      _showSnackBar('로그인 요청 시작');

      // 로딩 중이면 중복 클릭 방지
      final authState = ref.read(authProvider);
      if (authState.status == AuthStatus.loading) {
        _showSnackBar('요청 처리 중입니다...', isError: true);
        return;
      }

      // 검증 실패 시 SnackBar
      if (!_formKey.currentState!.validate()) {
        ref.read(devDiagnosticProvider.notifier).validateFail('LOGIN');
        _showSnackBar('입력값을 확인해주세요 (아이디/비번)', isError: true);
        return;
      }

      // API 호출 시작
      ref.read(devDiagnosticProvider.notifier).requestSent('/auth/login');
      debugPrint('[LOGIN] Calling authProvider.login()');

      final success = await ref.read(authProvider.notifier).login(
        _loginIdController.text.trim(),
        _passwordController.text,
      );

      debugPrint('[LOGIN] Result: $success');

      // 결과 처리
      if (success) {
        _showSnackBar('로그인 성공!');
        if (mounted) {
          context.go('/');
        }
      } else {
        final authState = ref.read(authProvider);
        final errorMsg = authState.error ?? '로그인 실패';
        _showSnackBar('로그인 실패: $errorMsg', isError: true);
      }
    } catch (e, stackTrace) {
      debugPrint('[LOGIN] Unexpected error: $e');
      debugPrint('[LOGIN] StackTrace: $stackTrace');
      _showSnackBar('로그인 중 오류 발생: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final diagState = ref.watch(devDiagnosticProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // DEV 모드 진단 패널
                if (kDebugMode) _buildDiagnosticPanel(diagState),
                const SizedBox(height: 48),
                const Icon(
                  Icons.card_travel,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                const Text(
                  '여행 정산',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 48),

                // 아이디 필드
                TextFormField(
                  controller: _loginIdController,
                  decoration: const InputDecoration(
                    labelText: '아이디',
                    hintText: '영문 소문자, 숫자',
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
                    if (!RegExp(r'^[a-z0-9]+$').hasMatch(value)) {
                      return '아이디는 영문 소문자와 숫자만 가능합니다';
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
                    hintText: '숫자 4자리',
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
                  onPressed: _login,  // 항상 활성화 - 조건부 null 제거
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: authState.status == AuthStatus.loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('로그인', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    debugPrint('SIGNUP_LINK_CLICKED');
                    context.go('/signup');
                    debugPrint('NAVIGATING_TO_SIGNUP');
                  },
                  child: const Text('계정이 없으신가요? 회원가입'),
                ),
                TextButton(
                  onPressed: () => context.go('/reset-password'),
                  child: const Text('비밀번호를 잊으셨나요?'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
