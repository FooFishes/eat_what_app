import 'package:dio/dio.dart';
import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/data/recommend/preference_repository.dart';
import 'package:eat/domain/models/recommend_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'preferences_providers.g.dart';

/// 推荐偏好页的数据: 服务端保存的偏好 [saved] 和可选值 [options].
class const PreferencesData({
  required final RecommendPreferences saved,
  required final RecommendOptions options,
});

/// 当前账号的推荐偏好. 保存和清空失败时抛出 `AppFailure`, 成功后同步更新本状态.
@riverpod
class RecommendPreferencesSetting extends _$RecommendPreferencesSetting {
  @override
  Future<PreferencesData> build() async {
    final repo = ref.watch(preferenceRepositoryProvider);
    final token = ref.cancelToken();
    final options = _options(repo, token);
    final saved = await repo.preferences(cancelToken: token);
    return PreferencesData(saved: saved, options: await options);
  }

  /// 可选值取不到或某一项为空时改用客户端枚举, 不让这一项挡住整页.
  static Future<RecommendOptions> _options(
    PreferenceRepository repo,
    CancelToken token,
  ) async {
    final fallback = RecommendOptions.fallback;
    try {
      final o = await repo.options(cancelToken: token);
      return RecommendOptions(
        categories: o.categories.isEmpty ? fallback.categories : o.categories,
        tastes: o.tastes.isEmpty ? fallback.tastes : o.tastes,
        dislikable: o.dislikable.isEmpty ? fallback.dislikable : o.dislikable,
      );
    } on Object {
      return fallback;
    }
  }

  Future<void> save(RecommendPreferences next) async {
    final saved = await ref.read(preferenceRepositoryProvider).save(next);
    _update(saved);
  }

  Future<void> clear() async {
    await ref.read(preferenceRepositoryProvider).clear();
    _update(const RecommendPreferences());
  }

  /// 忌口的口味不会被推断为喜欢, 因此偏好变化后隐式口味需要重新获取.
  void _update(RecommendPreferences saved) {
    if (!ref.mounted) return;
    final options = state.value?.options ?? RecommendOptions.fallback;
    state = AsyncData(PreferencesData(saved: saved, options: options));
    ref.invalidate(tasteProfileProvider);
  }
}

/// 服务端从点赞, 收藏和评价里推断出的偏爱口味和品类.
@riverpod
Future<TasteProfile> tasteProfile(Ref ref) => ref
    .watch(preferenceRepositoryProvider)
    .taste(cancelToken: ref.cancelToken());
