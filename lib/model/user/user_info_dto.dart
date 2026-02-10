import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_info_dto.freezed.dart';
part 'user_info_dto.g.dart';

@freezed
abstract class UserInfoDto with _$UserInfoDto {
  const factory UserInfoDto({
    required int id,
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
  }) = _UserInfoDto;

  factory UserInfoDto.fromJson(Map<String, dynamic> json) =>
      _$UserInfoDtoFromJson(json);
}
