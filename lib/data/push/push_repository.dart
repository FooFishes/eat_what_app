import 'package:dio/dio.dart';
import 'package:eat/data/push/push_api.dart';
import 'package:eat/domain/models/push.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_repository.g.dart';

/// 一个推送栏目的开关.
class const PushSetting({
  required final PushCategory category,
  required final bool enabled,
});

/// 推送栏目的开关.
class PushRepository {
  PushRepository(this._api);

  final PushApi _api;

  /// 四个栏目的开关, 按 [PushCategory] 的顺序. 接口没有返回的栏目按默认开启处理.
  Future<List<PushSetting>> settings({CancelToken? cancelToken}) async =>
      _settings(await _api.settings(cancelToken: cancelToken));

  /// 开关栏目 [category], 返回修改后的全部开关.
  Future<List<PushSetting>> set(
    PushCategory category, {
    required bool enabled,
  }) async =>
      _settings(await _api.set(category: category.api, enabled: enabled));

  static List<PushSetting> _settings(PushSettingsDto dto) => [
    for (final category in PushCategory.values)
      PushSetting(
        category: category,
        enabled: dto.categories?[category.api] ?? true,
      ),
  ];
}

@Riverpod(keepAlive: true)
PushRepository pushRepository(Ref ref) =>
    PushRepository(ref.watch(pushApiProvider));
