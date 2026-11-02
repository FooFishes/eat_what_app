import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/common/convert.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_api.g.dart';

// TODO: 未接入推送 SDK, 设备登记接口未对接, 服务端无法向本机推送. 接入推送 SDK 后对接设备登记接口.
/// 接口分组 Push: 各推送栏目的开关.
class PushApi {
  PushApi(this._client);

  final ApiClient _client;

  static const endpoints = [
    'GET /push/settings',
    'POST /push/settings/enable',
    'POST /push/settings/disable',
  ];

  Future<List<PushSettingDto>> settings({CancelToken? cancelToken}) async =>
      decodeList(
        await _client.get('/push/settings', cancelToken: cancelToken),
        PushSettingDto.fromJson,
      );

  /// 开关一个栏目. 开启时需回传读取到的 [revision] 和最近一次关闭的 [closeFrontier].
  ///
  /// 请求体只能有接口列出的字段, 多余的字段会被拒绝.
  Future<void> set({
    required String commandId,
    required String category,
    required bool enabled,
    required int revision,
    String? closeFrontier,
  }) => _client.post(
    enabled ? '/push/settings/enable' : '/push/settings/disable',
    body: {
      'commandId': commandId,
      'operation': enabled ? 'ENABLE' : 'DISABLE',
      'category': category,
      'expectedPreferenceRevision': revision,
      if (enabled) 'observedCloseFrontier': ?closeFrontier,
    },
  );
}

/// 一个推送栏目的开关. [revision] 和 [closeFrontier] 是开启时要原样回传的版本信息.
@JsonSerializable(createToJson: false)
class const PushSettingDto({
  final String? category,
  final bool? enabled,
  final int? revision,
  final String? closeFrontier,
}) {
  factory PushSettingDto.fromJson(Map<String, dynamic> json) =>
      _$PushSettingDtoFromJson(json);
}

@Riverpod(keepAlive: true)
PushApi pushApi(Ref ref) => PushApi(ref.watch(apiClientProvider));
