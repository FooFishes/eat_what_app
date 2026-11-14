// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publish_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 选店列表: 当前校区内营业中的店. [keyword] 为空时列出附近的店, 否则按店名或地址搜索.
///
/// - 按与用户的距离升序排列. 没有定位时按与校区中心的距离排列, 两者都没有时按新建时间倒序.
/// - 搜店接口也返回已关门的店, 这里去掉.

@ProviderFor(pickableShops)
final pickableShopsProvider = PickableShopsFamily._();

/// 选店列表: 当前校区内营业中的店. [keyword] 为空时列出附近的店, 否则按店名或地址搜索.
///
/// - 按与用户的距离升序排列. 没有定位时按与校区中心的距离排列, 两者都没有时按新建时间倒序.
/// - 搜店接口也返回已关门的店, 这里去掉.

final class PickableShopsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Shop>>,
          List<Shop>,
          FutureOr<List<Shop>>
        >
    with $FutureModifier<List<Shop>>, $FutureProvider<List<Shop>> {
  /// 选店列表: 当前校区内营业中的店. [keyword] 为空时列出附近的店, 否则按店名或地址搜索.
  ///
  /// - 按与用户的距离升序排列. 没有定位时按与校区中心的距离排列, 两者都没有时按新建时间倒序.
  /// - 搜店接口也返回已关门的店, 这里去掉.
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

String _$pickableShopsHash() => r'332dcc19c5cbbbed05260ac9fcbbb7524f7a54ac';

/// 选店列表: 当前校区内营业中的店. [keyword] 为空时列出附近的店, 否则按店名或地址搜索.
///
/// - 按与用户的距离升序排列. 没有定位时按与校区中心的距离排列, 两者都没有时按新建时间倒序.
/// - 搜店接口也返回已关门的店, 这里去掉.

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

  /// 选店列表: 当前校区内营业中的店. [keyword] 为空时列出附近的店, 否则按店名或地址搜索.
  ///
  /// - 按与用户的距离升序排列. 没有定位时按与校区中心的距离排列, 两者都没有时按新建时间倒序.
  /// - 搜店接口也返回已关门的店, 这里去掉.

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

/// 新建店时可能重复的店: 地图地点 [poi] 上已有的店, 或 [point] 200 m 内与 [name] 同名的店, 包括已关门的店.
///
/// 只用于提示, 用户可以继续新建. 输入停顿后再查.

@ProviderFor(shopDuplicates)
final shopDuplicatesProvider = ShopDuplicatesFamily._();

/// 新建店时可能重复的店: 地图地点 [poi] 上已有的店, 或 [point] 200 m 内与 [name] 同名的店, 包括已关门的店.
///
/// 只用于提示, 用户可以继续新建. 输入停顿后再查.

final class ShopDuplicatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ShopDuplicate>>,
          List<ShopDuplicate>,
          FutureOr<List<ShopDuplicate>>
        >
    with
        $FutureModifier<List<ShopDuplicate>>,
        $FutureProvider<List<ShopDuplicate>> {
  /// 新建店时可能重复的店: 地图地点 [poi] 上已有的店, 或 [point] 200 m 内与 [name] 同名的店, 包括已关门的店.
  ///
  /// 只用于提示, 用户可以继续新建. 输入停顿后再查.
  ShopDuplicatesProvider._({
    required ShopDuplicatesFamily super.from,
    required (String, GcjPoint, String?) super.argument,
  }) : super(
         retry: null,
         name: r'shopDuplicatesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$shopDuplicatesHash();

  @override
  String toString() {
    return r'shopDuplicatesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<ShopDuplicate>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ShopDuplicate>> create(Ref ref) {
    final argument = this.argument as (String, GcjPoint, String?);
    return shopDuplicates(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is ShopDuplicatesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shopDuplicatesHash() => r'79fb9cc4d861bb9cc753eeaa4b09c54a20ed6907';

/// 新建店时可能重复的店: 地图地点 [poi] 上已有的店, 或 [point] 200 m 内与 [name] 同名的店, 包括已关门的店.
///
/// 只用于提示, 用户可以继续新建. 输入停顿后再查.

final class ShopDuplicatesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<ShopDuplicate>>,
          (String, GcjPoint, String?)
        > {
  ShopDuplicatesFamily._()
    : super(
        retry: null,
        name: r'shopDuplicatesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 新建店时可能重复的店: 地图地点 [poi] 上已有的店, 或 [point] 200 m 内与 [name] 同名的店, 包括已关门的店.
  ///
  /// 只用于提示, 用户可以继续新建. 输入停顿后再查.

  ShopDuplicatesProvider call(String name, GcjPoint point, String? poi) =>
      ShopDuplicatesProvider._(argument: (name, point, poi), from: this);

  @override
  String toString() => r'shopDuplicatesProvider';
}

/// 新建店的候选: 地图上和 [keyword] 匹配的地点, 在当前位置附近找, 没有定位时在校区中心附近找.
///
/// [keyword] 为空时为空列表. 检索失败时为错误状态.

@ProviderFor(mapPlaces)
final mapPlacesProvider = MapPlacesFamily._();

/// 新建店的候选: 地图上和 [keyword] 匹配的地点, 在当前位置附近找, 没有定位时在校区中心附近找.
///
/// [keyword] 为空时为空列表. 检索失败时为错误状态.

final class MapPlacesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MapPlace>>,
          List<MapPlace>,
          FutureOr<List<MapPlace>>
        >
    with $FutureModifier<List<MapPlace>>, $FutureProvider<List<MapPlace>> {
  /// 新建店的候选: 地图上和 [keyword] 匹配的地点, 在当前位置附近找, 没有定位时在校区中心附近找.
  ///
  /// [keyword] 为空时为空列表. 检索失败时为错误状态.
  MapPlacesProvider._({
    required MapPlacesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'mapPlacesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mapPlacesHash();

  @override
  String toString() {
    return r'mapPlacesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<MapPlace>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MapPlace>> create(Ref ref) {
    final argument = this.argument as String;
    return mapPlaces(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MapPlacesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mapPlacesHash() => r'bec9f99f32758ce81b16ebeabbe349dad56f4ba3';

/// 新建店的候选: 地图上和 [keyword] 匹配的地点, 在当前位置附近找, 没有定位时在校区中心附近找.
///
/// [keyword] 为空时为空列表. 检索失败时为错误状态.

final class MapPlacesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<MapPlace>>, String> {
  MapPlacesFamily._()
    : super(
        retry: null,
        name: r'mapPlacesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 新建店的候选: 地图上和 [keyword] 匹配的地点, 在当前位置附近找, 没有定位时在校区中心附近找.
  ///
  /// [keyword] 为空时为空列表. 检索失败时为错误状态.

  MapPlacesProvider call(String keyword) =>
      MapPlacesProvider._(argument: keyword, from: this);

  @override
  String toString() => r'mapPlacesProvider';
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

/// 要编辑的菜. 编辑页没有从详情页带入菜品时 (如在 Web 上刷新) 使用.

@ProviderFor(dishToEdit)
final dishToEditProvider = DishToEditFamily._();

/// 要编辑的菜. 编辑页没有从详情页带入菜品时 (如在 Web 上刷新) 使用.

final class DishToEditProvider
    extends $FunctionalProvider<AsyncValue<Dish>, Dish, FutureOr<Dish>>
    with $FutureModifier<Dish>, $FutureProvider<Dish> {
  /// 要编辑的菜. 编辑页没有从详情页带入菜品时 (如在 Web 上刷新) 使用.
  DishToEditProvider._({
    required DishToEditFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'dishToEditProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dishToEditHash();

  @override
  String toString() {
    return r'dishToEditProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Dish> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Dish> create(Ref ref) {
    final argument = this.argument as int;
    return dishToEdit(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DishToEditProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dishToEditHash() => r'ad7666735026f144ef01713b2a4cac9df85b2719';

/// 要编辑的菜. 编辑页没有从详情页带入菜品时 (如在 Web 上刷新) 使用.

final class DishToEditFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Dish>, int> {
  DishToEditFamily._()
    : super(
        retry: null,
        name: r'dishToEditProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 要编辑的菜. 编辑页没有从详情页带入菜品时 (如在 Web 上刷新) 使用.

  DishToEditProvider call(int dishId) =>
      DishToEditProvider._(argument: dishId, from: this);

  @override
  String toString() => r'dishToEditProvider';
}

/// 加菜页的草稿和照片上传队列. 随页面释放, 草稿不持久化.
///
/// - [original] 是正在编辑的菜, 发布新菜时为 null. 编辑时分类, 口味和招牌菜预填为现有的值.
/// - 照片添加后立即在后台上传, 并发数有上限.
/// - 上传失败的照片可以单张重试.
/// - 回到前台时, 失败的照片自动重试一次.

@ProviderFor(Draft)
final draftProvider = DraftFamily._();

/// 加菜页的草稿和照片上传队列. 随页面释放, 草稿不持久化.
///
/// - [original] 是正在编辑的菜, 发布新菜时为 null. 编辑时分类, 口味和招牌菜预填为现有的值.
/// - 照片添加后立即在后台上传, 并发数有上限.
/// - 上传失败的照片可以单张重试.
/// - 回到前台时, 失败的照片自动重试一次.
final class DraftProvider extends $NotifierProvider<Draft, PublishDraft> {
  /// 加菜页的草稿和照片上传队列. 随页面释放, 草稿不持久化.
  ///
  /// - [original] 是正在编辑的菜, 发布新菜时为 null. 编辑时分类, 口味和招牌菜预填为现有的值.
  /// - 照片添加后立即在后台上传, 并发数有上限.
  /// - 上传失败的照片可以单张重试.
  /// - 回到前台时, 失败的照片自动重试一次.
  DraftProvider._({
    required DraftFamily super.from,
    required Dish? super.argument,
  }) : super(
         retry: null,
         name: r'draftProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$draftHash();

  @override
  String toString() {
    return r'draftProvider'
        ''
        '($argument)';
  }

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

  @override
  bool operator ==(Object other) {
    return other is DraftProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$draftHash() => r'fd0968064ec6865ead8e59e39844433df1fe3a01';

/// 加菜页的草稿和照片上传队列. 随页面释放, 草稿不持久化.
///
/// - [original] 是正在编辑的菜, 发布新菜时为 null. 编辑时分类, 口味和招牌菜预填为现有的值.
/// - 照片添加后立即在后台上传, 并发数有上限.
/// - 上传失败的照片可以单张重试.
/// - 回到前台时, 失败的照片自动重试一次.

final class DraftFamily extends $Family
    with
        $ClassFamilyOverride<
          Draft,
          PublishDraft,
          PublishDraft,
          PublishDraft,
          Dish?
        > {
  DraftFamily._()
    : super(
        retry: null,
        name: r'draftProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 加菜页的草稿和照片上传队列. 随页面释放, 草稿不持久化.
  ///
  /// - [original] 是正在编辑的菜, 发布新菜时为 null. 编辑时分类, 口味和招牌菜预填为现有的值.
  /// - 照片添加后立即在后台上传, 并发数有上限.
  /// - 上传失败的照片可以单张重试.
  /// - 回到前台时, 失败的照片自动重试一次.

  DraftProvider call({Dish? original}) =>
      DraftProvider._(argument: original, from: this);

  @override
  String toString() => r'draftProvider';
}

/// 加菜页的草稿和照片上传队列. 随页面释放, 草稿不持久化.
///
/// - [original] 是正在编辑的菜, 发布新菜时为 null. 编辑时分类, 口味和招牌菜预填为现有的值.
/// - 照片添加后立即在后台上传, 并发数有上限.
/// - 上传失败的照片可以单张重试.
/// - 回到前台时, 失败的照片自动重试一次.

abstract class _$Draft extends $Notifier<PublishDraft> {
  late final _$args = ref.$arg as Dish?;
  Dish? get original => _$args;

  PublishDraft build({Dish? original});
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
    return element.handleCreate(ref, () => build(original: _$args));
  }
}
