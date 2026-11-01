import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_api.g.dart';

// TODO: 未对接编辑资料, 关注和隐私设置的接口. 实现对应页面时在此添加接口方法.
/// 接口分组 User: 当前用户, 指定用户的公开资料和统计.
class UserApi {
  UserApi(this._client);

  final ApiClient _client;

  static const endpoints = ['GET /user/info', 'GET /user/userInfo'];

  Future<UserInfoDto> info() async =>
      decodeJson(await _client.get('/user/info'), UserInfoDto.fromJson);

  Future<UserProfileDto> profile(
    int userId, {
    CancelToken? cancelToken,
  }) async => decodeJson(
    await _client.get(
      '/user/userInfo',
      query: {'userId': userId},
      cancelToken: cancelToken,
    ),
    UserProfileDto.fromJson,
  );
}

/// `/user/userInfo` 的 `data`: 指定用户的公开资料, 统计, 以及与当前用户的关注关系.
@JsonSerializable(createToJson: false)
class const UserProfileDto({
  final String? displayName,
  final String? avatar,
  final int? earnedLikes,
  final int? fansCount,
  final int? followingsCount,
  final bool? fansVisible,
  final bool? followingsVisible,
  final bool? isFollowingMe,
  final bool? isFollowingHim,
  final int? uploadedFoodsCount,
}) {
  factory UserProfileDto.fromJson(Map<String, dynamic> json) =>
      _$UserProfileDtoFromJson(json);
}

/// `/user/info` 的 `data`. 字段按接口声明均为可空, 转换为领域模型时补默认值.
///
/// 该 DTO 原样存入本地缓存, 启动时先用缓存显示, 因此需要支持转回 JSON.
/// 产品不收集性别, 生日和家乡, 因此不读取这些字段.
@JsonSerializable(includeIfNull: false)
class const UserInfoDto({
  final int? id,
  final String? displayName,
  final String? userName,
  final bool? hasUsername,
  final String? avatar,
  final bool? banned,
  final String? banReason,
  final int? bannedAt,
  final String? phone,
  final bool? verified,
  final String? method,
  final String? verifiedEmail,
  final bool? hasPassword,
  final String? signature,
}) {
  factory UserInfoDto.fromJson(Map<String, dynamic> json) =>
      _$UserInfoDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserInfoDtoToJson(this);
}

@Riverpod(keepAlive: true)
UserApi userApi(Ref ref) => UserApi(ref.watch(apiClientProvider));
