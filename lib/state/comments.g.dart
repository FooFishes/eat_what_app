// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comments.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 一道菜的评论. 菜品详情和全部评论共用 "最有用" 一组, 菜品详情只显示前几条.
///
/// 离开页面后保留 5 分钟.

@ProviderFor(DishComments)
final dishCommentsProvider = DishCommentsFamily._();

/// 一道菜的评论. 菜品详情和全部评论共用 "最有用" 一组, 菜品详情只显示前几条.
///
/// 离开页面后保留 5 分钟.
final class DishCommentsProvider
    extends $AsyncNotifierProvider<DishComments, CommentList> {
  /// 一道菜的评论. 菜品详情和全部评论共用 "最有用" 一组, 菜品详情只显示前几条.
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

String _$dishCommentsHash() => r'faf5cb0db26a9aec5d4d7afdd79bd56d87341312';

/// 一道菜的评论. 菜品详情和全部评论共用 "最有用" 一组, 菜品详情只显示前几条.
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

  /// 一道菜的评论. 菜品详情和全部评论共用 "最有用" 一组, 菜品详情只显示前几条.
  ///
  /// 离开页面后保留 5 分钟.

  DishCommentsProvider call(int dishId, CommentSort sort) =>
      DishCommentsProvider._(argument: (dishId, sort), from: this);

  @override
  String toString() => r'dishCommentsProvider';
}

/// 一道菜的评论. 菜品详情和全部评论共用 "最有用" 一组, 菜品详情只显示前几条.
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

/// 一条评论下的回复, 每页 20 条, 按时间倒序加载. 显示时由 `CommentRules.chronological` 排成正序.

@ProviderFor(CommentReplies)
final commentRepliesProvider = CommentRepliesFamily._();

/// 一条评论下的回复, 每页 20 条, 按时间倒序加载. 显示时由 `CommentRules.chronological` 排成正序.
final class CommentRepliesProvider
    extends $AsyncNotifierProvider<CommentReplies, CommentList> {
  /// 一条评论下的回复, 每页 20 条, 按时间倒序加载. 显示时由 `CommentRules.chronological` 排成正序.
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

/// 一条评论下的回复, 每页 20 条, 按时间倒序加载. 显示时由 `CommentRules.chronological` 排成正序.

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

  /// 一条评论下的回复, 每页 20 条, 按时间倒序加载. 显示时由 `CommentRules.chronological` 排成正序.

  CommentRepliesProvider call(int commentId) =>
      CommentRepliesProvider._(argument: commentId, from: this);

  @override
  String toString() => r'commentRepliesProvider';
}

/// 一条评论下的回复, 每页 20 条, 按时间倒序加载. 显示时由 `CommentRules.chronological` 排成正序.

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

/// 删除评论和回复. 删除成功后从已加载的各个列表中移除该条目, 并刷新 "我的评论".

@ProviderFor(CommentWriter)
final commentWriterProvider = CommentWriterProvider._();

/// 删除评论和回复. 删除成功后从已加载的各个列表中移除该条目, 并刷新 "我的评论".
final class CommentWriterProvider
    extends $NotifierProvider<CommentWriter, void> {
  /// 删除评论和回复. 删除成功后从已加载的各个列表中移除该条目, 并刷新 "我的评论".
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

String _$commentWriterHash() => r'eaa7da69fa2134f86e39fe3ddb2c36eb5e27fc02';

/// 删除评论和回复. 删除成功后从已加载的各个列表中移除该条目, 并刷新 "我的评论".

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

/// 当前用户对 [commentId] 的赞. 未登录, 封禁中或请求失败时为 null, 界面按未赞过显示列表中的赞数.
///
/// 受限会话不能调用查询赞的接口, 调用会返回无权限并触发账号状态刷新, 因此封禁中不请求.

@ProviderFor(commentLikeOf)
final commentLikeOfProvider = CommentLikeOfFamily._();

/// 当前用户对 [commentId] 的赞. 未登录, 封禁中或请求失败时为 null, 界面按未赞过显示列表中的赞数.
///
/// 受限会话不能调用查询赞的接口, 调用会返回无权限并触发账号状态刷新, 因此封禁中不请求.

final class CommentLikeOfProvider
    extends
        $FunctionalProvider<
          AsyncValue<CommentLike?>,
          CommentLike?,
          FutureOr<CommentLike?>
        >
    with $FutureModifier<CommentLike?>, $FutureProvider<CommentLike?> {
  /// 当前用户对 [commentId] 的赞. 未登录, 封禁中或请求失败时为 null, 界面按未赞过显示列表中的赞数.
  ///
  /// 受限会话不能调用查询赞的接口, 调用会返回无权限并触发账号状态刷新, 因此封禁中不请求.
  CommentLikeOfProvider._({
    required CommentLikeOfFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'commentLikeOfProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$commentLikeOfHash();

  @override
  String toString() {
    return r'commentLikeOfProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CommentLike?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CommentLike?> create(Ref ref) {
    final argument = this.argument as int;
    return commentLikeOf(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CommentLikeOfProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$commentLikeOfHash() => r'ad50778f99269107dfcc09f2b79c78983464399e';

/// 当前用户对 [commentId] 的赞. 未登录, 封禁中或请求失败时为 null, 界面按未赞过显示列表中的赞数.
///
/// 受限会话不能调用查询赞的接口, 调用会返回无权限并触发账号状态刷新, 因此封禁中不请求.

final class CommentLikeOfFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CommentLike?>, int> {
  CommentLikeOfFamily._()
    : super(
        retry: null,
        name: r'commentLikeOfProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 当前用户对 [commentId] 的赞. 未登录, 封禁中或请求失败时为 null, 界面按未赞过显示列表中的赞数.
  ///
  /// 受限会话不能调用查询赞的接口, 调用会返回无权限并触发账号状态刷新, 因此封禁中不请求.

  CommentLikeOfProvider call(int commentId) =>
      CommentLikeOfProvider._(argument: commentId, from: this);

  @override
  String toString() => r'commentLikeOfProvider';
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

String _$commentLikesHash() => r'94e51e9510009f05991aa9d53d8ab432221efdb6';

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

/// 当前用户写过的评论和回复的 id, 用于在 "更多" 中显示 "删除" 还是 "举报".
///
/// 取 "我的评论" 最近 100 条. 本次启动后发表的评论在发表成功时加入.

@ProviderFor(MyCommentIds)
final myCommentIdsProvider = MyCommentIdsProvider._();

/// 当前用户写过的评论和回复的 id, 用于在 "更多" 中显示 "删除" 还是 "举报".
///
/// 取 "我的评论" 最近 100 条. 本次启动后发表的评论在发表成功时加入.
final class MyCommentIdsProvider
    extends $AsyncNotifierProvider<MyCommentIds, Set<int>> {
  /// 当前用户写过的评论和回复的 id, 用于在 "更多" 中显示 "删除" 还是 "举报".
  ///
  /// 取 "我的评论" 最近 100 条. 本次启动后发表的评论在发表成功时加入.
  MyCommentIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myCommentIdsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myCommentIdsHash();

  @$internal
  @override
  MyCommentIds create() => MyCommentIds();
}

String _$myCommentIdsHash() => r'1c68b1ab8574092688a7a8746d98f34ec94e955f';

/// 当前用户写过的评论和回复的 id, 用于在 "更多" 中显示 "删除" 还是 "举报".
///
/// 取 "我的评论" 最近 100 条. 本次启动后发表的评论在发表成功时加入.

abstract class _$MyCommentIds extends $AsyncNotifier<Set<int>> {
  FutureOr<Set<int>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Set<int>>, Set<int>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Set<int>>, Set<int>>,
              AsyncValue<Set<int>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// "我的" 中的评论分栏: 我写过的评论和回复, 不含已删除和被新版本取代的.
///
/// "我的" 是常驻的主页面, 切换到其他主页面后保留结果. 发表和删除后重新请求.

@ProviderFor(MyComments)
final myCommentsProvider = MyCommentsProvider._();

/// "我的" 中的评论分栏: 我写过的评论和回复, 不含已删除和被新版本取代的.
///
/// "我的" 是常驻的主页面, 切换到其他主页面后保留结果. 发表和删除后重新请求.
final class MyCommentsProvider
    extends $AsyncNotifierProvider<MyComments, CommentFeed> {
  /// "我的" 中的评论分栏: 我写过的评论和回复, 不含已删除和被新版本取代的.
  ///
  /// "我的" 是常驻的主页面, 切换到其他主页面后保留结果. 发表和删除后重新请求.
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

String _$myCommentsHash() => r'e818efaaa17f94f3dccb49eb2fb8c620b9d2423e';

/// "我的" 中的评论分栏: 我写过的评论和回复, 不含已删除和被新版本取代的.
///
/// "我的" 是常驻的主页面, 切换到其他主页面后保留结果. 发表和删除后重新请求.

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

/// "我的评论" 一行要显示的菜: 先用本地缓存的详情, 没有缓存时请求.
///
/// 评论记录只带菜的 id, 菜名和缩略图要另外获取. 离开页面后保留 5 分钟.

@ProviderFor(commentedDish)
final commentedDishProvider = CommentedDishFamily._();

/// "我的评论" 一行要显示的菜: 先用本地缓存的详情, 没有缓存时请求.
///
/// 评论记录只带菜的 id, 菜名和缩略图要另外获取. 离开页面后保留 5 分钟.

final class CommentedDishProvider
    extends $FunctionalProvider<AsyncValue<Dish>, Dish, FutureOr<Dish>>
    with $FutureModifier<Dish>, $FutureProvider<Dish> {
  /// "我的评论" 一行要显示的菜: 先用本地缓存的详情, 没有缓存时请求.
  ///
  /// 评论记录只带菜的 id, 菜名和缩略图要另外获取. 离开页面后保留 5 分钟.
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

/// "我的评论" 一行要显示的菜: 先用本地缓存的详情, 没有缓存时请求.
///
/// 评论记录只带菜的 id, 菜名和缩略图要另外获取. 离开页面后保留 5 分钟.

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

  /// "我的评论" 一行要显示的菜: 先用本地缓存的详情, 没有缓存时请求.
  ///
  /// 评论记录只带菜的 id, 菜名和缩略图要另外获取. 离开页面后保留 5 分钟.

  CommentedDishProvider call(int dishId) =>
      CommentedDishProvider._(argument: dishId, from: this);

  @override
  String toString() => r'commentedDishProvider';
}
