// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 搜菜名：跨店按菜名查。接口不能按距离排（现状差距 2.1），先按热度。

@ProviderFor(dishSearch)
final dishSearchProvider = DishSearchFamily._();

/// 搜菜名：跨店按菜名查。接口不能按距离排（现状差距 2.1），先按热度。

final class DishSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Dish>>,
          List<Dish>,
          FutureOr<List<Dish>>
        >
    with $FutureModifier<List<Dish>>, $FutureProvider<List<Dish>> {
  /// 搜菜名：跨店按菜名查。接口不能按距离排（现状差距 2.1），先按热度。
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

/// 搜菜名：跨店按菜名查。接口不能按距离排（现状差距 2.1），先按热度。

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

  /// 搜菜名：跨店按菜名查。接口不能按距离排（现状差距 2.1），先按热度。

  DishSearchProvider call(String keyword) =>
      DishSearchProvider._(argument: keyword, from: this);

  @override
  String toString() => r'dishSearchProvider';
}

/// 搜店名：离我近的在前，没有定位时按离校区中心的远近。

@ProviderFor(shopSearch)
final shopSearchProvider = ShopSearchFamily._();

/// 搜店名：离我近的在前，没有定位时按离校区中心的远近。

final class ShopSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Shop>>,
          List<Shop>,
          FutureOr<List<Shop>>
        >
    with $FutureModifier<List<Shop>>, $FutureProvider<List<Shop>> {
  /// 搜店名：离我近的在前，没有定位时按离校区中心的远近。
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

/// 搜店名：离我近的在前，没有定位时按离校区中心的远近。

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

  /// 搜店名：离我近的在前，没有定位时按离校区中心的远近。

  ShopSearchProvider call(String keyword) =>
      ShopSearchProvider._(argument: keyword, from: this);

  @override
  String toString() => r'shopSearchProvider';
}

/// 最近搜过的词，最多 10 个，新的在前。按账号存，退出登录时删（技术架构 9.1）。

@ProviderFor(SearchHistory)
final searchHistoryProvider = SearchHistoryProvider._();

/// 最近搜过的词，最多 10 个，新的在前。按账号存，退出登录时删（技术架构 9.1）。
final class SearchHistoryProvider
    extends $AsyncNotifierProvider<SearchHistory, List<String>> {
  /// 最近搜过的词，最多 10 个，新的在前。按账号存，退出登录时删（技术架构 9.1）。
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

/// 最近搜过的词，最多 10 个，新的在前。按账号存，退出登录时删（技术架构 9.1）。

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
