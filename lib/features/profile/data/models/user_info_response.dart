class const UserInfoResponse({
  required final int id,
  required final String userName,
  final String? avatar,
  final String? email,
  final String? phone,
  required final bool verified,
  required final String method,
  required final String studentId,
  required final String realName,
  final String? verifiedEmail,
  required final int createdAt,
  required final int updatedAt,
  final String? banReason,
  final bool? banned,
  final int? bannedAt,
  final String? role,
  final String? gender,
  final String? birthday,
  final String? signature,
  final int? hometownProvinceId,
  final int? hometownCityId,
  final String? hometownProvinceName,
  final String? hometownCityName,
}) {
  factory fromJson(Map<String, dynamic> json) {
    return UserInfoResponse(
      id: (json['id'] as num).toInt(),
      userName: json['userName'] as String,
      avatar: json['avatar'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      verified: json['verified'] as bool,
      method: json['method'] as String,
      studentId: json['studentId'] as String,
      realName: json['realName'] as String,
      verifiedEmail: json['verifiedEmail'] as String?,
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
      banReason: json['banReason'] as String?,
      banned: json['banned'] as bool?,
      bannedAt: json['bannedAt'] != null
          ? (json['bannedAt'] as num).toInt()
          : null,
      role: json['role'] as String?,
      gender: json['gender'] as String?,
      birthday: json['birthday'] as String?,
      signature: json['signature'] as String?,
      hometownProvinceId: json['hometownProvinceId'] != null
          ? (json['hometownProvinceId'] as num).toInt()
          : null,
      hometownCityId: json['hometownCityId'] != null
          ? (json['hometownCityId'] as num).toInt()
          : null,
      hometownProvinceName: json['hometownProvinceName'] as String?,
      hometownCityName: json['hometownCityName'] as String?,
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
      'banReason': banReason,
      'banned': banned,
      'bannedAt': bannedAt,
      'role': role,
      'gender': gender,
      'birthday': birthday,
      'signature': signature,
      'hometownProvinceId': hometownProvinceId,
      'hometownCityId': hometownCityId,
      'hometownProvinceName': hometownProvinceName,
      'hometownCityName': hometownCityName,
    };
  }

  @override
  String toString() {
    return 'UserInfoResponse(id: $id, userName: $userName, avatar: $avatar, email: $email, phone: $phone, verified: $verified, method: $method, studentId: $studentId, realName: $realName, verifiedEmail: $verifiedEmail, createdAt: $createdAt, updatedAt: $updatedAt, banReason: $banReason, banned: $banned, bannedAt: $bannedAt, role: $role, gender: $gender, birthday: $birthday, signature: $signature, hometownProvinceId: $hometownProvinceId, hometownCityId: $hometownCityId, hometownProvinceName: $hometownProvinceName, hometownCityName: $hometownCityName)';
  }
}
