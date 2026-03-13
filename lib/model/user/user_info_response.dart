class UserInfoResponse {
  final int id;
  final String userName;
  final String avatar;
  final String email;
  final String phone;
  final bool verified;
  final String method;
  final String studentId;
  final String realName;
  final String verifiedEmail;
  final int createdAt;
  final int updatedAt;

  const UserInfoResponse({
    required this.id,
    required this.userName,
    required this.avatar,
    required this.email,
    required this.phone,
    required this.verified,
    required this.method,
    required this.studentId,
    required this.realName,
    required this.verifiedEmail,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserInfoResponse.fromJson(Map<String, dynamic> json) {
    return UserInfoResponse(
      id: (json['id'] as num).toInt(),
      userName: json['userName'] as String,
      avatar: json['avatar'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      verified: json['verified'] as bool,
      method: json['method'] as String,
      studentId: json['studentId'] as String,
      realName: json['realName'] as String,
      verifiedEmail: json['verifiedEmail'] as String,
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'avatar': avatar,
      'email': email,
      'phone': phone,
      'verified': verified,
      'method': method,
      'studentId': studentId,
      'realName': realName,
      'verifiedEmail': verifiedEmail,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
