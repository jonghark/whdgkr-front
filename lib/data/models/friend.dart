class Friend {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String friendId;  // 친구의 로그인 ID
  final DateTime createdAt;

  Friend({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.friendId,
    required this.createdAt,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      friendId: json['friendId'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'friendId': friendId,
    };
  }
}
