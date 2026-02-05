import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String userName,
    required String avatar,
    required String email,
    required String phone,
    required bool verified,
    required String method,
    required String studentId,
    required String realName,
    required String verifiedEmail,
    required int createdAt,
    required int updatedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
