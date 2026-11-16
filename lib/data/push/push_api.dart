import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_api.g.dart';

// TODO: 未接入推送 SDK, 未对接设备登记接口 `/push/bindings`, 服务端无法向本机推送. 接入推送 SDK 后对接设备登记接口.
/// PushApi 调用的接口路径, 相对于业务接口地址.
abstract final class PushEndpoints {
  static const enable = '/push/settings/enable';
  static const disable = '/push/settings/disable';
  static const settings = '/push/settings';
}

/// 推送设置接口 (`Push` 分组), 用于查询和切换各推送栏目的开关状态.
class PushApi {
  PushApi(this._client);

  final ApiClient _client;

  Future<PushSettingsDto> settings({CancelToken? cancelToken}) async =>
      decodeJson(
        await _client.get(PushEndpoints.settings, cancelToken: cancelToken),
        PushSettingsDto.fromJson,
      );

  /// 切换指定推送栏目的开关状态, 并返回更新后的全部栏目开关.
  Future<PushSettingsDto> set({
    required String category,
    required bool enabled,
  }) async => decodeJson(
    await _client.post(
      enabled ? PushEndpoints.enable : PushEndpoints.disable,
      body: {'category': category},
    ),
    PushSettingsDto.fromJson,
  );
}

/// 推送开关配置 (`PushDtos.Settings`); [categories] 以栏目接口取值为键, 各栏目默认均为 true.
@JsonSerializable(createToJson: false)
class const PushSettingsDto({final Map<String, bool>? categories}) {
  factory PushSettingsDto.fromJson(Map<String, dynamic> json) =>
      _$PushSettingsDtoFromJson(json);
}

@Riverpod(keepAlive: true)
PushApi pushApi(Ref ref) => PushApi(ref.watch(apiClientProvider));
