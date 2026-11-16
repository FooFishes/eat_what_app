// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nearby_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 查询当前校区内附近营业中的店铺, 按与用户的距离升序排列.
///
/// - 关键词同时匹配店名与地址; 搜店接口包含已歇业店铺, 此处过滤掉已关门的店, 因此实际返回数可能少于分页大小.
/// - 后端按与地图中心的距离排序, 因列表展示的是与用户实时定位的距离, 拖动地图后两者不再一致, 故客户端在有定位时按用户距离重排, 无定位时保持服务端顺序.

@ProviderFor(nearbyShops)
final nearbyShopsProvider = NearbyShopsFamily._();

/// 查询当前校区内附近营业中的店铺, 按与用户的距离升序排列.
///
/// - 关键词同时匹配店名与地址; 搜店接口包含已歇业店铺, 此处过滤掉已关门的店, 因此实际返回数可能少于分页大小.
/// - 后端按与地图中心的距离排序, 因列表展示的是与用户实时定位的距离, 拖动地图后两者不再一致, 故客户端在有定位时按用户距离重排, 无定位时保持服务端顺序.

final class NearbyShopsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Shop>>,
          List<Shop>,
          FutureOr<List<Shop>>
        >
    with $FutureModifier<List<Shop>>, $FutureProvider<List<Shop>> {
  /// 查询当前校区内附近营业中的店铺, 按与用户的距离升序排列.
  ///
  /// - 关键词同时匹配店名与地址; 搜店接口包含已歇业店铺, 此处过滤掉已关门的店, 因此实际返回数可能少于分页大小.
  /// - 后端按与地图中心的距离排序, 因列表展示的是与用户实时定位的距离, 拖动地图后两者不再一致, 故客户端在有定位时按用户距离重排, 无定位时保持服务端顺序.
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

String _$nearbyShopsHash() => r'c5e1ae3c387f9e831cf0a24baa14885f9ae413b8';

/// 查询当前校区内附近营业中的店铺, 按与用户的距离升序排列.
///
/// - 关键词同时匹配店名与地址; 搜店接口包含已歇业店铺, 此处过滤掉已关门的店, 因此实际返回数可能少于分页大小.
/// - 后端按与地图中心的距离排序, 因列表展示的是与用户实时定位的距离, 拖动地图后两者不再一致, 故客户端在有定位时按用户距离重排, 无定位时保持服务端顺序.

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

  /// 查询当前校区内附近营业中的店铺, 按与用户的距离升序排列.
  ///
  /// - 关键词同时匹配店名与地址; 搜店接口包含已歇业店铺, 此处过滤掉已关门的店, 因此实际返回数可能少于分页大小.
  /// - 后端按与地图中心的距离排序, 因列表展示的是与用户实时定位的距离, 拖动地图后两者不再一致, 故客户端在有定位时按用户距离重排, 无定位时保持服务端顺序.

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
