import 'package:dio/dio.dart';
import 'package:eat/data/push/push_api.dart';
import 'package:eat/domain/models/push.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_repository.g.dart';

/// 单个推送栏目的开关配置.
class const PushSetting({
  required final PushCategory category,
  required final bool enabled,
});

/// 推送设置仓库, 管理各推送栏目的开关状态.
class PushRepository {
  PushRepository(this._api);

  final PushApi _api;

  /// 获取四个推送栏目的开关状态 (按 [PushCategory] 顺序排列), 接口未返回的栏目默认视为开启.
  Future<List<PushSetting>> settings({CancelToken? cancelToken}) async =>
      _settings(await _api.settings(cancelToken: cancelToken));

  /// 切换栏目 [category] 的开关状态, 并返回更新后的全部栏目开关.
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
