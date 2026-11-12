// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discover_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 发现页的转盘队列: 推荐的美食店. 地点, 饭点或场景变化时重新请求.
///
/// 抽屉的分类栏不影响转盘, 转盘总是推荐美食 ([ShopKind.food]).

@ProviderFor(TurntableQueue)
final turntableQueueProvider = TurntableQueueProvider._();

/// 发现页的转盘队列: 推荐的美食店. 地点, 饭点或场景变化时重新请求.
///
/// 抽屉的分类栏不影响转盘, 转盘总是推荐美食 ([ShopKind.food]).
final class TurntableQueueProvider
    extends $AsyncNotifierProvider<TurntableQueue, TurntableFeed> {
  /// 发现页的转盘队列: 推荐的美食店. 地点, 饭点或场景变化时重新请求.
  ///
  /// 抽屉的分类栏不影响转盘, 转盘总是推荐美食 ([ShopKind.food]).
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

String _$turntableQueueHash() => r'951c403f84bb5cffe4f95694c5add52924c4012b';

/// 发现页的转盘队列: 推荐的美食店. 地点, 饭点或场景变化时重新请求.
///
/// 抽屉的分类栏不影响转盘, 转盘总是推荐美食 ([ShopKind.food]).

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
