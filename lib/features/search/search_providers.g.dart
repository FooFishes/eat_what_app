// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 按菜名跨店搜索菜品列表, 不限校区, 按发布时间倒序排列.
///
/// 请求固定带堂食场景, 因为服务端只在带场景时排除已关门的店. 堂食不按外卖状态筛菜, 所以不会漏掉不能点外卖的菜.
///
/// 选了 [meal] 时只搜这一顿的菜.

@ProviderFor(dishSearch)
final dishSearchProvider = DishSearchFamily._();

/// 按菜名跨店搜索菜品列表, 不限校区, 按发布时间倒序排列.
///
/// 请求固定带堂食场景, 因为服务端只在带场景时排除已关门的店. 堂食不按外卖状态筛菜, 所以不会漏掉不能点外卖的菜.
///
/// 选了 [meal] 时只搜这一顿的菜.

final class DishSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Dish>>,
          List<Dish>,
          FutureOr<List<Dish>>
        >
    with $FutureModifier<List<Dish>>, $FutureProvider<List<Dish>> {
  /// 按菜名跨店搜索菜品列表, 不限校区, 按发布时间倒序排列.
  ///
  /// 请求固定带堂食场景, 因为服务端只在带场景时排除已关门的店. 堂食不按外卖状态筛菜, 所以不会漏掉不能点外卖的菜.
  ///
  /// 选了 [meal] 时只搜这一顿的菜.
  DishSearchProvider._({
    required DishSearchFamily super.from,
    required (String, MealTime?) super.argument,
  }) : super(
         retry: null,
         name: r'dishSearchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dishSearchHash();

  @override
  String toString() {
    return r'dishSearchProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<Dish>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Dish>> create(Ref ref) {
    final argument = this.argument as (String, MealTime?);
    return dishSearch(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is DishSearchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dishSearchHash() => r'4cb32076e9643d277cd8ad42b468ef4950ca71ff';

/// 按菜名跨店搜索菜品列表, 不限校区, 按发布时间倒序排列.
///
/// 请求固定带堂食场景, 因为服务端只在带场景时排除已关门的店. 堂食不按外卖状态筛菜, 所以不会漏掉不能点外卖的菜.
///
/// 选了 [meal] 时只搜这一顿的菜.

final class DishSearchFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Dish>>, (String, MealTime?)> {
  DishSearchFamily._()
    : super(
        retry: null,
        name: r'dishSearchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 按菜名跨店搜索菜品列表, 不限校区, 按发布时间倒序排列.
  ///
  /// 请求固定带堂食场景, 因为服务端只在带场景时排除已关门的店. 堂食不按外卖状态筛菜, 所以不会漏掉不能点外卖的菜.
  ///
  /// 选了 [meal] 时只搜这一顿的菜.

  DishSearchProvider call(String keyword, MealTime? meal) =>
      DishSearchProvider._(argument: (keyword, meal), from: this);

  @override
  String toString() => r'dishSearchProvider';
}

/// 按店名, 地址或店里的菜名搜索店铺 (含已关门店铺), 按 [order] 排序.
///
/// 已关门店铺不论哪种排序都统一置于末尾, 并保持服务端给的顺序.

@ProviderFor(shopSearch)
final shopSearchProvider = ShopSearchFamily._();

/// 按店名, 地址或店里的菜名搜索店铺 (含已关门店铺), 按 [order] 排序.
///
/// 已关门店铺不论哪种排序都统一置于末尾, 并保持服务端给的顺序.

final class ShopSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Shop>>,
          List<Shop>,
          FutureOr<List<Shop>>
        >
    with $FutureModifier<List<Shop>>, $FutureProvider<List<Shop>> {
  /// 按店名, 地址或店里的菜名搜索店铺 (含已关门店铺), 按 [order] 排序.
  ///
  /// 已关门店铺不论哪种排序都统一置于末尾, 并保持服务端给的顺序.
  ShopSearchProvider._({
    required ShopSearchFamily super.from,
    required (String, ShopOrder) super.argument,
  }) : super(
         retry: null,
         name: r'shopSearchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$shopSearchHash();

  @override
  String toString() {
    return r'shopSearchProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<Shop>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Shop>> create(Ref ref) {
    final argument = this.argument as (String, ShopOrder);
    return shopSearch(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is ShopSearchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shopSearchHash() => r'9a1cbfe859653c8d1d00c2e8decf4d3c56471253';

/// 按店名, 地址或店里的菜名搜索店铺 (含已关门店铺), 按 [order] 排序.
///
/// 已关门店铺不论哪种排序都统一置于末尾, 并保持服务端给的顺序.

final class ShopSearchFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Shop>>, (String, ShopOrder)> {
  ShopSearchFamily._()
    : super(
        retry: null,
        name: r'shopSearchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 按店名, 地址或店里的菜名搜索店铺 (含已关门店铺), 按 [order] 排序.
  ///
  /// 已关门店铺不论哪种排序都统一置于末尾, 并保持服务端给的顺序.

  ShopSearchProvider call(String keyword, ShopOrder order) =>
      ShopSearchProvider._(argument: (keyword, order), from: this);

  @override
  String toString() => r'shopSearchProvider';
}

/// 管理最近搜索关键词列表的控制器, 按搜索时间倒序排列并限制最大条数.
///
/// 记录按账号隔离存储在 `cache.` 前缀下, 退出登录时随账号缓存一并清除; 游客状态既不持久化记录, 也不读取本机其他账号的历史.

@ProviderFor(SearchHistory)
final searchHistoryProvider = SearchHistoryProvider._();

/// 管理最近搜索关键词列表的控制器, 按搜索时间倒序排列并限制最大条数.
///
/// 记录按账号隔离存储在 `cache.` 前缀下, 退出登录时随账号缓存一并清除; 游客状态既不持久化记录, 也不读取本机其他账号的历史.
final class SearchHistoryProvider
    extends $AsyncNotifierProvider<SearchHistory, List<String>> {
  /// 管理最近搜索关键词列表的控制器, 按搜索时间倒序排列并限制最大条数.
  ///
  /// 记录按账号隔离存储在 `cache.` 前缀下, 退出登录时随账号缓存一并清除; 游客状态既不持久化记录, 也不读取本机其他账号的历史.
  SearchHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchHistoryHash();

  @$internal
  @override
  SearchHistory create() => SearchHistory();
}

String _$searchHistoryHash() => r'c37f31660f43efbfb663994673a5364fa2564db1';

/// 管理最近搜索关键词列表的控制器, 按搜索时间倒序排列并限制最大条数.
///
/// 记录按账号隔离存储在 `cache.` 前缀下, 退出登录时随账号缓存一并清除; 游客状态既不持久化记录, 也不读取本机其他账号的历史.

abstract class _$SearchHistory extends $AsyncNotifier<List<String>> {
  FutureOr<List<String>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<String>>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<String>>, List<String>>,
              AsyncValue<List<String>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
