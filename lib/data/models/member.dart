class Member {
  final int memberId;
  final String loginId;
  final String name;
  final String email;

  Member({
    required this.memberId,
    required this.loginId,
    required this.name,
    required this.email,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      memberId: json['memberId'] as int,
      loginId: json['loginId'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }
}

class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final Member member;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.member,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      member: Member.fromJson(json['member'] as Map<String, dynamic>),
    );
  }
}

class TokenResponse {
  final String accessToken;
  final String refreshToken;

  TokenResponse({
    required this.accessToken,
    required this.refreshToken,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
}
