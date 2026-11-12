// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 一家店的全部菜品, 按菜单顺序分页: 招牌菜在前, 然后按分类, 同一分类按赞数.
///
/// [LoadedPages.pages] 的 `total` 是这家店的菜数. 发布新菜后重新请求. 离开页面后保留 5 分钟.

@ProviderFor(ShopMenu)
final shopMenuProvider = ShopMenuFamily._();

/// 一家店的全部菜品, 按菜单顺序分页: 招牌菜在前, 然后按分类, 同一分类按赞数.
///
/// [LoadedPages.pages] 的 `total` 是这家店的菜数. 发布新菜后重新请求. 离开页面后保留 5 分钟.
final class ShopMenuProvider
    extends $AsyncNotifierProvider<ShopMenu, LoadedPages<Dish>> {
  /// 一家店的全部菜品, 按菜单顺序分页: 招牌菜在前, 然后按分类, 同一分类按赞数.
  ///
  /// [LoadedPages.pages] 的 `total` 是这家店的菜数. 发布新菜后重新请求. 离开页面后保留 5 分钟.
  ShopMenuProvider._({
    required ShopMenuFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'shopMenuProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$shopMenuHash();

  @override
  String toString() {
    return r'shopMenuProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ShopMenu create() => ShopMenu();

  @override
  bool operator ==(Object other) {
    return other is ShopMenuProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shopMenuHash() => r'80d4f980ef85ce9eb1716597526739b1ae276bfb';

/// 一家店的全部菜品, 按菜单顺序分页: 招牌菜在前, 然后按分类, 同一分类按赞数.
///
/// [LoadedPages.pages] 的 `total` 是这家店的菜数. 发布新菜后重新请求. 离开页面后保留 5 分钟.

final class ShopMenuFamily extends $Family
    with
        $ClassFamilyOverride<
          ShopMenu,
          AsyncValue<LoadedPages<Dish>>,
          LoadedPages<Dish>,
          FutureOr<LoadedPages<Dish>>,
          int
        > {
  ShopMenuFamily._()
    : super(
        retry: null,
        name: r'shopMenuProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 一家店的全部菜品, 按菜单顺序分页: 招牌菜在前, 然后按分类, 同一分类按赞数.
  ///
  /// [LoadedPages.pages] 的 `total` 是这家店的菜数. 发布新菜后重新请求. 离开页面后保留 5 分钟.

  ShopMenuProvider call(int shopId) =>
      ShopMenuProvider._(argument: shopId, from: this);

  @override
  String toString() => r'shopMenuProvider';
}

/// 一家店的全部菜品, 按菜单顺序分页: 招牌菜在前, 然后按分类, 同一分类按赞数.
///
/// [LoadedPages.pages] 的 `total` 是这家店的菜数. 发布新菜后重新请求. 离开页面后保留 5 分钟.

abstract class _$ShopMenu extends $AsyncNotifier<LoadedPages<Dish>> {
  late final _$args = ref.$arg as int;
  int get shopId => _$args;

  FutureOr<LoadedPages<Dish>> build(int shopId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<LoadedPages<Dish>>, LoadedPages<Dish>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<LoadedPages<Dish>>, LoadedPages<Dish>>,
              AsyncValue<LoadedPages<Dish>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// 一家店的招牌菜, 至多 3 道, 按菜单顺序.
///
/// 店铺接口不返回招牌菜, 因此单独请求. 发布新菜后重新请求. 离开页面后保留 5 分钟.

@ProviderFor(shopSignatures)
final shopSignaturesProvider = ShopSignaturesFamily._();

/// 一家店的招牌菜, 至多 3 道, 按菜单顺序.
///
/// 店铺接口不返回招牌菜, 因此单独请求. 发布新菜后重新请求. 离开页面后保留 5 分钟.

final class ShopSignaturesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Dish>>,
          List<Dish>,
          FutureOr<List<Dish>>
        >
    with $FutureModifier<List<Dish>>, $FutureProvider<List<Dish>> {
  /// 一家店的招牌菜, 至多 3 道, 按菜单顺序.
  ///
  /// 店铺接口不返回招牌菜, 因此单独请求. 发布新菜后重新请求. 离开页面后保留 5 分钟.
  ShopSignaturesProvider._({
    required ShopSignaturesFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'shopSignaturesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$shopSignaturesHash();

  @override
  String toString() {
    return r'shopSignaturesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Dish>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Dish>> create(Ref ref) {
    final argument = this.argument as int;
    return shopSignatures(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ShopSignaturesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shopSignaturesHash() => r'e79ae3951387b92f67e432b706a70b9039904d0c';

/// 一家店的招牌菜, 至多 3 道, 按菜单顺序.
///
/// 店铺接口不返回招牌菜, 因此单独请求. 发布新菜后重新请求. 离开页面后保留 5 分钟.

final class ShopSignaturesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Dish>>, int> {
  ShopSignaturesFamily._()
    : super(
        retry: null,
        name: r'shopSignaturesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 一家店的招牌菜, 至多 3 道, 按菜单顺序.
  ///
  /// 店铺接口不返回招牌菜, 因此单独请求. 发布新菜后重新请求. 离开页面后保留 5 分钟.

  ShopSignaturesProvider call(int shopId) =>
      ShopSignaturesProvider._(argument: shopId, from: this);

  @override
  String toString() => r'shopSignaturesProvider';
}

/// 当前用户对一家店的评价和收藏, 点击后立即修改本地值, 请求失败时恢复.
///
/// 初值和后续更新来自店铺详情中的个人状态, 只监听其中两个字段.
/// 评价成功后店铺详情会重新请求. 若监听整个详情, 请求期间的旧数据会覆盖乐观值.

@ProviderFor(ShopMineState)
final shopMineStateProvider = ShopMineStateFamily._();

/// 当前用户对一家店的评价和收藏, 点击后立即修改本地值, 请求失败时恢复.
///
/// 初值和后续更新来自店铺详情中的个人状态, 只监听其中两个字段.
/// 评价成功后店铺详情会重新请求. 若监听整个详情, 请求期间的旧数据会覆盖乐观值.
final class ShopMineStateProvider
    extends $NotifierProvider<ShopMineState, ShopMine> {
  /// 当前用户对一家店的评价和收藏, 点击后立即修改本地值, 请求失败时恢复.
  ///
  /// 初值和后续更新来自店铺详情中的个人状态, 只监听其中两个字段.
  /// 评价成功后店铺详情会重新请求. 若监听整个详情, 请求期间的旧数据会覆盖乐观值.
  ShopMineStateProvider._({
    required ShopMineStateFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'shopMineStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$shopMineStateHash();

  @override
  String toString() {
    return r'shopMineStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ShopMineState create() => ShopMineState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShopMine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShopMine>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ShopMineStateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shopMineStateHash() => r'dc5e3ee202e9773f3fb0d14124f030b92ea240aa';

/// 当前用户对一家店的评价和收藏, 点击后立即修改本地值, 请求失败时恢复.
///
/// 初值和后续更新来自店铺详情中的个人状态, 只监听其中两个字段.
/// 评价成功后店铺详情会重新请求. 若监听整个详情, 请求期间的旧数据会覆盖乐观值.

final class ShopMineStateFamily extends $Family
    with
        $ClassFamilyOverride<ShopMineState, ShopMine, ShopMine, ShopMine, int> {
  ShopMineStateFamily._()
    : super(
        retry: null,
        name: r'shopMineStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 当前用户对一家店的评价和收藏, 点击后立即修改本地值, 请求失败时恢复.
  ///
  /// 初值和后续更新来自店铺详情中的个人状态, 只监听其中两个字段.
  /// 评价成功后店铺详情会重新请求. 若监听整个详情, 请求期间的旧数据会覆盖乐观值.

  ShopMineStateProvider call(int shopId) =>
      ShopMineStateProvider._(argument: shopId, from: this);

  @override
  String toString() => r'shopMineStateProvider';
}

/// 当前用户对一家店的评价和收藏, 点击后立即修改本地值, 请求失败时恢复.
///
/// 初值和后续更新来自店铺详情中的个人状态, 只监听其中两个字段.
/// 评价成功后店铺详情会重新请求. 若监听整个详情, 请求期间的旧数据会覆盖乐观值.

abstract class _$ShopMineState extends $Notifier<ShopMine> {
  late final _$args = ref.$arg as int;
  int get shopId => _$args;

  ShopMine build(int shopId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ShopMine, ShopMine>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ShopMine, ShopMine>,
              ShopMine,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// 一家店的修改记录, 最新的在前, 分页加载.

@ProviderFor(ShopHistory)
final shopHistoryProvider = ShopHistoryFamily._();

/// 一家店的修改记录, 最新的在前, 分页加载.
final class ShopHistoryProvider
    extends $AsyncNotifierProvider<ShopHistory, LoadedPages<ShopRevision>> {
  /// 一家店的修改记录, 最新的在前, 分页加载.
  ShopHistoryProvider._({
    required ShopHistoryFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'shopHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$shopHistoryHash();

  @override
  String toString() {
    return r'shopHistoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ShopHistory create() => ShopHistory();

  @override
  bool operator ==(Object other) {
    return other is ShopHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shopHistoryHash() => r'94bab4e095ac42be6ced1b4db355c314f89cb638';

/// 一家店的修改记录, 最新的在前, 分页加载.

final class ShopHistoryFamily extends $Family
    with
        $ClassFamilyOverride<
          ShopHistory,
          AsyncValue<LoadedPages<ShopRevision>>,
          LoadedPages<ShopRevision>,
          FutureOr<LoadedPages<ShopRevision>>,
          int
        > {
  ShopHistoryFamily._()
    : super(
        retry: null,
        name: r'shopHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 一家店的修改记录, 最新的在前, 分页加载.

  ShopHistoryProvider call(int shopId) =>
      ShopHistoryProvider._(argument: shopId, from: this);

  @override
  String toString() => r'shopHistoryProvider';
}

/// 一家店的修改记录, 最新的在前, 分页加载.

abstract class _$ShopHistory extends $AsyncNotifier<LoadedPages<ShopRevision>> {
  late final _$args = ref.$arg as int;
  int get shopId => _$args;

  FutureOr<LoadedPages<ShopRevision>> build(int shopId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<LoadedPages<ShopRevision>>,
              LoadedPages<ShopRevision>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<LoadedPages<ShopRevision>>,
                LoadedPages<ShopRevision>
              >,
              AsyncValue<LoadedPages<ShopRevision>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
