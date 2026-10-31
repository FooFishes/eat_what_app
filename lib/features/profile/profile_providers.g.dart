// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 我的统计：获赞、上传的菜、粉丝、关注。主页面常驻，切走不重拉（技术架构 10.5）。

@ProviderFor(myProfile)
final myProfileProvider = MyProfileProvider._();

/// 我的统计：获赞、上传的菜、粉丝、关注。主页面常驻，切走不重拉（技术架构 10.5）。

final class MyProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserProfile?>,
          UserProfile?,
          FutureOr<UserProfile?>
        >
    with $FutureModifier<UserProfile?>, $FutureProvider<UserProfile?> {
  /// 我的统计：获赞、上传的菜、粉丝、关注。主页面常驻，切走不重拉（技术架构 10.5）。
  MyProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myProfileProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myProfileHash();

  @$internal
  @override
  $FutureProviderElement<UserProfile?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UserProfile?> create(Ref ref) {
    return myProfile(ref);
  }
}

String _$myProfileHash() => r'6ec712b49570098f8d04e30445e1c6b6a2018f42';

/// 我上传的菜。

@ProviderFor(MyUploads)
final myUploadsProvider = MyUploadsProvider._();

/// 我上传的菜。
final class MyUploadsProvider
    extends $AsyncNotifierProvider<MyUploads, DishPages> {
  /// 我上传的菜。
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

String _$myUploadsHash() => r'bd14e12502a5ca40fea77e50e815efe82e186690';

/// 我上传的菜。

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

/// 我收藏的菜，新收藏的在前。

@ProviderFor(MyFavorites)
final myFavoritesProvider = MyFavoritesProvider._();

/// 我收藏的菜，新收藏的在前。
final class MyFavoritesProvider
    extends $AsyncNotifierProvider<MyFavorites, DishPages> {
  /// 我收藏的菜，新收藏的在前。
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

String _$myFavoritesHash() => r'837ec128d9442a495ef3670fdae00681c4cb4a48';

/// 我收藏的菜，新收藏的在前。

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
