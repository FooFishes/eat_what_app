// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_page.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 一家店的菜品, 按赞数降序分页. [tagId] 不为空时只列出带该口味标签的菜.
///
/// 发布新菜后重新请求. 离开页面后保留 5 分钟.

@ProviderFor(ShopMenu)
final shopMenuProvider = ShopMenuFamily._();

/// 一家店的菜品, 按赞数降序分页. [tagId] 不为空时只列出带该口味标签的菜.
///
/// 发布新菜后重新请求. 离开页面后保留 5 分钟.
final class ShopMenuProvider
    extends $AsyncNotifierProvider<ShopMenu, MenuPages> {
  /// 一家店的菜品, 按赞数降序分页. [tagId] 不为空时只列出带该口味标签的菜.
  ///
  /// 发布新菜后重新请求. 离开页面后保留 5 分钟.
  ShopMenuProvider._({
    required ShopMenuFamily super.from,
    required (int, int?) super.argument,
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
        '$argument';
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

String _$shopMenuHash() => r'7a5891fe93557c52f13021adef709d6f2dbd8576';

/// 一家店的菜品, 按赞数降序分页. [tagId] 不为空时只列出带该口味标签的菜.
///
/// 发布新菜后重新请求. 离开页面后保留 5 分钟.

final class ShopMenuFamily extends $Family
    with
        $ClassFamilyOverride<
          ShopMenu,
          AsyncValue<MenuPages>,
          MenuPages,
          FutureOr<MenuPages>,
          (int, int?)
        > {
  ShopMenuFamily._()
    : super(
        retry: null,
        name: r'shopMenuProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 一家店的菜品, 按赞数降序分页. [tagId] 不为空时只列出带该口味标签的菜.
  ///
  /// 发布新菜后重新请求. 离开页面后保留 5 分钟.

  ShopMenuProvider call(int shopId, int? tagId) =>
      ShopMenuProvider._(argument: (shopId, tagId), from: this);

  @override
  String toString() => r'shopMenuProvider';
}

/// 一家店的菜品, 按赞数降序分页. [tagId] 不为空时只列出带该口味标签的菜.
///
/// 发布新菜后重新请求. 离开页面后保留 5 分钟.

abstract class _$ShopMenu extends $AsyncNotifier<MenuPages> {
  late final _$args = ref.$arg as (int, int?);
  int get shopId => _$args.$1;
  int? get tagId => _$args.$2;

  FutureOr<MenuPages> build(int shopId, int? tagId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<MenuPages>, MenuPages>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MenuPages>, MenuPages>,
              AsyncValue<MenuPages>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
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

String _$shopMineStateHash() => r'5a38b2a46fe8c1bb165b567163a57fa9fbe407b9';

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
