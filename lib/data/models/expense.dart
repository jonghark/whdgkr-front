class Expense {
  final int id;
  final String title;
  final DateTime occurredAt;
  final int totalAmount;
  final String currency;
  final DateTime createdAt;
  final String settledYn;
  final DateTime? settledAt;
  final List<PaymentDetail> payments;
  final List<ShareDetail> shares;

  Expense({
    required this.id,
    required this.title,
    required this.occurredAt,
    required this.totalAmount,
    required this.currency,
    required this.createdAt,
    required this.settledYn,
    this.settledAt,
    required this.payments,
    required this.shares,
  });

  bool get isSettled => settledYn == 'Y';

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as int,
      title: json['title'] as String,
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      totalAmount: json['totalAmount'] as int,
      currency: json['currency'] as String? ?? 'KRW',
      createdAt: DateTime.parse(json['createdAt'] as String),
      settledYn: json['settledYn'] as String? ?? 'N',
      settledAt: json['settledAt'] != null
          ? DateTime.parse(json['settledAt'] as String)
          : null,
      payments: (json['payments'] as List<dynamic>?)
              ?.map((p) => PaymentDetail.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      shares: (json['shares'] as List<dynamic>?)
              ?.map((s) => ShareDetail.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String get formattedAmount {
    final formatted = totalAmount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '$formatted원';
  }

  /// 대표 결제자 요약 텍스트
  /// - 1명: "이름"
  /// - 2명 이상: "대표이름 외 N명" (대표 = 가장 많이 낸 사람, 동률 시 이름순)
  String get payerSummaryText {
    if (payments.isEmpty) return '';

    if (payments.length == 1) {
      return payments.first.participantName;
    }

    // 금액 내림차순, 동률 시 이름 오름차순 정렬
    final sorted = List<PaymentDetail>.from(payments)
      ..sort((a, b) {
        final amountCompare = b.amount.compareTo(a.amount);
        if (amountCompare != 0) return amountCompare;
        return a.participantName.compareTo(b.participantName);
      });

    final representative = sorted.first.participantName;
    final othersCount = payments.length - 1;
    return '$representative 외 $othersCount명';
  }
}

class PaymentDetail {
  final int participantId;
  final String participantName;
  final int amount;

  PaymentDetail({
    required this.participantId,
    required this.participantName,
    required this.amount,
  });

  factory PaymentDetail.fromJson(Map<String, dynamic> json) {
    return PaymentDetail(
      participantId: json['participantId'] as int,
      participantName: json['participantName'] as String,
      amount: json['amount'] as int,
    );
  }
}

class ShareDetail {
  final int participantId;
  final String participantName;
  final int amount;

  ShareDetail({
    required this.participantId,
    required this.participantName,
    required this.amount,
  });

  factory ShareDetail.fromJson(Map<String, dynamic> json) {
    return ShareDetail(
      participantId: json['participantId'] as int,
      participantName: json['participantName'] as String,
      amount: json['amount'] as int,
    );
  }
}
