import 'package:eat/core/network/api_client.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'remote_config_api.g.dart';

/// RemoteConfigApi 调用的接口路径, 相对于业务接口地址.
abstract final class RemoteConfigEndpoints {
  static const config = '/remote-config';
}

/// 远程配置接口 (`RemoteConfig` 分组). 游客可访问, 响应带 `ETag` 和 60 秒公共缓存.
class RemoteConfigApi {
  RemoteConfigApi(this._client);

  final ApiClient _client;

  /// 请求客户端配置. [platform], [build] 和 [campusId] 用于服务端筛选公告, [etag] 为上次响应的 `ETag`.
  Future<ConditionalData> fetch({
    String? platform,
    int? build,
    int? campusId,
    String? etag,
  }) => _client.getConditional(
    RemoteConfigEndpoints.config,
    query: {'platform': ?platform, 'build': ?build, 'campusId': ?campusId},
    etag: etag,
  );
}

/// 功能开关 (`RemoteConfigDtos.Flag`).
@JsonSerializable(createToJson: false)
class const FlagDto({final bool? on, final String? reason}) {
  factory FlagDto.fromJson(Map<String, dynamic> json) =>
      _$FlagDtoFromJson(json);
}

/// 维护状态 (`RemoteConfigDtos.Maintenance`). [mode] 为 `NONE`, `READ_ONLY` 或 `DOWN`, [until] 为毫秒时间戳.
@JsonSerializable(createToJson: false)
class const MaintenanceDto({
  final String? mode,
  final String? message,
  final int? until,
}) {
  factory MaintenanceDto.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceDtoFromJson(json);
}

/// 公告 (`RemoteConfigDtos.Announcement`). [level] 为 `NORMAL` 或 `IMPORTANT`, 时间为毫秒时间戳.
@JsonSerializable(createToJson: false)
class const AnnouncementDto({
  required final int id,
  final String? level,
  final String? title,
  final String? content,
  final String? linkUrl,
  final int? startsAt,
  final int? endsAt,
}) {
  factory AnnouncementDto.fromJson(Map<String, dynamic> json) =>
      _$AnnouncementDtoFromJson(json);
}

/// 单个平台的版本线 (`RemoteConfigDtos.Version`), 构建号为 0 表示未设置.
@JsonSerializable(createToJson: false)
class const VersionDto({
  final int? minBuild,
  final int? latestBuild,
  final String? latestVersionName,
  final String? storeUrl,
  final String? releaseNotes,
}) {
  factory VersionDto.fromJson(Map<String, dynamic> json) =>
      _$VersionDtoFromJson(json);
}

@Riverpod(keepAlive: true)
RemoteConfigApi remoteConfigApi(Ref ref) =>
    RemoteConfigApi(ref.watch(apiClientProvider));
