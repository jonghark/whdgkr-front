import 'package:whdgkr/data/models/expense.dart';

class Trip {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String deleteYn;
  final DateTime createdAt;
  final Participant? owner;
  final List<Participant> participants;
  final List<Expense> expenses;

  Trip({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.deleteYn = 'N',
    required this.createdAt,
    this.owner,
    required this.participants,
    required this.expenses,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as int,
      name: json['name'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      deleteYn: json['deleteYn'] as String? ?? 'N',
      createdAt: DateTime.parse(json['createdAt'] as String),
      owner: json['owner'] != null
          ? Participant.fromJson(json['owner'] as Map<String, dynamic>)
          : null,
      participants: (json['participants'] as List<dynamic>?)
              ?.map((p) => Participant.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      expenses: (json['expenses'] as List<dynamic>?)
              ?.map((e) => Expense.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  List<Participant> get activeParticipants =>
      participants.where((p) => p.deleteYn == 'N').toList();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String().split('T')[0],
      'endDate': endDate.toIso8601String().split('T')[0],
      'participants': participants.map((p) => p.toJson()).toList(),
    };
  }
}

class Participant {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final bool isOwner;
  final String deleteYn;

  Participant({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.isOwner = false,
    this.deleteYn = 'N',
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      isOwner: json['isOwner'] ?? false,
      deleteYn: json['deleteYn'] ?? 'N',
    );
  }

  bool get isActive => deleteYn == 'N';

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'isOwner': isOwner,
    };
  }
}
