// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nearby_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 当前校区内附近营业中的店, 按 [NearbyQuery.sort] 排列.
///
/// 关键词同时匹配店名和菜名. 不传校区时后端只查默认校区.
///
/// 按距离排序时, 后端按与地图中心的距离排列, 客户端改按与用户的距离重排.
/// 列表显示的是与用户的距离, 拖动地图后两者不一致. 没有定位时保持按与地图中心的距离排列.

@ProviderFor(nearbyShops)
final nearbyShopsProvider = NearbyShopsFamily._();

/// 当前校区内附近营业中的店, 按 [NearbyQuery.sort] 排列.
///
/// 关键词同时匹配店名和菜名. 不传校区时后端只查默认校区.
///
/// 按距离排序时, 后端按与地图中心的距离排列, 客户端改按与用户的距离重排.
/// 列表显示的是与用户的距离, 拖动地图后两者不一致. 没有定位时保持按与地图中心的距离排列.

final class NearbyShopsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Shop>>,
          List<Shop>,
          FutureOr<List<Shop>>
        >
    with $FutureModifier<List<Shop>>, $FutureProvider<List<Shop>> {
  /// 当前校区内附近营业中的店, 按 [NearbyQuery.sort] 排列.
  ///
  /// 关键词同时匹配店名和菜名. 不传校区时后端只查默认校区.
  ///
  /// 按距离排序时, 后端按与地图中心的距离排列, 客户端改按与用户的距离重排.
  /// 列表显示的是与用户的距离, 拖动地图后两者不一致. 没有定位时保持按与地图中心的距离排列.
  NearbyShopsProvider._({
    required NearbyShopsFamily super.from,
    required NearbyQuery super.argument,
  }) : super(
         retry: null,
         name: r'nearbyShopsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$nearbyShopsHash();

  @override
  String toString() {
    return r'nearbyShopsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Shop>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Shop>> create(Ref ref) {
    final argument = this.argument as NearbyQuery;
    return nearbyShops(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is NearbyShopsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$nearbyShopsHash() => r'8c2b9a80d5d3a7741a2d901d03047f075bcd7443';

/// 当前校区内附近营业中的店, 按 [NearbyQuery.sort] 排列.
///
/// 关键词同时匹配店名和菜名. 不传校区时后端只查默认校区.
///
/// 按距离排序时, 后端按与地图中心的距离排列, 客户端改按与用户的距离重排.
/// 列表显示的是与用户的距离, 拖动地图后两者不一致. 没有定位时保持按与地图中心的距离排列.

final class NearbyShopsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Shop>>, NearbyQuery> {
  NearbyShopsFamily._()
    : super(
        retry: null,
        name: r'nearbyShopsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 当前校区内附近营业中的店, 按 [NearbyQuery.sort] 排列.
  ///
  /// 关键词同时匹配店名和菜名. 不传校区时后端只查默认校区.
  ///
  /// 按距离排序时, 后端按与地图中心的距离排列, 客户端改按与用户的距离重排.
  /// 列表显示的是与用户的距离, 拖动地图后两者不一致. 没有定位时保持按与地图中心的距离排列.

  NearbyShopsProvider call(NearbyQuery query) =>
      NearbyShopsProvider._(argument: query, from: this);

  @override
  String toString() => r'nearbyShopsProvider';
}

/// 我当前所在的商圈, 附近页默认选中该商圈.
///
/// 没有定位或不在任何商圈内时为 null.

@ProviderFor(myHub)
final myHubProvider = MyHubProvider._();

/// 我当前所在的商圈, 附近页默认选中该商圈.
///
/// 没有定位或不在任何商圈内时为 null.

final class MyHubProvider
    extends $FunctionalProvider<AsyncValue<Hub?>, Hub?, FutureOr<Hub?>>
    with $FutureModifier<Hub?>, $FutureProvider<Hub?> {
  /// 我当前所在的商圈, 附近页默认选中该商圈.
  ///
  /// 没有定位或不在任何商圈内时为 null.
  MyHubProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myHubProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myHubHash();

  @$internal
  @override
  $FutureProviderElement<Hub?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Hub?> create(Ref ref) {
    return myHub(ref);
  }
}

String _$myHubHash() => r'30801ea7c162f9ef6f0eb76904ef25536364c232';
