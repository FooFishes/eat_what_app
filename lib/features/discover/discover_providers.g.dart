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
