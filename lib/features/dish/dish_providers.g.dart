// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dish_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 菜品详情.
///
/// 获取到最新数据时清除赞和收藏的本地覆盖值.
/// 网络不可达时使用本地缓存的详情, 没有缓存则抛出失败.
///
/// 发布次数变化时重新请求. 编辑页属于另一个功能, 保存后只能通过发布次数通知详情刷新.

@ProviderFor(dishDetail)
final dishDetailProvider = DishDetailFamily._();

/// 菜品详情.
///
/// 获取到最新数据时清除赞和收藏的本地覆盖值.
/// 网络不可达时使用本地缓存的详情, 没有缓存则抛出失败.
///
/// 发布次数变化时重新请求. 编辑页属于另一个功能, 保存后只能通过发布次数通知详情刷新.

final class DishDetailProvider
    extends $FunctionalProvider<AsyncValue<Dish>, Dish, FutureOr<Dish>>
    with $FutureModifier<Dish>, $FutureProvider<Dish> {
  /// 菜品详情.
  ///
  /// 获取到最新数据时清除赞和收藏的本地覆盖值.
  /// 网络不可达时使用本地缓存的详情, 没有缓存则抛出失败.
  ///
  /// 发布次数变化时重新请求. 编辑页属于另一个功能, 保存后只能通过发布次数通知详情刷新.
  DishDetailProvider._({
    required DishDetailFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'dishDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dishDetailHash();

  @override
  String toString() {
    return r'dishDetailProvider'
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
    return dishDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DishDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dishDetailHash() => r'1e1bdb24474feb6d199038dbf08fc176da5d17f6';

/// 菜品详情.
///
/// 获取到最新数据时清除赞和收藏的本地覆盖值.
/// 网络不可达时使用本地缓存的详情, 没有缓存则抛出失败.
///
/// 发布次数变化时重新请求. 编辑页属于另一个功能, 保存后只能通过发布次数通知详情刷新.

final class DishDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Dish>, int> {
  DishDetailFamily._()
    : super(
        retry: null,
        name: r'dishDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 菜品详情.
  ///
  /// 获取到最新数据时清除赞和收藏的本地覆盖值.
  /// 网络不可达时使用本地缓存的详情, 没有缓存则抛出失败.
  ///
  /// 发布次数变化时重新请求. 编辑页属于另一个功能, 保存后只能通过发布次数通知详情刷新.

  DishDetailProvider call(int dishId) =>
      DishDetailProvider._(argument: dishId, from: this);

  @override
  String toString() => r'dishDetailProvider';
}

/// 一道菜的修改记录, 最新的在前.
///
/// 恢复成功后重新请求修改记录和菜品详情.

@ProviderFor(DishHistory)
final dishHistoryProvider = DishHistoryFamily._();

/// 一道菜的修改记录, 最新的在前.
///
/// 恢复成功后重新请求修改记录和菜品详情.
final class DishHistoryProvider
    extends $AsyncNotifierProvider<DishHistory, DishRevisionPages> {
  /// 一道菜的修改记录, 最新的在前.
  ///
  /// 恢复成功后重新请求修改记录和菜品详情.
  DishHistoryProvider._({
    required DishHistoryFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'dishHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dishHistoryHash();

  @override
  String toString() {
    return r'dishHistoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DishHistory create() => DishHistory();

  @override
  bool operator ==(Object other) {
    return other is DishHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dishHistoryHash() => r'9d8f45471fd4370fb3b6fb2bcc432fa0ed0b3258';

/// 一道菜的修改记录, 最新的在前.
///
/// 恢复成功后重新请求修改记录和菜品详情.

final class DishHistoryFamily extends $Family
    with
        $ClassFamilyOverride<
          DishHistory,
          AsyncValue<DishRevisionPages>,
          DishRevisionPages,
          FutureOr<DishRevisionPages>,
          int
        > {
  DishHistoryFamily._()
    : super(
        retry: null,
        name: r'dishHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 一道菜的修改记录, 最新的在前.
  ///
  /// 恢复成功后重新请求修改记录和菜品详情.

  DishHistoryProvider call(int dishId) =>
      DishHistoryProvider._(argument: dishId, from: this);

  @override
  String toString() => r'dishHistoryProvider';
}

/// 一道菜的修改记录, 最新的在前.
///
/// 恢复成功后重新请求修改记录和菜品详情.

abstract class _$DishHistory extends $AsyncNotifier<DishRevisionPages> {
  late final _$args = ref.$arg as int;
  int get dishId => _$args;

  FutureOr<DishRevisionPages> build(int dishId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<DishRevisionPages>, DishRevisionPages>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DishRevisionPages>, DishRevisionPages>,
              AsyncValue<DishRevisionPages>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(DishTagsOf)
final dishTagsOfProvider = DishTagsOfFamily._();

final class DishTagsOfProvider
    extends $NotifierProvider<DishTagsOf, DishTags?> {
  DishTagsOfProvider._({
    required DishTagsOfFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'dishTagsOfProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dishTagsOfHash();

  @override
  String toString() {
    return r'dishTagsOfProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DishTagsOf create() => DishTagsOf();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DishTags? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DishTags?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DishTagsOfProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dishTagsOfHash() => r'0e1082a8a7077853e71b3e7ef171481bcc49a92b';

final class DishTagsOfFamily extends $Family
    with
        $ClassFamilyOverride<DishTagsOf, DishTags?, DishTags?, DishTags?, int> {
  DishTagsOfFamily._()
    : super(
        retry: null,
        name: r'dishTagsOfProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DishTagsOfProvider call(int dishId) =>
      DishTagsOfProvider._(argument: dishId, from: this);

  @override
  String toString() => r'dishTagsOfProvider';
}

abstract class _$DishTagsOf extends $Notifier<DishTags?> {
  late final _$args = ref.$arg as int;
  int get dishId => _$args;

  DishTags? build(int dishId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DishTags?, DishTags?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DishTags?, DishTags?>,
              DishTags?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
