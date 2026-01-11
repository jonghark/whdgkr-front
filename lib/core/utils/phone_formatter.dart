import 'package:flutter/services.dart';

/// 전화번호 입력 시 자동 하이픈 포맷팅
/// - 입력: 자동으로 하이픈 추가 (010-1234-5678)
/// - 저장: 숫자만 저장 (01012345678)
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 숫자만 추출
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // 최대 11자리까지만 허용
    final truncated = digitsOnly.length > 11 ? digitsOnly.substring(0, 11) : digitsOnly;

    // 포맷팅
    final formatted = _formatPhoneNumber(truncated);

    // 커서 위치 계산
    int cursorPosition = formatted.length;
    if (newValue.selection.baseOffset <= newValue.text.length) {
      // 입력 위치까지의 숫자 개수 계산
      final textBeforeCursor = newValue.text.substring(0, newValue.selection.baseOffset);
      final digitsBeforeCursor = textBeforeCursor.replaceAll(RegExp(r'[^0-9]'), '').length;

      // 포맷된 문자열에서 해당 숫자 위치 찾기
      int digitCount = 0;
      for (int i = 0; i < formatted.length; i++) {
        if (RegExp(r'[0-9]').hasMatch(formatted[i])) {
          digitCount++;
        }
        if (digitCount == digitsBeforeCursor) {
          cursorPosition = i + 1;
          break;
        }
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }

  /// 전화번호 포맷팅 (하이픈 추가)
  static String _formatPhoneNumber(String digits) {
    if (digits.isEmpty) return '';

    // 11자리: 010-1234-5678
    if (digits.length == 11) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    }
    // 10자리: 010-123-4567
    else if (digits.length == 10) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    // 7자리 이상: 앞 3자리 + 하이픈 + 나머지
    else if (digits.length > 7) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    }
    // 4자리 이상 7자리 이하: 앞 3자리 + 하이픈 + 나머지
    else if (digits.length > 3) {
      return '${digits.substring(0, 3)}-${digits.substring(3)}';
    }
    // 3자리 이하: 그대로
    return digits;
  }

  /// 저장용 숫자만 추출
  static String normalize(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// 표시용 포맷팅 (저장된 숫자를 하이픈 포함으로 변환)
  static String format(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    final digits = normalize(phone);
    return _formatPhoneNumber(digits);
  }
}
