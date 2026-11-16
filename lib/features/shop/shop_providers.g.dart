// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 指定店铺的全部菜品分页列表, 按菜单顺序排序 (招牌菜优先, 其次按分类及赞数).
///
/// [LoadedPages.pages] 中的 total 即该店菜品总数. 发布新菜后会自动失效并重新请求, 离开页面后缓存保留 5 分钟.

@ProviderFor(ShopMenu)
final shopMenuProvider = ShopMenuFamily._();

/// 指定店铺的全部菜品分页列表, 按菜单顺序排序 (招牌菜优先, 其次按分类及赞数).
///
/// [LoadedPages.pages] 中的 total 即该店菜品总数. 发布新菜后会自动失效并重新请求, 离开页面后缓存保留 5 分钟.
final class ShopMenuProvider
    extends $AsyncNotifierProvider<ShopMenu, LoadedPages<Dish>> {
  /// 指定店铺的全部菜品分页列表, 按菜单顺序排序 (招牌菜优先, 其次按分类及赞数).
  ///
  /// [LoadedPages.pages] 中的 total 即该店菜品总数. 发布新菜后会自动失效并重新请求, 离开页面后缓存保留 5 分钟.
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

/// 指定店铺的全部菜品分页列表, 按菜单顺序排序 (招牌菜优先, 其次按分类及赞数).
///
/// [LoadedPages.pages] 中的 total 即该店菜品总数. 发布新菜后会自动失效并重新请求, 离开页面后缓存保留 5 分钟.

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

  /// 指定店铺的全部菜品分页列表, 按菜单顺序排序 (招牌菜优先, 其次按分类及赞数).
  ///
  /// [LoadedPages.pages] 中的 total 即该店菜品总数. 发布新菜后会自动失效并重新请求, 离开页面后缓存保留 5 分钟.

  ShopMenuProvider call(int shopId) =>
      ShopMenuProvider._(argument: shopId, from: this);

  @override
  String toString() => r'shopMenuProvider';
}

/// 指定店铺的全部菜品分页列表, 按菜单顺序排序 (招牌菜优先, 其次按分类及赞数).
///
/// [LoadedPages.pages] 中的 total 即该店菜品总数. 发布新菜后会自动失效并重新请求, 离开页面后缓存保留 5 分钟.

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

/// 获取指定店铺的招牌菜 (最多 3 道, 按菜单顺序).
///
/// 由于店铺详情接口不返回招牌菜列表, 需单独请求. 发布新菜后会失效并重新请求, 离开页面后缓存保留 5 分钟.

@ProviderFor(shopSignatures)
final shopSignaturesProvider = ShopSignaturesFamily._();

/// 获取指定店铺的招牌菜 (最多 3 道, 按菜单顺序).
///
/// 由于店铺详情接口不返回招牌菜列表, 需单独请求. 发布新菜后会失效并重新请求, 离开页面后缓存保留 5 分钟.

final class ShopSignaturesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Dish>>,
          List<Dish>,
          FutureOr<List<Dish>>
        >
    with $FutureModifier<List<Dish>>, $FutureProvider<List<Dish>> {
  /// 获取指定店铺的招牌菜 (最多 3 道, 按菜单顺序).
  ///
  /// 由于店铺详情接口不返回招牌菜列表, 需单独请求. 发布新菜后会失效并重新请求, 离开页面后缓存保留 5 分钟.
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

/// 获取指定店铺的招牌菜 (最多 3 道, 按菜单顺序).
///
/// 由于店铺详情接口不返回招牌菜列表, 需单独请求. 发布新菜后会失效并重新请求, 离开页面后缓存保留 5 分钟.

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

  /// 获取指定店铺的招牌菜 (最多 3 道, 按菜单顺序).
  ///
  /// 由于店铺详情接口不返回招牌菜列表, 需单独请求. 发布新菜后会失效并重新请求, 离开页面后缓存保留 5 分钟.

  ShopSignaturesProvider call(int shopId) =>
      ShopSignaturesProvider._(argument: shopId, from: this);

  @override
  String toString() => r'shopSignaturesProvider';
}

/// 管理当前用户对指定店铺的评价与收藏状态, 操作时采用乐观更新并在失败时回滚.
///
/// 仅订阅店铺详情中的个人评价与收藏两个字段, 避免评价成功后重新请求店铺详情期间旧数据覆盖本地乐观值.

@ProviderFor(ShopMineState)
final shopMineStateProvider = ShopMineStateFamily._();

/// 管理当前用户对指定店铺的评价与收藏状态, 操作时采用乐观更新并在失败时回滚.
///
/// 仅订阅店铺详情中的个人评价与收藏两个字段, 避免评价成功后重新请求店铺详情期间旧数据覆盖本地乐观值.
final class ShopMineStateProvider
    extends $NotifierProvider<ShopMineState, ShopMine> {
  /// 管理当前用户对指定店铺的评价与收藏状态, 操作时采用乐观更新并在失败时回滚.
  ///
  /// 仅订阅店铺详情中的个人评价与收藏两个字段, 避免评价成功后重新请求店铺详情期间旧数据覆盖本地乐观值.
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

/// 管理当前用户对指定店铺的评价与收藏状态, 操作时采用乐观更新并在失败时回滚.
///
/// 仅订阅店铺详情中的个人评价与收藏两个字段, 避免评价成功后重新请求店铺详情期间旧数据覆盖本地乐观值.

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

  /// 管理当前用户对指定店铺的评价与收藏状态, 操作时采用乐观更新并在失败时回滚.
  ///
  /// 仅订阅店铺详情中的个人评价与收藏两个字段, 避免评价成功后重新请求店铺详情期间旧数据覆盖本地乐观值.

  ShopMineStateProvider call(int shopId) =>
      ShopMineStateProvider._(argument: shopId, from: this);

  @override
  String toString() => r'shopMineStateProvider';
}

/// 管理当前用户对指定店铺的评价与收藏状态, 操作时采用乐观更新并在失败时回滚.
///
/// 仅订阅店铺详情中的个人评价与收藏两个字段, 避免评价成功后重新请求店铺详情期间旧数据覆盖本地乐观值.

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

/// 指定店铺的修改记录分页列表, 按时间倒序排列.

@ProviderFor(ShopHistory)
final shopHistoryProvider = ShopHistoryFamily._();

/// 指定店铺的修改记录分页列表, 按时间倒序排列.
final class ShopHistoryProvider
    extends $AsyncNotifierProvider<ShopHistory, LoadedPages<ShopRevision>> {
  /// 指定店铺的修改记录分页列表, 按时间倒序排列.
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

/// 指定店铺的修改记录分页列表, 按时间倒序排列.

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

  /// 指定店铺的修改记录分页列表, 按时间倒序排列.

  ShopHistoryProvider call(int shopId) =>
      ShopHistoryProvider._(argument: shopId, from: this);

  @override
  String toString() => r'shopHistoryProvider';
}

/// 指定店铺的修改记录分页列表, 按时间倒序排列.

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
