// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publish_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 选店列表. [keyword] 为空时列出附近的店.
///
/// 按与我的距离升序排列. 没有定位时按与校区中心的距离排列.

@ProviderFor(pickableShops)
final pickableShopsProvider = PickableShopsFamily._();

/// 选店列表. [keyword] 为空时列出附近的店.
///
/// 按与我的距离升序排列. 没有定位时按与校区中心的距离排列.

final class PickableShopsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Shop>>,
          List<Shop>,
          FutureOr<List<Shop>>
        >
    with $FutureModifier<List<Shop>>, $FutureProvider<List<Shop>> {
  /// 选店列表. [keyword] 为空时列出附近的店.
  ///
  /// 按与我的距离升序排列. 没有定位时按与校区中心的距离排列.
  PickableShopsProvider._({
    required PickableShopsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pickableShopsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pickableShopsHash();

  @override
  String toString() {
    return r'pickableShopsProvider'
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
    return pickableShops(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PickableShopsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pickableShopsHash() => r'f1b76821ed1aafbbf9b76abf5886d85867b26514';

/// 选店列表. [keyword] 为空时列出附近的店.
///
/// 按与我的距离升序排列. 没有定位时按与校区中心的距离排列.

final class PickableShopsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Shop>>, String> {
  PickableShopsFamily._()
    : super(
        retry: null,
        name: r'pickableShopsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 选店列表. [keyword] 为空时列出附近的店.
  ///
  /// 按与我的距离升序排列. 没有定位时按与校区中心的距离排列.

  PickableShopsProvider call(String keyword) =>
      PickableShopsProvider._(argument: keyword, from: this);

  @override
  String toString() => r'pickableShopsProvider';
}

/// 我当前所在的商圈, 用于选店页的位置提示. 没有定位或不在任何商圈内时为 null.

@ProviderFor(myHub)
final myHubProvider = MyHubProvider._();

/// 我当前所在的商圈, 用于选店页的位置提示. 没有定位或不在任何商圈内时为 null.

final class MyHubProvider
    extends $FunctionalProvider<AsyncValue<Hub?>, Hub?, FutureOr<Hub?>>
    with $FutureModifier<Hub?>, $FutureProvider<Hub?> {
  /// 我当前所在的商圈, 用于选店页的位置提示. 没有定位或不在任何商圈内时为 null.
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

/// 地图中心所在的商圈. 新建店时据此自动确定所属商圈.

@ProviderFor(hubAt)
final hubAtProvider = HubAtFamily._();

/// 地图中心所在的商圈. 新建店时据此自动确定所属商圈.

final class HubAtProvider
    extends $FunctionalProvider<AsyncValue<Hub?>, Hub?, FutureOr<Hub?>>
    with $FutureModifier<Hub?>, $FutureProvider<Hub?> {
  /// 地图中心所在的商圈. 新建店时据此自动确定所属商圈.
  HubAtProvider._({
    required HubAtFamily super.from,
    required GcjPoint super.argument,
  }) : super(
         retry: null,
         name: r'hubAtProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$hubAtHash();

  @override
  String toString() {
    return r'hubAtProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Hub?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Hub?> create(Ref ref) {
    final argument = this.argument as GcjPoint;
    return hubAt(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HubAtProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$hubAtHash() => r'ab05209d56ed9b3cb37591fce54c1858cb7aa031';

/// 地图中心所在的商圈. 新建店时据此自动确定所属商圈.

final class HubAtFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Hub?>, GcjPoint> {
  HubAtFamily._()
    : super(
        retry: null,
        name: r'hubAtProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 地图中心所在的商圈. 新建店时据此自动确定所属商圈.

  HubAtProvider call(GcjPoint point) =>
      HubAtProvider._(argument: point, from: this);

  @override
  String toString() => r'hubAtProvider';
}

/// 新建店时, 地图中心附近的同名店. 没有时为 null.

@ProviderFor(sameNameShop)
final sameNameShopProvider = SameNameShopFamily._();

/// 新建店时, 地图中心附近的同名店. 没有时为 null.

final class SameNameShopProvider
    extends $FunctionalProvider<AsyncValue<Shop?>, Shop?, FutureOr<Shop?>>
    with $FutureModifier<Shop?>, $FutureProvider<Shop?> {
  /// 新建店时, 地图中心附近的同名店. 没有时为 null.
  SameNameShopProvider._({
    required SameNameShopFamily super.from,
    required (String, GcjPoint) super.argument,
  }) : super(
         retry: null,
         name: r'sameNameShopProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sameNameShopHash();

  @override
  String toString() {
    return r'sameNameShopProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<Shop?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Shop?> create(Ref ref) {
    final argument = this.argument as (String, GcjPoint);
    return sameNameShop(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is SameNameShopProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sameNameShopHash() => r'216076e5af1e0172d878cb6e234620ce9ed5f53b';

/// 新建店时, 地图中心附近的同名店. 没有时为 null.

final class SameNameShopFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Shop?>, (String, GcjPoint)> {
  SameNameShopFamily._()
    : super(
        retry: null,
        name: r'sameNameShopProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 新建店时, 地图中心附近的同名店. 没有时为 null.

  SameNameShopProvider call(String name, GcjPoint point) =>
      SameNameShopProvider._(argument: (name, point), from: this);

  @override
  String toString() => r'sameNameShopProvider';
}

/// 菜名查重. 这家店已有同名菜时返回该菜, 否则为 null.

@ProviderFor(sameNameDish)
final sameNameDishProvider = SameNameDishFamily._();

/// 菜名查重. 这家店已有同名菜时返回该菜, 否则为 null.

final class SameNameDishProvider
    extends $FunctionalProvider<AsyncValue<Dish?>, Dish?, FutureOr<Dish?>>
    with $FutureModifier<Dish?>, $FutureProvider<Dish?> {
  /// 菜名查重. 这家店已有同名菜时返回该菜, 否则为 null.
  SameNameDishProvider._({
    required SameNameDishFamily super.from,
    required (int, String) super.argument,
  }) : super(
         retry: null,
         name: r'sameNameDishProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sameNameDishHash();

  @override
  String toString() {
    return r'sameNameDishProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<Dish?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Dish?> create(Ref ref) {
    final argument = this.argument as (int, String);
    return sameNameDish(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is SameNameDishProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sameNameDishHash() => r'dcc1779df716a0b10b6230f13a5eed45d9e997a3';

/// 菜名查重. 这家店已有同名菜时返回该菜, 否则为 null.

final class SameNameDishFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Dish?>, (int, String)> {
  SameNameDishFamily._()
    : super(
        retry: null,
        name: r'sameNameDishProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 菜名查重. 这家店已有同名菜时返回该菜, 否则为 null.

  SameNameDishProvider call(int shopId, String name) =>
      SameNameDishProvider._(argument: (shopId, name), from: this);

  @override
  String toString() => r'sameNameDishProvider';
}

/// 加菜页的草稿和照片上传队列. 随页面释放, 草稿不持久化.
///
/// - 照片添加后立即在后台上传, 并发数有上限.
/// - 上传失败的照片可以单张重试.
/// - 回到前台时, 失败的照片自动重试一次.

@ProviderFor(Draft)
final draftProvider = DraftProvider._();

/// 加菜页的草稿和照片上传队列. 随页面释放, 草稿不持久化.
///
/// - 照片添加后立即在后台上传, 并发数有上限.
/// - 上传失败的照片可以单张重试.
/// - 回到前台时, 失败的照片自动重试一次.
final class DraftProvider extends $NotifierProvider<Draft, PublishDraft> {
  /// 加菜页的草稿和照片上传队列. 随页面释放, 草稿不持久化.
  ///
  /// - 照片添加后立即在后台上传, 并发数有上限.
  /// - 上传失败的照片可以单张重试.
  /// - 回到前台时, 失败的照片自动重试一次.
  DraftProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'draftProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$draftHash();

  @$internal
  @override
  Draft create() => Draft();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PublishDraft value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PublishDraft>(value),
    );
  }
}

String _$draftHash() => r'74843abe9ceb74e308cb64cbfa99337978f84c2d';

/// 加菜页的草稿和照片上传队列. 随页面释放, 草稿不持久化.
///
/// - 照片添加后立即在后台上传, 并发数有上限.
/// - 上传失败的照片可以单张重试.
/// - 回到前台时, 失败的照片自动重试一次.

abstract class _$Draft extends $Notifier<PublishDraft> {
  PublishDraft build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PublishDraft, PublishDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PublishDraft, PublishDraft>,
              PublishDraft,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
