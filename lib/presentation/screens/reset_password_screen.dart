import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whdgkr/presentation/providers/auth_provider.dart';
import 'package:whdgkr/presentation/screens/signup_screen.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 필드 수정 시 에러 자동 제거
    _loginIdController.addListener(_clearError);
    _emailController.addListener(_clearError);
  }

  void _clearError() {
    if (!mounted) return;
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  @override
  void dispose() {
    _loginIdController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    super.dispose();
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

  Future<void> _resetPassword() async {
    if (_isLoading) {
      _showSnackBar('요청 처리 중입니다...', isError: true);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      _showSnackBar('입력값을 확인해주세요', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ref.read(authProvider.notifier).resetPassword(
        loginId: _loginIdController.text.trim(),
        email: _emailController.text.trim(),
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showSnackBar('비밀번호가 재설정되었습니다. 로그인해주세요.');
        if (mounted) {
          context.go('/login');
        }
      } else {
        setState(() => _errorMessage = result['error'] ?? '비밀번호 재설정 실패');
        _showSnackBar('비밀번호 재설정 실패: ${result['error'] ?? '알 수 없는 오류'}', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = '비밀번호 재설정 중 오류 발생: $e');
      _showSnackBar('비밀번호 재설정 중 오류 발생: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('비밀번호 재설정'),
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
                const Text(
                  '아이디와 이메일을 입력하여\n비밀번호를 재설정하세요',
                  style: TextStyle(fontSize: 16, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

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
                    if (!RegExp(r'^[a-z0-9]+$').hasMatch(value)) {
                      return '아이디는 영문 소문자와 숫자만 가능합니다';
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

                // 새 비밀번호 필드
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: '새 비밀번호 (숫자 4자리)',
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
                      return '새 비밀번호를 입력해주세요';
                    }
                    if (!RegExp(r'^[0-9]{4}$').hasMatch(value)) {
                      return '비밀번호는 숫자 4자리만 가능합니다';
                    }
                    return null;
                  },
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('비밀번호 재설정', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('로그인 화면으로 돌아가기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
