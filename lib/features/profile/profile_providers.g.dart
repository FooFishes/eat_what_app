// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 我上传的菜. 发布成功后重新请求.
///
/// "我的" 是常驻的主页面, 切换到其他主页面后保留结果, 不重新请求.
///
/// 封禁中改用他人主页的接口读取. 受限会话不能调用 `/foods/my`, 但可以调用 `/foods/by-user/{id}`.

@ProviderFor(MyUploads)
final myUploadsProvider = MyUploadsProvider._();

/// 我上传的菜. 发布成功后重新请求.
///
/// "我的" 是常驻的主页面, 切换到其他主页面后保留结果, 不重新请求.
///
/// 封禁中改用他人主页的接口读取. 受限会话不能调用 `/foods/my`, 但可以调用 `/foods/by-user/{id}`.
final class MyUploadsProvider
    extends $AsyncNotifierProvider<MyUploads, DishPages> {
  /// 我上传的菜. 发布成功后重新请求.
  ///
  /// "我的" 是常驻的主页面, 切换到其他主页面后保留结果, 不重新请求.
  ///
  /// 封禁中改用他人主页的接口读取. 受限会话不能调用 `/foods/my`, 但可以调用 `/foods/by-user/{id}`.
  MyUploadsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myUploadsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myUploadsHash();

  @$internal
  @override
  MyUploads create() => MyUploads();
}

String _$myUploadsHash() => r'8db7af5ec8e860f384a114828a60f74f00b2cc19';

/// 我上传的菜. 发布成功后重新请求.
///
/// "我的" 是常驻的主页面, 切换到其他主页面后保留结果, 不重新请求.
///
/// 封禁中改用他人主页的接口读取. 受限会话不能调用 `/foods/my`, 但可以调用 `/foods/by-user/{id}`.

abstract class _$MyUploads extends $AsyncNotifier<DishPages> {
  FutureOr<DishPages> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DishPages>, DishPages>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DishPages>, DishPages>,
              AsyncValue<DishPages>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 我收藏的菜, 按收藏时间倒序.

@ProviderFor(MyFavorites)
final myFavoritesProvider = MyFavoritesProvider._();

/// 我收藏的菜, 按收藏时间倒序.
final class MyFavoritesProvider
    extends $AsyncNotifierProvider<MyFavorites, DishPages> {
  /// 我收藏的菜, 按收藏时间倒序.
  MyFavoritesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myFavoritesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myFavoritesHash();

  @$internal
  @override
  MyFavorites create() => MyFavorites();
}

String _$myFavoritesHash() => r'9241a8eb5fc3737374f3e95c2046998440bea26a';

/// 我收藏的菜, 按收藏时间倒序.

abstract class _$MyFavorites extends $AsyncNotifier<DishPages> {
  FutureOr<DishPages> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DishPages>, DishPages>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DishPages>, DishPages>,
              AsyncValue<DishPages>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 我收藏的店. 已关门的店排在最后.

@ProviderFor(MyFavoriteShops)
final myFavoriteShopsProvider = MyFavoriteShopsProvider._();

/// 我收藏的店. 已关门的店排在最后.
final class MyFavoriteShopsProvider
    extends $AsyncNotifierProvider<MyFavoriteShops, ListPages<Shop>> {
  /// 我收藏的店. 已关门的店排在最后.
  MyFavoriteShopsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myFavoriteShopsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myFavoriteShopsHash();

  @$internal
  @override
  MyFavoriteShops create() => MyFavoriteShops();
}

String _$myFavoriteShopsHash() => r'af503c70caca042aa64df00a8203927f8ebc24e7';

/// 我收藏的店. 已关门的店排在最后.

abstract class _$MyFavoriteShops extends $AsyncNotifier<ListPages<Shop>> {
  FutureOr<ListPages<Shop>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ListPages<Shop>>, ListPages<Shop>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ListPages<Shop>>, ListPages<Shop>>,
              AsyncValue<ListPages<Shop>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 他人主页的 "上传". 离开页面后保留 5 分钟.

@ProviderFor(UserUploads)
final userUploadsProvider = UserUploadsFamily._();

/// 他人主页的 "上传". 离开页面后保留 5 分钟.
final class UserUploadsProvider
    extends $AsyncNotifierProvider<UserUploads, DishPages> {
  /// 他人主页的 "上传". 离开页面后保留 5 分钟.
  UserUploadsProvider._({
    required UserUploadsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'userUploadsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userUploadsHash();

  @override
  String toString() {
    return r'userUploadsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  UserUploads create() => UserUploads();

  @override
  bool operator ==(Object other) {
    return other is UserUploadsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userUploadsHash() => r'fb385cedc951c56d7ac03646402f022adbaab4a9';

/// 他人主页的 "上传". 离开页面后保留 5 分钟.

final class UserUploadsFamily extends $Family
    with
        $ClassFamilyOverride<
          UserUploads,
          AsyncValue<DishPages>,
          DishPages,
          FutureOr<DishPages>,
          int
        > {
  UserUploadsFamily._()
    : super(
        retry: null,
        name: r'userUploadsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 他人主页的 "上传". 离开页面后保留 5 分钟.

  UserUploadsProvider call(int userId) =>
      UserUploadsProvider._(argument: userId, from: this);

  @override
  String toString() => r'userUploadsProvider';
}

/// 他人主页的 "上传". 离开页面后保留 5 分钟.

abstract class _$UserUploads extends $AsyncNotifier<DishPages> {
  late final _$args = ref.$arg as int;
  int get userId => _$args;

  FutureOr<DishPages> build(int userId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DishPages>, DishPages>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DishPages>, DishPages>,
              AsyncValue<DishPages>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// [userId] 的粉丝或关注列表.
///
/// 对方未公开该列表时失败, [AppFailure.code] 为 `BizCodes.notSupported`, 页面显示 "对方未公开".

@ProviderFor(FollowList)
final followListProvider = FollowListFamily._();

/// [userId] 的粉丝或关注列表.
///
/// 对方未公开该列表时失败, [AppFailure.code] 为 `BizCodes.notSupported`, 页面显示 "对方未公开".
final class FollowListProvider
    extends $AsyncNotifierProvider<FollowList, ListPages<UserBrief>> {
  /// [userId] 的粉丝或关注列表.
  ///
  /// 对方未公开该列表时失败, [AppFailure.code] 为 `BizCodes.notSupported`, 页面显示 "对方未公开".
  FollowListProvider._({
    required FollowListFamily super.from,
    required (int, FollowListKind) super.argument,
  }) : super(
         retry: null,
         name: r'followListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$followListHash();

  @override
  String toString() {
    return r'followListProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  FollowList create() => FollowList();

  @override
  bool operator ==(Object other) {
    return other is FollowListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$followListHash() => r'2e6657246ee4dd4fe43e383cf0f3dbab96ec0f48';

/// [userId] 的粉丝或关注列表.
///
/// 对方未公开该列表时失败, [AppFailure.code] 为 `BizCodes.notSupported`, 页面显示 "对方未公开".

final class FollowListFamily extends $Family
    with
        $ClassFamilyOverride<
          FollowList,
          AsyncValue<ListPages<UserBrief>>,
          ListPages<UserBrief>,
          FutureOr<ListPages<UserBrief>>,
          (int, FollowListKind)
        > {
  FollowListFamily._()
    : super(
        retry: null,
        name: r'followListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// [userId] 的粉丝或关注列表.
  ///
  /// 对方未公开该列表时失败, [AppFailure.code] 为 `BizCodes.notSupported`, 页面显示 "对方未公开".

  FollowListProvider call(int userId, FollowListKind kind) =>
      FollowListProvider._(argument: (userId, kind), from: this);

  @override
  String toString() => r'followListProvider';
}

/// [userId] 的粉丝或关注列表.
///
/// 对方未公开该列表时失败, [AppFailure.code] 为 `BizCodes.notSupported`, 页面显示 "对方未公开".

abstract class _$FollowList extends $AsyncNotifier<ListPages<UserBrief>> {
  late final _$args = ref.$arg as (int, FollowListKind);
  int get userId => _$args.$1;
  FollowListKind get kind => _$args.$2;

  FutureOr<ListPages<UserBrief>> build(int userId, FollowListKind kind);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<ListPages<UserBrief>>, ListPages<UserBrief>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ListPages<UserBrief>>,
                ListPages<UserBrief>
              >,
              AsyncValue<ListPages<UserBrief>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

/// 当前用户是否屏蔽了 [userId]. 他人主页的 "更多" 据此显示 "屏蔽" 或 "解除屏蔽".

@ProviderFor(BlockState)
final blockStateProvider = BlockStateFamily._();

/// 当前用户是否屏蔽了 [userId]. 他人主页的 "更多" 据此显示 "屏蔽" 或 "解除屏蔽".
final class BlockStateProvider
    extends $AsyncNotifierProvider<BlockState, bool> {
  /// 当前用户是否屏蔽了 [userId]. 他人主页的 "更多" 据此显示 "屏蔽" 或 "解除屏蔽".
  BlockStateProvider._({
    required BlockStateFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'blockStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$blockStateHash();

  @override
  String toString() {
    return r'blockStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  BlockState create() => BlockState();

  @override
  bool operator ==(Object other) {
    return other is BlockStateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$blockStateHash() => r'd88e7605bba55e54b6be4583adae92339f0cf196';

/// 当前用户是否屏蔽了 [userId]. 他人主页的 "更多" 据此显示 "屏蔽" 或 "解除屏蔽".

final class BlockStateFamily extends $Family
    with
        $ClassFamilyOverride<
          BlockState,
          AsyncValue<bool>,
          bool,
          FutureOr<bool>,
          int
        > {
  BlockStateFamily._()
    : super(
        retry: null,
        name: r'blockStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 当前用户是否屏蔽了 [userId]. 他人主页的 "更多" 据此显示 "屏蔽" 或 "解除屏蔽".

  BlockStateProvider call(int userId) =>
      BlockStateProvider._(argument: userId, from: this);

  @override
  String toString() => r'blockStateProvider';
}

/// 当前用户是否屏蔽了 [userId]. 他人主页的 "更多" 据此显示 "屏蔽" 或 "解除屏蔽".

abstract class _$BlockState extends $AsyncNotifier<bool> {
  late final _$args = ref.$arg as int;
  int get userId => _$args;

  FutureOr<bool> build(int userId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// 我的标签. 只有认证用户能写标签, 未认证时不请求, 返回空列表.

@ProviderFor(MyTags)
final myTagsProvider = MyTagsProvider._();

/// 我的标签. 只有认证用户能写标签, 未认证时不请求, 返回空列表.
final class MyTagsProvider extends $AsyncNotifierProvider<MyTags, List<MyTag>> {
  /// 我的标签. 只有认证用户能写标签, 未认证时不请求, 返回空列表.
  MyTagsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myTagsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myTagsHash();

  @$internal
  @override
  MyTags create() => MyTags();
}

String _$myTagsHash() => r'37714cd052efc49aa7ff6f8d930f4088a30d07c1';

/// 我的标签. 只有认证用户能写标签, 未认证时不请求, 返回空列表.

abstract class _$MyTags extends $AsyncNotifier<List<MyTag>> {
  FutureOr<List<MyTag>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<MyTag>>, List<MyTag>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<MyTag>>, List<MyTag>>,
              AsyncValue<List<MyTag>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 用我的标签 [tagId] 标过的菜.

@ProviderFor(TagDishes)
final tagDishesProvider = TagDishesFamily._();

/// 用我的标签 [tagId] 标过的菜.
final class TagDishesProvider
    extends $AsyncNotifierProvider<TagDishes, DishPages> {
  /// 用我的标签 [tagId] 标过的菜.
  TagDishesProvider._({
    required TagDishesFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'tagDishesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tagDishesHash();

  @override
  String toString() {
    return r'tagDishesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TagDishes create() => TagDishes();

  @override
  bool operator ==(Object other) {
    return other is TagDishesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tagDishesHash() => r'798bc285ced63e013aff2fbbf1b9a95d602a8b16';

/// 用我的标签 [tagId] 标过的菜.

final class TagDishesFamily extends $Family
    with
        $ClassFamilyOverride<
          TagDishes,
          AsyncValue<DishPages>,
          DishPages,
          FutureOr<DishPages>,
          int
        > {
  TagDishesFamily._()
    : super(
        retry: null,
        name: r'tagDishesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 用我的标签 [tagId] 标过的菜.

  TagDishesProvider call(int tagId) =>
      TagDishesProvider._(argument: tagId, from: this);

  @override
  String toString() => r'tagDishesProvider';
}

/// 用我的标签 [tagId] 标过的菜.

abstract class _$TagDishes extends $AsyncNotifier<DishPages> {
  late final _$args = ref.$arg as int;
  int get tagId => _$args;

  FutureOr<DishPages> build(int tagId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DishPages>, DishPages>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DishPages>, DishPages>,
              AsyncValue<DishPages>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// 足迹的一个分栏, 按最近看过排序.

@ProviderFor(Footprints)
final footprintsProvider = FootprintsFamily._();

/// 足迹的一个分栏, 按最近看过排序.
final class FootprintsProvider
    extends $AsyncNotifierProvider<Footprints, ListPages<Footprint>> {
  /// 足迹的一个分栏, 按最近看过排序.
  FootprintsProvider._({
    required FootprintsFamily super.from,
    required FootprintKind super.argument,
  }) : super(
         retry: null,
         name: r'footprintsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$footprintsHash();

  @override
  String toString() {
    return r'footprintsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  Footprints create() => Footprints();

  @override
  bool operator ==(Object other) {
    return other is FootprintsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$footprintsHash() => r'f3b3b145c08ffbe5c5592a7374d4afb919a10680';

/// 足迹的一个分栏, 按最近看过排序.

final class FootprintsFamily extends $Family
    with
        $ClassFamilyOverride<
          Footprints,
          AsyncValue<ListPages<Footprint>>,
          ListPages<Footprint>,
          FutureOr<ListPages<Footprint>>,
          FootprintKind
        > {
  FootprintsFamily._()
    : super(
        retry: null,
        name: r'footprintsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 足迹的一个分栏, 按最近看过排序.

  FootprintsProvider call(FootprintKind kind) =>
      FootprintsProvider._(argument: kind, from: this);

  @override
  String toString() => r'footprintsProvider';
}

/// 足迹的一个分栏, 按最近看过排序.

abstract class _$Footprints extends $AsyncNotifier<ListPages<Footprint>> {
  late final _$args = ref.$arg as FootprintKind;
  FootprintKind get kind => _$args;

  FutureOr<ListPages<Footprint>> build(FootprintKind kind);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<ListPages<Footprint>>, ListPages<Footprint>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ListPages<Footprint>>,
                ListPages<Footprint>
              >,
              AsyncValue<ListPages<Footprint>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// 本人的等级进度. 每次打开等级页重新请求.
///
/// 等级与 "我的" 舞台上的不一致时 (如今天刚升级), 刷新本人的公开资料.

@ProviderFor(growthProgress)
final growthProgressProvider = GrowthProgressProvider._();

/// 本人的等级进度. 每次打开等级页重新请求.
///
/// 等级与 "我的" 舞台上的不一致时 (如今天刚升级), 刷新本人的公开资料.

final class GrowthProgressProvider
    extends
        $FunctionalProvider<
          AsyncValue<GrowthProgress>,
          GrowthProgress,
          FutureOr<GrowthProgress>
        >
    with $FutureModifier<GrowthProgress>, $FutureProvider<GrowthProgress> {
  /// 本人的等级进度. 每次打开等级页重新请求.
  ///
  /// 等级与 "我的" 舞台上的不一致时 (如今天刚升级), 刷新本人的公开资料.
  GrowthProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'growthProgressProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$growthProgressHash();

  @$internal
  @override
  $FutureProviderElement<GrowthProgress> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GrowthProgress> create(Ref ref) {
    return growthProgress(ref);
  }
}

String _$growthProgressHash() => r'b773ed2deb0f47ca409fe8da9b66a4c028c51ee5';

/// 本人的经验明细, 按入账时间倒序.

@ProviderFor(ExperienceLedger)
final experienceLedgerProvider = ExperienceLedgerProvider._();

/// 本人的经验明细, 按入账时间倒序.
final class ExperienceLedgerProvider
    extends
        $AsyncNotifierProvider<ExperienceLedger, ListPages<ExperienceEntry>> {
  /// 本人的经验明细, 按入账时间倒序.
  ExperienceLedgerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'experienceLedgerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$experienceLedgerHash();

  @$internal
  @override
  ExperienceLedger create() => ExperienceLedger();
}

String _$experienceLedgerHash() => r'aceb0598009563ec59fd3ae3f6202138007c52eb';

/// 本人的经验明细, 按入账时间倒序.

abstract class _$ExperienceLedger
    extends $AsyncNotifier<ListPages<ExperienceEntry>> {
  FutureOr<ListPages<ExperienceEntry>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<ListPages<ExperienceEntry>>,
              ListPages<ExperienceEntry>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ListPages<ExperienceEntry>>,
                ListPages<ExperienceEntry>
              >,
              AsyncValue<ListPages<ExperienceEntry>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 保存资料: 更换头像时先上传头像, 然后保存昵称, 签名和头像.
///
/// 成功后刷新当前用户和 "我的" 的资料. 失败时抛出 [AppFailure].

@ProviderFor(ProfileSaver)
final profileSaverProvider = ProfileSaverProvider._();

/// 保存资料: 更换头像时先上传头像, 然后保存昵称, 签名和头像.
///
/// 成功后刷新当前用户和 "我的" 的资料. 失败时抛出 [AppFailure].
final class ProfileSaverProvider extends $NotifierProvider<ProfileSaver, bool> {
  /// 保存资料: 更换头像时先上传头像, 然后保存昵称, 签名和头像.
  ///
  /// 成功后刷新当前用户和 "我的" 的资料. 失败时抛出 [AppFailure].
  ProfileSaverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileSaverProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileSaverHash();

  @$internal
  @override
  ProfileSaver create() => ProfileSaver();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$profileSaverHash() => r'8cbdac00301ab28866f5d8d2fe223b9bfd9b657c';

/// 保存资料: 更换头像时先上传头像, 然后保存昵称, 签名和头像.
///
/// 成功后刷新当前用户和 "我的" 的资料. 失败时抛出 [AppFailure].

abstract class _$ProfileSaver extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
