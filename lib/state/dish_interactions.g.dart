// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dish_interactions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 赞和收藏的本地覆盖值，按菜 id（技术架构 4.3 乐观更新）。
///
/// 点了先改这里，转盘、方块、详情里同一道菜一起变；请求失败退回原值，由页面给一句提示。
/// 拉到这道菜的最新详情时清掉覆盖值，换了账号全部清空。

@ProviderFor(DishInteractions)
final dishInteractionsProvider = DishInteractionsProvider._();

/// 赞和收藏的本地覆盖值，按菜 id（技术架构 4.3 乐观更新）。
///
/// 点了先改这里，转盘、方块、详情里同一道菜一起变；请求失败退回原值，由页面给一句提示。
/// 拉到这道菜的最新详情时清掉覆盖值，换了账号全部清空。
final class DishInteractionsProvider
    extends $NotifierProvider<DishInteractions, Map<int, DishInteraction>> {
  /// 赞和收藏的本地覆盖值，按菜 id（技术架构 4.3 乐观更新）。
  ///
  /// 点了先改这里，转盘、方块、详情里同一道菜一起变；请求失败退回原值，由页面给一句提示。
  /// 拉到这道菜的最新详情时清掉覆盖值，换了账号全部清空。
  DishInteractionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dishInteractionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dishInteractionsHash();

  @$internal
  @override
  DishInteractions create() => DishInteractions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<int, DishInteraction> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<int, DishInteraction>>(value),
    );
  }
}

String _$dishInteractionsHash() => r'514954e436a7ac2b13f25c105a24ac7cb574d80f';

/// 赞和收藏的本地覆盖值，按菜 id（技术架构 4.3 乐观更新）。
///
/// 点了先改这里，转盘、方块、详情里同一道菜一起变；请求失败退回原值，由页面给一句提示。
/// 拉到这道菜的最新详情时清掉覆盖值，换了账号全部清空。

abstract class _$DishInteractions extends $Notifier<Map<int, DishInteraction>> {
  Map<int, DishInteraction> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<Map<int, DishInteraction>, Map<int, DishInteraction>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<int, DishInteraction>, Map<int, DishInteraction>>,
              Map<int, DishInteraction>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
