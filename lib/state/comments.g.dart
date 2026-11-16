// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comments.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 指定菜品的评论列表状态. 菜品详情与全部评论页共用 "最有用" 排序的数据, 详情页仅展示前几条.
///
/// 离开页面后保留 5 分钟.

@ProviderFor(DishComments)
final dishCommentsProvider = DishCommentsFamily._();

/// 指定菜品的评论列表状态. 菜品详情与全部评论页共用 "最有用" 排序的数据, 详情页仅展示前几条.
///
/// 离开页面后保留 5 分钟.
final class DishCommentsProvider
    extends $AsyncNotifierProvider<DishComments, CommentList> {
  /// 指定菜品的评论列表状态. 菜品详情与全部评论页共用 "最有用" 排序的数据, 详情页仅展示前几条.
  ///
  /// 离开页面后保留 5 分钟.
  DishCommentsProvider._({
    required DishCommentsFamily super.from,
    required (int, CommentSort) super.argument,
  }) : super(
         retry: null,
         name: r'dishCommentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dishCommentsHash();

  @override
  String toString() {
    return r'dishCommentsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  DishComments create() => DishComments();

  @override
  bool operator ==(Object other) {
    return other is DishCommentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dishCommentsHash() => r'a7a6cc77d6320ee42700d6b34e96939b453ef7e1';

/// 指定菜品的评论列表状态. 菜品详情与全部评论页共用 "最有用" 排序的数据, 详情页仅展示前几条.
///
/// 离开页面后保留 5 分钟.

final class DishCommentsFamily extends $Family
    with
        $ClassFamilyOverride<
          DishComments,
          AsyncValue<CommentList>,
          CommentList,
          FutureOr<CommentList>,
          (int, CommentSort)
        > {
  DishCommentsFamily._()
    : super(
        retry: null,
        name: r'dishCommentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 指定菜品的评论列表状态. 菜品详情与全部评论页共用 "最有用" 排序的数据, 详情页仅展示前几条.
  ///
  /// 离开页面后保留 5 分钟.

  DishCommentsProvider call(int dishId, CommentSort sort) =>
      DishCommentsProvider._(argument: (dishId, sort), from: this);

  @override
  String toString() => r'dishCommentsProvider';
}

/// 指定菜品的评论列表状态. 菜品详情与全部评论页共用 "最有用" 排序的数据, 详情页仅展示前几条.
///
/// 离开页面后保留 5 分钟.

abstract class _$DishComments extends $AsyncNotifier<CommentList> {
  late final _$args = ref.$arg as (int, CommentSort);
  int get dishId => _$args.$1;
  CommentSort get sort => _$args.$2;

  FutureOr<CommentList> build(int dishId, CommentSort sort);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CommentList>, CommentList>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CommentList>, CommentList>,
              AsyncValue<CommentList>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

/// 单条评论下的回复列表状态, 按时间正序分页加载, 每页 20 条.

@ProviderFor(CommentReplies)
final commentRepliesProvider = CommentRepliesFamily._();

/// 单条评论下的回复列表状态, 按时间正序分页加载, 每页 20 条.
final class CommentRepliesProvider
    extends $AsyncNotifierProvider<CommentReplies, CommentList> {
  /// 单条评论下的回复列表状态, 按时间正序分页加载, 每页 20 条.
  CommentRepliesProvider._({
    required CommentRepliesFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'commentRepliesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$commentRepliesHash();

  @override
  String toString() {
    return r'commentRepliesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CommentReplies create() => CommentReplies();

  @override
  bool operator ==(Object other) {
    return other is CommentRepliesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$commentRepliesHash() => r'9cb593f31113c0f0312050d0dc66f1fb5949f31b';

/// 单条评论下的回复列表状态, 按时间正序分页加载, 每页 20 条.

final class CommentRepliesFamily extends $Family
    with
        $ClassFamilyOverride<
          CommentReplies,
          AsyncValue<CommentList>,
          CommentList,
          FutureOr<CommentList>,
          int
        > {
  CommentRepliesFamily._()
    : super(
        retry: null,
        name: r'commentRepliesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 单条评论下的回复列表状态, 按时间正序分页加载, 每页 20 条.

  CommentRepliesProvider call(int commentId) =>
      CommentRepliesProvider._(argument: commentId, from: this);

  @override
  String toString() => r'commentRepliesProvider';
}

/// 单条评论下的回复列表状态, 按时间正序分页加载, 每页 20 条.

abstract class _$CommentReplies extends $AsyncNotifier<CommentList> {
  late final _$args = ref.$arg as int;
  int get commentId => _$args;

  FutureOr<CommentList> build(int commentId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CommentList>, CommentList>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CommentList>, CommentList>,
              AsyncValue<CommentList>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// 评论与回复的写操作管理器, 在发表或删除成功后同步更新已加载的列表并刷新 "我的评论".

@ProviderFor(CommentWriter)
final commentWriterProvider = CommentWriterProvider._();

/// 评论与回复的写操作管理器, 在发表或删除成功后同步更新已加载的列表并刷新 "我的评论".
final class CommentWriterProvider
    extends $NotifierProvider<CommentWriter, void> {
  /// 评论与回复的写操作管理器, 在发表或删除成功后同步更新已加载的列表并刷新 "我的评论".
  CommentWriterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'commentWriterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$commentWriterHash();

  @$internal
  @override
  CommentWriter create() => CommentWriter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$commentWriterHash() => r'bb4ed516ccf84b9f76dc6cc4d4b98a7105e790f5';

/// 评论与回复的写操作管理器, 在发表或删除成功后同步更新已加载的列表并刷新 "我的评论".

abstract class _$CommentWriter extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 评论赞的本地覆盖值, 以评论 id 为键, 用于乐观更新. 切换账号时清空.
///
/// 菜品详情和全部评论显示同一条评论时同步变化.

@ProviderFor(CommentLikes)
final commentLikesProvider = CommentLikesProvider._();

/// 评论赞的本地覆盖值, 以评论 id 为键, 用于乐观更新. 切换账号时清空.
///
/// 菜品详情和全部评论显示同一条评论时同步变化.
final class CommentLikesProvider
    extends $NotifierProvider<CommentLikes, Map<int, CommentLike>> {
  /// 评论赞的本地覆盖值, 以评论 id 为键, 用于乐观更新. 切换账号时清空.
  ///
  /// 菜品详情和全部评论显示同一条评论时同步变化.
  CommentLikesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'commentLikesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$commentLikesHash();

  @$internal
  @override
  CommentLikes create() => CommentLikes();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<int, CommentLike> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<int, CommentLike>>(value),
    );
  }
}

String _$commentLikesHash() => r'502070c72b7917ca2bb424bfdf666aadb8c3b754';

/// 评论赞的本地覆盖值, 以评论 id 为键, 用于乐观更新. 切换账号时清空.
///
/// 菜品详情和全部评论显示同一条评论时同步变化.

abstract class _$CommentLikes extends $Notifier<Map<int, CommentLike>> {
  Map<int, CommentLike> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Map<int, CommentLike>, Map<int, CommentLike>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<int, CommentLike>, Map<int, CommentLike>>,
              Map<int, CommentLike>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// "我的" 页面中的个人评论与回复列表 (不含已删除记录).
///
/// 由于 "我的" 是常驻主页面, 切换到其他主页面后保留当前结果, 仅在发表或删除后重新请求.

@ProviderFor(MyComments)
final myCommentsProvider = MyCommentsProvider._();

/// "我的" 页面中的个人评论与回复列表 (不含已删除记录).
///
/// 由于 "我的" 是常驻主页面, 切换到其他主页面后保留当前结果, 仅在发表或删除后重新请求.
final class MyCommentsProvider
    extends $AsyncNotifierProvider<MyComments, CommentFeed> {
  /// "我的" 页面中的个人评论与回复列表 (不含已删除记录).
  ///
  /// 由于 "我的" 是常驻主页面, 切换到其他主页面后保留当前结果, 仅在发表或删除后重新请求.
  MyCommentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myCommentsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myCommentsHash();

  @$internal
  @override
  MyComments create() => MyComments();
}

String _$myCommentsHash() => r'f51ca02a6bda79a7668712e1c080c9a62be253e3';

/// "我的" 页面中的个人评论与回复列表 (不含已删除记录).
///
/// 由于 "我的" 是常驻主页面, 切换到其他主页面后保留当前结果, 仅在发表或删除后重新请求.

abstract class _$MyComments extends $AsyncNotifier<CommentFeed> {
  FutureOr<CommentFeed> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CommentFeed>, CommentFeed>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CommentFeed>, CommentFeed>,
              AsyncValue<CommentFeed>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 获取 "我的评论" 单条记录关联的菜品信息, 优先读取本地缓存, 缺失时再请求详情接口.
///
/// 由于评论记录仅包含菜品 id, 需额外获取菜名与缩略图; 离开页面后缓存保留 5 分钟.

@ProviderFor(commentedDish)
final commentedDishProvider = CommentedDishFamily._();

/// 获取 "我的评论" 单条记录关联的菜品信息, 优先读取本地缓存, 缺失时再请求详情接口.
///
/// 由于评论记录仅包含菜品 id, 需额外获取菜名与缩略图; 离开页面后缓存保留 5 分钟.

final class CommentedDishProvider
    extends $FunctionalProvider<AsyncValue<Dish>, Dish, FutureOr<Dish>>
    with $FutureModifier<Dish>, $FutureProvider<Dish> {
  /// 获取 "我的评论" 单条记录关联的菜品信息, 优先读取本地缓存, 缺失时再请求详情接口.
  ///
  /// 由于评论记录仅包含菜品 id, 需额外获取菜名与缩略图; 离开页面后缓存保留 5 分钟.
  CommentedDishProvider._({
    required CommentedDishFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'commentedDishProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$commentedDishHash();

  @override
  String toString() {
    return r'commentedDishProvider'
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
    return commentedDish(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CommentedDishProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$commentedDishHash() => r'3945376e7d4d2e104e2a9d52572bca11d7ca0f43';

/// 获取 "我的评论" 单条记录关联的菜品信息, 优先读取本地缓存, 缺失时再请求详情接口.
///
/// 由于评论记录仅包含菜品 id, 需额外获取菜名与缩略图; 离开页面后缓存保留 5 分钟.

final class CommentedDishFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Dish>, int> {
  CommentedDishFamily._()
    : super(
        retry: null,
        name: r'commentedDishProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 获取 "我的评论" 单条记录关联的菜品信息, 优先读取本地缓存, 缺失时再请求详情接口.
  ///
  /// 由于评论记录仅包含菜品 id, 需额外获取菜名与缩略图; 离开页面后缓存保留 5 分钟.

  CommentedDishProvider call(int dishId) =>
      CommentedDishProvider._(argument: dishId, from: this);

  @override
  String toString() => r'commentedDishProvider';
}
