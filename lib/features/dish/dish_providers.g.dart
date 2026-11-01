// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dish_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 菜品详情。拿到最新的就清掉赞和收藏的本地覆盖；拿不到时用 7 天内看过的缓存（技术架构 10.1）。

@ProviderFor(dishDetail)
final dishDetailProvider = DishDetailFamily._();

/// 菜品详情。拿到最新的就清掉赞和收藏的本地覆盖；拿不到时用 7 天内看过的缓存（技术架构 10.1）。

final class DishDetailProvider
    extends $FunctionalProvider<AsyncValue<Dish>, Dish, FutureOr<Dish>>
    with $FutureModifier<Dish>, $FutureProvider<Dish> {
  /// 菜品详情。拿到最新的就清掉赞和收藏的本地覆盖；拿不到时用 7 天内看过的缓存（技术架构 10.1）。
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

String _$dishDetailHash() => r'0e45f82ebcdb10e610570ece7ed4368ecc7aa7a4';

/// 菜品详情。拿到最新的就清掉赞和收藏的本地覆盖；拿不到时用 7 天内看过的缓存（技术架构 10.1）。

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

  /// 菜品详情。拿到最新的就清掉赞和收藏的本地覆盖；拿不到时用 7 天内看过的缓存（技术架构 10.1）。

  DishDetailProvider call(int dishId) =>
      DishDetailProvider._(argument: dishId, from: this);

  @override
  String toString() => r'dishDetailProvider';
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

String _$dishTagsOfHash() => r'3f18f6ca54d78ca5adf91e4f3aff9b4720646922';

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
