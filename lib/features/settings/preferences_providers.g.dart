// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preferences_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 当前账号的推荐偏好. 保存和清空失败时抛出 `AppFailure`, 成功后同步更新本状态.

@ProviderFor(RecommendPreferencesSetting)
final recommendPreferencesSettingProvider =
    RecommendPreferencesSettingProvider._();

/// 当前账号的推荐偏好. 保存和清空失败时抛出 `AppFailure`, 成功后同步更新本状态.
final class RecommendPreferencesSettingProvider
    extends
        $AsyncNotifierProvider<RecommendPreferencesSetting, PreferencesData> {
  /// 当前账号的推荐偏好. 保存和清空失败时抛出 `AppFailure`, 成功后同步更新本状态.
  RecommendPreferencesSettingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recommendPreferencesSettingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recommendPreferencesSettingHash();

  @$internal
  @override
  RecommendPreferencesSetting create() => RecommendPreferencesSetting();
}

String _$recommendPreferencesSettingHash() =>
    r'a6eabdf7a44c2561c076f79493e671efd16abc84';

/// 当前账号的推荐偏好. 保存和清空失败时抛出 `AppFailure`, 成功后同步更新本状态.

abstract class _$RecommendPreferencesSetting
    extends $AsyncNotifier<PreferencesData> {
  FutureOr<PreferencesData> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PreferencesData>, PreferencesData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PreferencesData>, PreferencesData>,
              AsyncValue<PreferencesData>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 服务端从点赞, 收藏和评价里推断出的偏爱口味和品类.

@ProviderFor(tasteProfile)
final tasteProfileProvider = TasteProfileProvider._();

/// 服务端从点赞, 收藏和评价里推断出的偏爱口味和品类.

final class TasteProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<TasteProfile>,
          TasteProfile,
          FutureOr<TasteProfile>
        >
    with $FutureModifier<TasteProfile>, $FutureProvider<TasteProfile> {
  /// 服务端从点赞, 收藏和评价里推断出的偏爱口味和品类.
  TasteProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tasteProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tasteProfileHash();

  @$internal
  @override
  $FutureProviderElement<TasteProfile> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TasteProfile> create(Ref ref) {
    return tasteProfile(ref);
  }
}

String _$tasteProfileHash() => r'811048a45fb82efe2d500962e24e5ba801181b6d';
