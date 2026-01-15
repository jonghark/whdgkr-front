import 'package:flutter_riverpod/flutter_riverpod.dart';

class DevDiagnosticState {
  final String lastAction;
  final String? lastEndpoint;
  final int? lastStatusCode;
  final String? lastErrorMessage;
  final DateTime? timestamp;

  DevDiagnosticState({
    this.lastAction = 'IDLE',
    this.lastEndpoint,
    this.lastStatusCode,
    this.lastErrorMessage,
    this.timestamp,
  });

  DevDiagnosticState copyWith({
    String? lastAction,
    String? lastEndpoint,
    int? lastStatusCode,
    String? lastErrorMessage,
    DateTime? timestamp,
  }) {
    return DevDiagnosticState(
      lastAction: lastAction ?? this.lastAction,
      lastEndpoint: lastEndpoint ?? this.lastEndpoint,
      lastStatusCode: lastStatusCode,
      lastErrorMessage: lastErrorMessage,
      timestamp: timestamp ?? DateTime.now(),
    );
  }
}

/// Dio interceptor에서 접근 가능한 static callback
typedef DiagnosticCallback = void Function(String action, {String? endpoint, int? statusCode, String? errorMessage});

class DevDiagnosticNotifier extends StateNotifier<DevDiagnosticState> {
  /// static callback - Dio interceptor에서 호출
  static DiagnosticCallback? _globalCallback;

  static void setGlobalCallback(DiagnosticCallback? callback) {
    _globalCallback = callback;
  }

  /// Dio interceptor에서 호출하는 static 메서드
  static void recordHttp(int statusCode, String endpoint, {String? errorMessage}) {
    _globalCallback?.call('HTTP_$statusCode', endpoint: endpoint, statusCode: statusCode, errorMessage: errorMessage);
  }

  static void recordRequest(String endpoint) {
    _globalCallback?.call('REQUEST', endpoint: endpoint);
  }

  static void recordNetworkError(String endpoint, String message) {
    _globalCallback?.call('NET_ERR', endpoint: endpoint, errorMessage: message);
  }

  DevDiagnosticNotifier() : super(DevDiagnosticState()) {
    // Provider 생성 시 global callback 등록
    DevDiagnosticNotifier.setGlobalCallback(_onDiagnostic);
  }

  void _onDiagnostic(String action, {String? endpoint, int? statusCode, String? errorMessage}) {
    setAction(action, endpoint: endpoint, statusCode: statusCode, errorMessage: errorMessage);
  }

  void setAction(String action, {String? endpoint, int? statusCode, String? errorMessage}) {
    state = state.copyWith(
      lastAction: action,
      lastEndpoint: endpoint ?? state.lastEndpoint,
      lastStatusCode: statusCode,
      lastErrorMessage: errorMessage,
      timestamp: DateTime.now(),
    );
    print('[DEV_DIAG] $action | endpoint=$endpoint | status=$statusCode | error=$errorMessage');
  }

  void buttonClicked(String screen) {
    setAction('${screen}_CLICKED');
  }

  void validateFail(String screen) {
    setAction('${screen}_VALIDATE_FAIL', errorMessage: '입력값 누락');
  }

  void requestSent(String endpoint) {
    setAction('REQUEST_SENT', endpoint: endpoint);
  }

  void httpResponse(int statusCode, {String? errorMessage, String? endpoint}) {
    setAction('HTTP_$statusCode', statusCode: statusCode, errorMessage: errorMessage, endpoint: endpoint);
  }

  void networkError(String message) {
    setAction('NET_ERR', errorMessage: message);
  }

  void backendDown() {
    setAction('BACKEND_DOWN', errorMessage: '백엔드(8080) 미기동');
  }

  void backendOk() {
    setAction('BACKEND_OK');
  }
}

final devDiagnosticProvider = StateNotifierProvider<DevDiagnosticNotifier, DevDiagnosticState>((ref) {
  return DevDiagnosticNotifier();
});
