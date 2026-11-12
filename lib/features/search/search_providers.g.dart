// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 按菜名跨店搜索菜品, 最新的在前.

@ProviderFor(dishSearch)
final dishSearchProvider = DishSearchFamily._();

/// 按菜名跨店搜索菜品, 最新的在前.

final class DishSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Dish>>,
          List<Dish>,
          FutureOr<List<Dish>>
        >
    with $FutureModifier<List<Dish>>, $FutureProvider<List<Dish>> {
  /// 按菜名跨店搜索菜品, 最新的在前.
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

String _$dishSearchHash() => r'045f33a57a41ccb825ba3d3923458c2f84abb21c';

/// 按菜名跨店搜索菜品, 最新的在前.

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

  /// 按菜名跨店搜索菜品, 最新的在前.

  DishSearchProvider call(String keyword) =>
      DishSearchProvider._(argument: keyword, from: this);

  @override
  String toString() => r'dishSearchProvider';
}

/// 按店名或地址搜索当前校区的店铺, 包括已关门的店.
///
/// 按与用户的距离升序排列, 没有定位时按与校区中心的距离排列. 已关门的店排在最后, 彼此之间保持距离顺序.

@ProviderFor(shopSearch)
final shopSearchProvider = ShopSearchFamily._();

/// 按店名或地址搜索当前校区的店铺, 包括已关门的店.
///
/// 按与用户的距离升序排列, 没有定位时按与校区中心的距离排列. 已关门的店排在最后, 彼此之间保持距离顺序.

final class ShopSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Shop>>,
          List<Shop>,
          FutureOr<List<Shop>>
        >
    with $FutureModifier<List<Shop>>, $FutureProvider<List<Shop>> {
  /// 按店名或地址搜索当前校区的店铺, 包括已关门的店.
  ///
  /// 按与用户的距离升序排列, 没有定位时按与校区中心的距离排列. 已关门的店排在最后, 彼此之间保持距离顺序.
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

String _$shopSearchHash() => r'6ab0cb04d84fe7981012f04ab9fb602d94b030de';

/// 按店名或地址搜索当前校区的店铺, 包括已关门的店.
///
/// 按与用户的距离升序排列, 没有定位时按与校区中心的距离排列. 已关门的店排在最后, 彼此之间保持距离顺序.

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

  /// 按店名或地址搜索当前校区的店铺, 包括已关门的店.
  ///
  /// 按与用户的距离升序排列, 没有定位时按与校区中心的距离排列. 已关门的店排在最后, 彼此之间保持距离顺序.

  ShopSearchProvider call(String keyword) =>
      ShopSearchProvider._(argument: keyword, from: this);

  @override
  String toString() => r'shopSearchProvider';
}

/// 最近搜索的词, 按时间倒序, 数量有上限.
///
/// 按账号存储在 `cache.` 前缀下, 退出登录时随账号数据一起删除.
/// 游客搜过的词不保存, 也不显示本机上其他账号的记录.

@ProviderFor(SearchHistory)
final searchHistoryProvider = SearchHistoryProvider._();

/// 最近搜索的词, 按时间倒序, 数量有上限.
///
/// 按账号存储在 `cache.` 前缀下, 退出登录时随账号数据一起删除.
/// 游客搜过的词不保存, 也不显示本机上其他账号的记录.
final class SearchHistoryProvider
    extends $AsyncNotifierProvider<SearchHistory, List<String>> {
  /// 最近搜索的词, 按时间倒序, 数量有上限.
  ///
  /// 按账号存储在 `cache.` 前缀下, 退出登录时随账号数据一起删除.
  /// 游客搜过的词不保存, 也不显示本机上其他账号的记录.
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

/// 最近搜索的词, 按时间倒序, 数量有上限.
///
/// 按账号存储在 `cache.` 前缀下, 退出登录时随账号数据一起删除.
/// 游客搜过的词不保存, 也不显示本机上其他账号的记录.

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
