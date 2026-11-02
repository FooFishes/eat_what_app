import 'package:dio/dio.dart';
import 'package:eat/core/network/idempotency.dart';
import 'package:eat/data/push/push_api.dart';
import 'package:eat/domain/models/push.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_repository.g.dart';

/// 一个推送栏目的开关和版本信息. 切换开关时把版本信息原样传给仓库.
class const PushSetting({
  required final PushCategory category,
  required final bool enabled,
  final int revision = 0,
  final String? closeFrontier,
});

/// 推送栏目的开关.
class PushRepository {
  PushRepository(this._api);

  final PushApi _api;

  /// 四个栏目的开关, 按 [PushCategory] 的顺序. 接口没有返回的栏目按默认开启处理.
  Future<List<PushSetting>> settings({CancelToken? cancelToken}) async {
    final byCategory = <PushCategory, PushSetting>{};
    for (final dto in await _api.settings(cancelToken: cancelToken)) {
      final category = PushCategory.fromApi(dto.category);
      if (category == null) continue;
      byCategory[category] = PushSetting(
        category: category,
        enabled: dto.enabled ?? true,
        revision: dto.revision ?? 0,
        closeFrontier: dto.closeFrontier,
      );
    }
    return [
      for (final category in PushCategory.values)
        byCategory[category] ?? PushSetting(category: category, enabled: true),
    ];
  }

  Future<void> set(PushSetting current, {required bool enabled}) => _api.set(
    commandId: newIdempotencyKey(),
    category: current.category.api,
    enabled: enabled,
    revision: current.revision,
    closeFrontier: current.closeFrontier,
  );
}

@Riverpod(keepAlive: true)
PushRepository pushRepository(Ref ref) =>
    PushRepository(ref.watch(pushApiProvider));
