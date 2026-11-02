// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discover_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 发现页的转盘队列. 地点或饭点变化时重新请求.

@ProviderFor(TurntableQueue)
final turntableQueueProvider = TurntableQueueProvider._();

/// 发现页的转盘队列. 地点或饭点变化时重新请求.
final class TurntableQueueProvider
    extends $AsyncNotifierProvider<TurntableQueue, TurntableFeed> {
  /// 发现页的转盘队列. 地点或饭点变化时重新请求.
  TurntableQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'turntableQueueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$turntableQueueHash();

  @$internal
  @override
  TurntableQueue create() => TurntableQueue();
}

String _$turntableQueueHash() => r'e7f5a7717f0c12e36440f462c231845775358a82';

/// 发现页的转盘队列. 地点或饭点变化时重新请求.

abstract class _$TurntableQueue extends $AsyncNotifier<TurntableFeed> {
  FutureOr<TurntableFeed> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<TurntableFeed>, TurntableFeed>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TurntableFeed>, TurntableFeed>,
              AsyncValue<TurntableFeed>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 当前校区的当期专题, 没有时为 null. 切换校区后重新请求, 回到前台时由页面刷新.
///
/// 分类栏只在有当期专题时显示专题. 请求失败时页面按没有专题处理, 不影响推荐.

@ProviderFor(currentTopic)
final currentTopicProvider = CurrentTopicProvider._();

/// 当前校区的当期专题, 没有时为 null. 切换校区后重新请求, 回到前台时由页面刷新.
///
/// 分类栏只在有当期专题时显示专题. 请求失败时页面按没有专题处理, 不影响推荐.

final class CurrentTopicProvider
    extends $FunctionalProvider<AsyncValue<Topic?>, Topic?, FutureOr<Topic?>>
    with $FutureModifier<Topic?>, $FutureProvider<Topic?> {
  /// 当前校区的当期专题, 没有时为 null. 切换校区后重新请求, 回到前台时由页面刷新.
  ///
  /// 分类栏只在有当期专题时显示专题. 请求失败时页面按没有专题处理, 不影响推荐.
  CurrentTopicProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentTopicProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentTopicHash();

  @$internal
  @override
  $FutureProviderElement<Topic?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Topic?> create(Ref ref) {
    return currentTopic(ref);
  }
}

String _$currentTopicHash() => r'47595d2bb0284157897ee260e7682a5f4797f2e4';

/// 分类栏选中专题时抽屉中的专题详情. 专题已撤下或尚未开始时为 null.

@ProviderFor(discoverTopic)
final discoverTopicProvider = DiscoverTopicFamily._();

/// 分类栏选中专题时抽屉中的专题详情. 专题已撤下或尚未开始时为 null.

final class DiscoverTopicProvider
    extends
        $FunctionalProvider<
          AsyncValue<TopicDetail?>,
          TopicDetail?,
          FutureOr<TopicDetail?>
        >
    with $FutureModifier<TopicDetail?>, $FutureProvider<TopicDetail?> {
  /// 分类栏选中专题时抽屉中的专题详情. 专题已撤下或尚未开始时为 null.
  DiscoverTopicProvider._({
    required DiscoverTopicFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'discoverTopicProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$discoverTopicHash();

  @override
  String toString() {
    return r'discoverTopicProvider'
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
    return discoverTopic(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DiscoverTopicProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$discoverTopicHash() => r'427102700df8e129a92ba2b2b241643636bd4948';

/// 分类栏选中专题时抽屉中的专题详情. 专题已撤下或尚未开始时为 null.

final class DiscoverTopicFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TopicDetail?>, int> {
  DiscoverTopicFamily._()
    : super(
        retry: null,
        name: r'discoverTopicProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 分类栏选中专题时抽屉中的专题详情. 专题已撤下或尚未开始时为 null.

  DiscoverTopicProvider call(int topicId) =>
      DiscoverTopicProvider._(argument: topicId, from: this);

  @override
  String toString() => r'discoverTopicProvider';
}

@ProviderFor(DiscoverList)
final discoverListProvider = DiscoverListFamily._();

final class DiscoverListProvider
    extends $AsyncNotifierProvider<DiscoverList, DishFeed> {
  DiscoverListProvider._({
    required DiscoverListFamily super.from,
    required DishCategory? super.argument,
  }) : super(
         retry: null,
         name: r'discoverListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$discoverListHash();

  @override
  String toString() {
    return r'discoverListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DiscoverList create() => DiscoverList();

  @override
  bool operator ==(Object other) {
    return other is DiscoverListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$discoverListHash() => r'fd7080bd9b616c7b879285902b2c2e276edcb1cc';

final class DiscoverListFamily extends $Family
    with
        $ClassFamilyOverride<
          DiscoverList,
          AsyncValue<DishFeed>,
          DishFeed,
          FutureOr<DishFeed>,
          DishCategory?
        > {
  DiscoverListFamily._()
    : super(
        retry: null,
        name: r'discoverListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DiscoverListProvider call(DishCategory? category) =>
      DiscoverListProvider._(argument: category, from: this);

  @override
  String toString() => r'discoverListProvider';
}

abstract class _$DiscoverList extends $AsyncNotifier<DishFeed> {
  late final _$args = ref.$arg as DishCategory?;
  DishCategory? get category => _$args;

  FutureOr<DishFeed> build(DishCategory? category);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DishFeed>, DishFeed>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DishFeed>, DishFeed>,
              AsyncValue<DishFeed>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
