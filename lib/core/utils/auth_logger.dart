import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 인증 관련 API 로그를 파일과 콘솔에 저장하는 유틸리티
class AuthLogger {
  static File? _logFile;
  static final List<AuthLogEntry> _recentLogs = [];

  /// 최근 로그 목록 (UI에서 조회용)
  static List<AuthLogEntry> get recentLogs => List.unmodifiable(_recentLogs);

  /// 가장 최근 에러 로그
  static AuthLogEntry? get lastError =>
      _recentLogs.where((e) => e.isError).lastOrNull;

  /// 로그 파일 초기화
  static Future<void> init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${directory.path}/logs');
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }
      _logFile = File('${logsDir.path}/auth.log');
      debugPrint('[AuthLogger] Log file: ${_logFile!.path}');
    } catch (e) {
      debugPrint('[AuthLogger] Failed to init log file: $e');
    }
  }

  /// 요청 로그
  static Future<void> logRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
  }) async {
    final maskedBody = _maskPassword(body);
    final entry = AuthLogEntry(
      timestamp: DateTime.now(),
      type: 'REQUEST',
      endpoint: endpoint,
      method: method,
      requestBody: maskedBody,
    );

    _addLog(entry);
    await _writeToFile(entry);
  }

  /// 응답 성공 로그
  static Future<void> logResponse({
    required String endpoint,
    required String method,
    required int statusCode,
    dynamic responseBody,
  }) async {
    final entry = AuthLogEntry(
      timestamp: DateTime.now(),
      type: 'RESPONSE',
      endpoint: endpoint,
      method: method,
      statusCode: statusCode,
      responseBody: responseBody?.toString(),
      isError: statusCode >= 400,
    );

    _addLog(entry);
    await _writeToFile(entry);
  }

  /// 에러 로그
  static Future<void> logError({
    required String endpoint,
    required String method,
    int? statusCode,
    dynamic responseBody,
    required String errorMessage,
    StackTrace? stackTrace,
  }) async {
    final entry = AuthLogEntry(
      timestamp: DateTime.now(),
      type: 'ERROR',
      endpoint: endpoint,
      method: method,
      statusCode: statusCode,
      responseBody: responseBody?.toString(),
      errorMessage: errorMessage,
      stackTrace: stackTrace?.toString(),
      isError: true,
    );

    _addLog(entry);
    await _writeToFile(entry);

    // 콘솔에 눈에 띄게 출력
    debugPrint('');
    debugPrint('========== AUTH ERROR ==========');
    debugPrint('Endpoint: $method $endpoint');
    debugPrint('Status: $statusCode');
    debugPrint('Response: $responseBody');
    debugPrint('Error: $errorMessage');
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }
    debugPrint('================================');
    debugPrint('');
  }

  static void _addLog(AuthLogEntry entry) {
    _recentLogs.add(entry);
    // 최근 100개만 유지
    if (_recentLogs.length > 100) {
      _recentLogs.removeAt(0);
    }
  }

  static Future<void> _writeToFile(AuthLogEntry entry) async {
    if (_logFile == null) return;

    try {
      final line = entry.toLogLine();
      await _logFile!.writeAsString('$line\n', mode: FileMode.append);
    } catch (e) {
      debugPrint('[AuthLogger] Failed to write log: $e');
    }
  }

  static Map<String, dynamic>? _maskPassword(Map<String, dynamic>? body) {
    if (body == null) return null;
    final masked = Map<String, dynamic>.from(body);
    if (masked.containsKey('password')) {
      masked['password'] = '***';
    }
    return masked;
  }

  /// 로그 파일 경로 반환
  static String? get logFilePath => _logFile?.path;

  /// 최근 로그 클리어
  static void clearRecentLogs() {
    _recentLogs.clear();
  }
}

/// 로그 항목 데이터 클래스
class AuthLogEntry {
  final DateTime timestamp;
  final String type;
  final String endpoint;
  final String method;
  final Map<String, dynamic>? requestBody;
  final int? statusCode;
  final String? responseBody;
  final String? errorMessage;
  final String? stackTrace;
  final bool isError;

  AuthLogEntry({
    required this.timestamp,
    required this.type,
    required this.endpoint,
    required this.method,
    this.requestBody,
    this.statusCode,
    this.responseBody,
    this.errorMessage,
    this.stackTrace,
    this.isError = false,
  });

  String toLogLine() {
    final sb = StringBuffer();
    sb.writeln('[$timestamp] $type $method $endpoint');
    if (requestBody != null) sb.writeln('  Request: $requestBody');
    if (statusCode != null) sb.writeln('  Status: $statusCode');
    if (responseBody != null) sb.writeln('  Response: $responseBody');
    if (errorMessage != null) sb.writeln('  Error: $errorMessage');
    if (stackTrace != null) sb.writeln('  StackTrace: $stackTrace');
    sb.writeln('---');
    return sb.toString();
  }

  /// UI 표시용 요약
  String toDisplayString() {
    final sb = StringBuffer();
    sb.writeln('[$type] $method $endpoint');
    sb.writeln('Time: $timestamp');
    if (statusCode != null) sb.writeln('Status: $statusCode');
    if (responseBody != null) sb.writeln('Response: $responseBody');
    if (errorMessage != null) sb.writeln('Error: $errorMessage');
    return sb.toString();
  }
}
