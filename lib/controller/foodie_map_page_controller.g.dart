// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'foodie_map_page_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FoodieMapPageController)
final foodieMapPageControllerProvider = FoodieMapPageControllerProvider._();

final class FoodieMapPageControllerProvider
    extends $NotifierProvider<FoodieMapPageController, FoodieMapPageState> {
  FoodieMapPageControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foodieMapPageControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foodieMapPageControllerHash();

  @$internal
  @override
  FoodieMapPageController create() => FoodieMapPageController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FoodieMapPageState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FoodieMapPageState>(value),
    );
  }
}

String _$foodieMapPageControllerHash() =>
    r'4b451c85798e2be2c11dae069e2892cf93df0186';

abstract class _$FoodieMapPageController extends $Notifier<FoodieMapPageState> {
  FoodieMapPageState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FoodieMapPageState, FoodieMapPageState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FoodieMapPageState, FoodieMapPageState>,
              FoodieMapPageState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(FoodieMapFoodListController)
final foodieMapFoodListControllerProvider =
    FoodieMapFoodListControllerFamily._();

final class FoodieMapFoodListControllerProvider
    extends
        $NotifierProvider<FoodieMapFoodListController, FoodieMapFoodListState> {
  FoodieMapFoodListControllerProvider._({
    required FoodieMapFoodListControllerFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'foodieMapFoodListControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$foodieMapFoodListControllerHash();

  @override
  String toString() {
    return r'foodieMapFoodListControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  FoodieMapFoodListController create() => FoodieMapFoodListController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FoodieMapFoodListState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FoodieMapFoodListState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FoodieMapFoodListControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$foodieMapFoodListControllerHash() =>
    r'f45b2d8ef4f0900e31c32ab898d9e435cec6e7bb';

final class FoodieMapFoodListControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          FoodieMapFoodListController,
          FoodieMapFoodListState,
          FoodieMapFoodListState,
          FoodieMapFoodListState,
          int
        > {
  FoodieMapFoodListControllerFamily._()
    : super(
        retry: null,
        name: r'foodieMapFoodListControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FoodieMapFoodListControllerProvider call(int provinceId) =>
      FoodieMapFoodListControllerProvider._(argument: provinceId, from: this);

  @override
  String toString() => r'foodieMapFoodListControllerProvider';
}

abstract class _$FoodieMapFoodListController
    extends $Notifier<FoodieMapFoodListState> {
  late final _$args = ref.$arg as int;
  int get provinceId => _$args;

  FoodieMapFoodListState build(int provinceId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<FoodieMapFoodListState, FoodieMapFoodListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FoodieMapFoodListState, FoodieMapFoodListState>,
              FoodieMapFoodListState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
