class Settlement {
  final int totalExpense;
  final List<ParticipantBalance> balances;
  final List<Transfer> transfers;

  Settlement({
    required this.totalExpense,
    required this.balances,
    required this.transfers,
  });

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      totalExpense: json['totalExpense'] as int? ?? 0,
      balances: (json['balances'] as List)
          .map((b) => ParticipantBalance.fromJson(b))
          .toList(),
      transfers: (json['transfers'] as List? ?? [])
          .map((t) => Transfer.fromJson(t))
          .toList(),
    );
  }

  String get formattedTotalExpense {
    return '${totalExpense.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }
}

class ParticipantBalance {
  final int participantId;
  final String participantName;
  final int paidTotal;
  final int shareTotal;
  final int netBalance;

  ParticipantBalance({
    required this.participantId,
    required this.participantName,
    required this.paidTotal,
    required this.shareTotal,
    required this.netBalance,
  });

  factory ParticipantBalance.fromJson(Map<String, dynamic> json) {
    return ParticipantBalance(
      participantId: json['participantId'],
      participantName: json['participantName'],
      paidTotal: (json['paidTotal'] as num).toInt(),
      shareTotal: (json['shareTotal'] as num).toInt(),
      netBalance: (json['netBalance'] as num).toInt(),
    );
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  String get formattedPaidTotal => '${_formatAmount(paidTotal)}';
  String get formattedShareTotal => '${_formatAmount(shareTotal)}';
  String get formattedNetBalance {
    final absAmount = _formatAmount(netBalance.abs());
    if (netBalance > 0) return '+$absAmount';
    if (netBalance < 0) return '-$absAmount';
    return '0';
  }

  bool get isOwed => netBalance > 0;
  bool get isOwing => netBalance < 0;
  bool get isSettled => netBalance == 0;
}

class Transfer {
  final int fromParticipantId;
  final String fromParticipantName;
  final int toParticipantId;
  final String toParticipantName;
  final int amount;

  Transfer({
    required this.fromParticipantId,
    required this.fromParticipantName,
    required this.toParticipantId,
    required this.toParticipantName,
    required this.amount,
  });

  factory Transfer.fromJson(Map<String, dynamic> json) {
    return Transfer(
      fromParticipantId: json['fromParticipantId'],
      fromParticipantName: json['fromParticipantName'],
      toParticipantId: json['toParticipantId'],
      toParticipantName: json['toParticipantName'],
      amount: (json['amount'] as num).toInt(),
    );
  }

  String get formattedAmount {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  String get description => '$fromParticipantName님이 $toParticipantName님에게 ${formattedAmount}원을 보내세요';
}
