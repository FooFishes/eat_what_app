// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topic_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 获取指定专题详情, 若专题不存在或尚未开始则返回 null.
///
/// 由于往期专题列表每行也会读取该详情以展示前三道菜, 缓存 5 分钟后从列表进入专题页时无需重复请求.

@ProviderFor(topicDetail)
final topicDetailProvider = TopicDetailFamily._();

/// 获取指定专题详情, 若专题不存在或尚未开始则返回 null.
///
/// 由于往期专题列表每行也会读取该详情以展示前三道菜, 缓存 5 分钟后从列表进入专题页时无需重复请求.

final class TopicDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<TopicDetail?>,
          TopicDetail?,
          FutureOr<TopicDetail?>
        >
    with $FutureModifier<TopicDetail?>, $FutureProvider<TopicDetail?> {
  /// 获取指定专题详情, 若专题不存在或尚未开始则返回 null.
  ///
  /// 由于往期专题列表每行也会读取该详情以展示前三道菜, 缓存 5 分钟后从列表进入专题页时无需重复请求.
  TopicDetailProvider._({
    required TopicDetailFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'topicDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$topicDetailHash();

  @override
  String toString() {
    return r'topicDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TopicDetail?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TopicDetail?> create(Ref ref) {
    final argument = this.argument as int;
    return topicDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TopicDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$topicDetailHash() => r'f9f157f304ffb4d256a131f8419c404ed9687362';

/// 获取指定专题详情, 若专题不存在或尚未开始则返回 null.
///
/// 由于往期专题列表每行也会读取该详情以展示前三道菜, 缓存 5 分钟后从列表进入专题页时无需重复请求.

final class TopicDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TopicDetail?>, int> {
  TopicDetailFamily._()
    : super(
        retry: null,
        name: r'topicDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 获取指定专题详情, 若专题不存在或尚未开始则返回 null.
  ///
  /// 由于往期专题列表每行也会读取该详情以展示前三道菜, 缓存 5 分钟后从列表进入专题页时无需重复请求.

  TopicDetailProvider call(int topicId) =>
      TopicDetailProvider._(argument: topicId, from: this);

  @override
  String toString() => r'topicDetailProvider';
}

/// 当前校区的往期专题分页列表, 支持触底加载下一页, 切换校区时自动重新请求.

@ProviderFor(TopicArchive)
final topicArchiveProvider = TopicArchiveProvider._();

/// 当前校区的往期专题分页列表, 支持触底加载下一页, 切换校区时自动重新请求.
final class TopicArchiveProvider
    extends $AsyncNotifierProvider<TopicArchive, TopicArchivePages> {
  /// 当前校区的往期专题分页列表, 支持触底加载下一页, 切换校区时自动重新请求.
  TopicArchiveProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'topicArchiveProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$topicArchiveHash();

  @$internal
  @override
  TopicArchive create() => TopicArchive();
}

String _$topicArchiveHash() => r'5ccd06c5485d5cf43eeac35b48b9084962b954de';

/// 当前校区的往期专题分页列表, 支持触底加载下一页, 切换校区时自动重新请求.

abstract class _$TopicArchive extends $AsyncNotifier<TopicArchivePages> {
  FutureOr<TopicArchivePages> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<TopicArchivePages>, TopicArchivePages>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TopicArchivePages>, TopicArchivePages>,
              AsyncValue<TopicArchivePages>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
