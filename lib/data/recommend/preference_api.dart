import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/recommend/preference_dto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'preference_api.g.dart';

/// PreferenceApi 调用的接口路径, 相对于业务接口地址.
abstract final class PreferenceEndpoints {
  static const preferences = '/user/recommendation-profile/preferences';
  static const taste = '/user/recommendation-profile/taste';
  static const options = '/recommend/tags';
}

/// 推荐偏好接口 (`Preference`, `Taste` 分组) 和偏好的可选值 (`Recommend` 分组的 `/recommend/tags`).
///
/// 偏好和隐式口味需登录, 可选值游客也能获取.
class PreferenceApi {
  PreferenceApi(this._client);

  final ApiClient _client;

  Future<PreferencesDto> preferences({CancelToken? cancelToken}) async =>
      decodeJson(
        await _client.get(
          PreferenceEndpoints.preferences,
          cancelToken: cancelToken,
        ),
        PreferencesDto.fromJson,
      );

  /// 整体覆盖推荐偏好并返回保存后的结果. 每人每天最多修改 50 次.
  Future<PreferencesDto> save(PreferencesRequestDto request) async =>
      decodeJson(
        await _client.put(
          PreferenceEndpoints.preferences,
          body: request.toJson(),
        ),
        PreferencesDto.fromJson,
      );

  Future<void> clear() => _client.delete(PreferenceEndpoints.preferences);

  Future<TasteDto> taste({CancelToken? cancelToken}) async => decodeJson(
    await _client.get(PreferenceEndpoints.taste, cancelToken: cancelToken),
    TasteDto.fromJson,
  );

  Future<RecommendOptionsDto> options({CancelToken? cancelToken}) async =>
      decodeJson(
        await _client.get(
          PreferenceEndpoints.options,
          cancelToken: cancelToken,
        ),
        RecommendOptionsDto.fromJson,
      );
}

@Riverpod(keepAlive: true)
PreferenceApi preferenceApi(Ref ref) =>
    PreferenceApi(ref.watch(apiClientProvider));
