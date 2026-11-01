// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 按菜名跨店搜索菜品.

@ProviderFor(dishSearch)
final dishSearchProvider = DishSearchFamily._();

/// 按菜名跨店搜索菜品.

final class DishSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Dish>>,
          List<Dish>,
          FutureOr<List<Dish>>
        >
    with $FutureModifier<List<Dish>>, $FutureProvider<List<Dish>> {
  /// 按菜名跨店搜索菜品.
  DishSearchProvider._({
    required DishSearchFamily super.from,
    required String super.argument,
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
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Dish>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Dish>> create(Ref ref) {
    final argument = this.argument as String;
    return dishSearch(ref, argument);
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

String _$dishSearchHash() => r'c7308db1e1d3d2eae0259aa344175006ee4c9f02';

/// 按菜名跨店搜索菜品.

final class DishSearchFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Dish>>, String> {
  DishSearchFamily._()
    : super(
        retry: null,
        name: r'dishSearchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 按菜名跨店搜索菜品.

  DishSearchProvider call(String keyword) =>
      DishSearchProvider._(argument: keyword, from: this);

  @override
  String toString() => r'dishSearchProvider';
}

/// 按店名搜索店铺. 按与我的距离升序排列, 没有定位时按与校区中心的距离排列.

@ProviderFor(shopSearch)
final shopSearchProvider = ShopSearchFamily._();

/// 按店名搜索店铺. 按与我的距离升序排列, 没有定位时按与校区中心的距离排列.

final class ShopSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Shop>>,
          List<Shop>,
          FutureOr<List<Shop>>
        >
    with $FutureModifier<List<Shop>>, $FutureProvider<List<Shop>> {
  /// 按店名搜索店铺. 按与我的距离升序排列, 没有定位时按与校区中心的距离排列.
  ShopSearchProvider._({
    required ShopSearchFamily super.from,
    required String super.argument,
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
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Shop>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Shop>> create(Ref ref) {
    final argument = this.argument as String;
    return shopSearch(ref, argument);
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

String _$shopSearchHash() => r'cecccdbbccdb2c63d9aa0c42f5b6de5248c0c1dc';

/// 按店名搜索店铺. 按与我的距离升序排列, 没有定位时按与校区中心的距离排列.

final class ShopSearchFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Shop>>, String> {
  ShopSearchFamily._()
    : super(
        retry: null,
        name: r'shopSearchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 按店名搜索店铺. 按与我的距离升序排列, 没有定位时按与校区中心的距离排列.

  ShopSearchProvider call(String keyword) =>
      ShopSearchProvider._(argument: keyword, from: this);

  @override
  String toString() => r'shopSearchProvider';
}

/// 最近搜索的词, 按时间倒序, 数量有上限.
///
/// 按账号存储在 `cache.` 前缀下, 退出登录时随账号数据一起删除.

@ProviderFor(SearchHistory)
final searchHistoryProvider = SearchHistoryProvider._();

/// 最近搜索的词, 按时间倒序, 数量有上限.
///
/// 按账号存储在 `cache.` 前缀下, 退出登录时随账号数据一起删除.
final class SearchHistoryProvider
    extends $AsyncNotifierProvider<SearchHistory, List<String>> {
  /// 最近搜索的词, 按时间倒序, 数量有上限.
  ///
  /// 按账号存储在 `cache.` 前缀下, 退出登录时随账号数据一起删除.
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

String _$searchHistoryHash() => r'417efa840e7ff95199a6ccaf3b8082d99dfbf5b8';

/// 最近搜索的词, 按时间倒序, 数量有上限.
///
/// 按账号存储在 `cache.` 前缀下, 退出登录时随账号数据一起删除.

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
