import 'package:eat/core/network/api_client.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_api.g.dart';

/// 接口分组 User：当前用户。资料、关注、隐私在后面的阶段加。
class UserApi {
  UserApi(this._client);

  final ApiClient _client;

  static const endpoints = ['GET /user/info'];

  Future<UserInfoDto> info() async =>
      decodeJson(await _client.get('/user/info'), UserInfoDto.fromJson);
}

/// `/user/info` 的 `data`。字段照接口写成可空，转领域模型时补默认值。
///
/// 也原样存进本地缓存，启动时先用它显示（技术架构 10.1），所以要能转回 JSON。性别、生日、家乡
/// 产品上不收集（产品 7.6），这里不读。
@JsonSerializable(includeIfNull: false)
class const UserInfoDto({
  final int? id,
  final String? userName,
  final String? loginUsername,
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
