// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discover_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 发现页转盘队列状态, 当地点, 饭点或场景变化时重新请求推荐美食店.
///
/// 抽屉分类切换不影响转盘, 转盘固定推荐美食 ([ShopKind.food]).

@ProviderFor(TurntableQueue)
final turntableQueueProvider = TurntableQueueProvider._();

/// 发现页转盘队列状态, 当地点, 饭点或场景变化时重新请求推荐美食店.
///
/// 抽屉分类切换不影响转盘, 转盘固定推荐美食 ([ShopKind.food]).
final class TurntableQueueProvider
    extends $AsyncNotifierProvider<TurntableQueue, TurntableFeed> {
  /// 发现页转盘队列状态, 当地点, 饭点或场景变化时重新请求推荐美食店.
  ///
  /// 抽屉分类切换不影响转盘, 转盘固定推荐美食 ([ShopKind.food]).
  TurntableQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'turntableQueueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$turntableQueueHash();

  @$internal
  @override
  TurntableQueue create() => TurntableQueue();
}

String _$turntableQueueHash() => r'273a649a510dc6f2da4a90c037d4646905307968';

/// 发现页转盘队列状态, 当地点, 饭点或场景变化时重新请求推荐美食店.
///
/// 抽屉分类切换不影响转盘, 转盘固定推荐美食 ([ShopKind.food]).

abstract class _$TurntableQueue extends $AsyncNotifier<TurntableFeed> {
  FutureOr<TurntableFeed> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<TurntableFeed>, TurntableFeed>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TurntableFeed>, TurntableFeed>,
              AsyncValue<TurntableFeed>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 抽屉里 [kind] 一栏的推荐店铺. 地点, 饭点或场景变化时重新请求.
///
/// 登录用户的推荐按天去重, 与转盘共用去重记录. "美食" 一栏因此列出转盘之外的更多推荐.

@ProviderFor(DiscoverShops)
final discoverShopsProvider = DiscoverShopsFamily._();

/// 抽屉里 [kind] 一栏的推荐店铺. 地点, 饭点或场景变化时重新请求.
///
/// 登录用户的推荐按天去重, 与转盘共用去重记录. "美食" 一栏因此列出转盘之外的更多推荐.
final class DiscoverShopsProvider
    extends $AsyncNotifierProvider<DiscoverShops, ShopFeed> {
  /// 抽屉里 [kind] 一栏的推荐店铺. 地点, 饭点或场景变化时重新请求.
  ///
  /// 登录用户的推荐按天去重, 与转盘共用去重记录. "美食" 一栏因此列出转盘之外的更多推荐.
  DiscoverShopsProvider._({
    required DiscoverShopsFamily super.from,
    required ShopKind super.argument,
  }) : super(
         retry: null,
         name: r'discoverShopsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$discoverShopsHash();

  @override
  String toString() {
    return r'discoverShopsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DiscoverShops create() => DiscoverShops();

  @override
  bool operator ==(Object other) {
    return other is DiscoverShopsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$discoverShopsHash() => r'64d135358a884adb66f11669f4a1dc7efce7e86c';

/// 抽屉里 [kind] 一栏的推荐店铺. 地点, 饭点或场景变化时重新请求.
///
/// 登录用户的推荐按天去重, 与转盘共用去重记录. "美食" 一栏因此列出转盘之外的更多推荐.

final class DiscoverShopsFamily extends $Family
    with
        $ClassFamilyOverride<
          DiscoverShops,
          AsyncValue<ShopFeed>,
          ShopFeed,
          FutureOr<ShopFeed>,
          ShopKind
        > {
  DiscoverShopsFamily._()
    : super(
        retry: null,
        name: r'discoverShopsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 抽屉里 [kind] 一栏的推荐店铺. 地点, 饭点或场景变化时重新请求.
  ///
  /// 登录用户的推荐按天去重, 与转盘共用去重记录. "美食" 一栏因此列出转盘之外的更多推荐.

  DiscoverShopsProvider call(ShopKind kind) =>
      DiscoverShopsProvider._(argument: kind, from: this);

  @override
  String toString() => r'discoverShopsProvider';
}

/// 抽屉里 [kind] 一栏的推荐店铺. 地点, 饭点或场景变化时重新请求.
///
/// 登录用户的推荐按天去重, 与转盘共用去重记录. "美食" 一栏因此列出转盘之外的更多推荐.

abstract class _$DiscoverShops extends $AsyncNotifier<ShopFeed> {
  late final _$args = ref.$arg as ShopKind;
  ShopKind get kind => _$args;

  FutureOr<ShopFeed> build(ShopKind kind);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ShopFeed>, ShopFeed>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ShopFeed>, ShopFeed>,
              AsyncValue<ShopFeed>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// 抽屉里 [kind] 一栏按 [order] 排的店, 走逛店接口, 向下滚动时按页追加. 地点或场景变化时重新请求.
///
/// - 查询位置和推荐一样 (见 [_near]); 推荐率按顶栏的场景排.
/// - 顶栏选了外卖时只列能点外卖的店.
/// - 抽屉不列已关门的店, 在客户端去掉; 一页全是已关门的店时接着取下一页.

@ProviderFor(SortedShops)
final sortedShopsProvider = SortedShopsFamily._();

/// 抽屉里 [kind] 一栏按 [order] 排的店, 走逛店接口, 向下滚动时按页追加. 地点或场景变化时重新请求.
///
/// - 查询位置和推荐一样 (见 [_near]); 推荐率按顶栏的场景排.
/// - 顶栏选了外卖时只列能点外卖的店.
/// - 抽屉不列已关门的店, 在客户端去掉; 一页全是已关门的店时接着取下一页.
final class SortedShopsProvider
    extends $AsyncNotifierProvider<SortedShops, ShopFeed> {
  /// 抽屉里 [kind] 一栏按 [order] 排的店, 走逛店接口, 向下滚动时按页追加. 地点或场景变化时重新请求.
  ///
  /// - 查询位置和推荐一样 (见 [_near]); 推荐率按顶栏的场景排.
  /// - 顶栏选了外卖时只列能点外卖的店.
  /// - 抽屉不列已关门的店, 在客户端去掉; 一页全是已关门的店时接着取下一页.
  SortedShopsProvider._({
    required SortedShopsFamily super.from,
    required (ShopKind, DiscoverOrder) super.argument,
  }) : super(
         retry: null,
         name: r'sortedShopsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sortedShopsHash();

  @override
  String toString() {
    return r'sortedShopsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  SortedShops create() => SortedShops();

  @override
  bool operator ==(Object other) {
    return other is SortedShopsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sortedShopsHash() => r'92627e2f5ed1a64ba54fee121e6acbbdf9a833bc';

/// 抽屉里 [kind] 一栏按 [order] 排的店, 走逛店接口, 向下滚动时按页追加. 地点或场景变化时重新请求.
///
/// - 查询位置和推荐一样 (见 [_near]); 推荐率按顶栏的场景排.
/// - 顶栏选了外卖时只列能点外卖的店.
/// - 抽屉不列已关门的店, 在客户端去掉; 一页全是已关门的店时接着取下一页.

final class SortedShopsFamily extends $Family
    with
        $ClassFamilyOverride<
          SortedShops,
          AsyncValue<ShopFeed>,
          ShopFeed,
          FutureOr<ShopFeed>,
          (ShopKind, DiscoverOrder)
        > {
  SortedShopsFamily._()
    : super(
        retry: null,
        name: r'sortedShopsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 抽屉里 [kind] 一栏按 [order] 排的店, 走逛店接口, 向下滚动时按页追加. 地点或场景变化时重新请求.
  ///
  /// - 查询位置和推荐一样 (见 [_near]); 推荐率按顶栏的场景排.
  /// - 顶栏选了外卖时只列能点外卖的店.
  /// - 抽屉不列已关门的店, 在客户端去掉; 一页全是已关门的店时接着取下一页.

  SortedShopsProvider call(ShopKind kind, DiscoverOrder order) =>
      SortedShopsProvider._(argument: (kind, order), from: this);

  @override
  String toString() => r'sortedShopsProvider';
}

/// 抽屉里 [kind] 一栏按 [order] 排的店, 走逛店接口, 向下滚动时按页追加. 地点或场景变化时重新请求.
///
/// - 查询位置和推荐一样 (见 [_near]); 推荐率按顶栏的场景排.
/// - 顶栏选了外卖时只列能点外卖的店.
/// - 抽屉不列已关门的店, 在客户端去掉; 一页全是已关门的店时接着取下一页.

abstract class _$SortedShops extends $AsyncNotifier<ShopFeed> {
  late final _$args = ref.$arg as (ShopKind, DiscoverOrder);
  ShopKind get kind => _$args.$1;
  DiscoverOrder get order => _$args.$2;

  FutureOr<ShopFeed> build(ShopKind kind, DiscoverOrder order);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ShopFeed>, ShopFeed>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ShopFeed>, ShopFeed>,
              AsyncValue<ShopFeed>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
