// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'foodie_map_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FoodieMapViewModel)
final foodieMapViewModelProvider = FoodieMapViewModelProvider._();

final class FoodieMapViewModelProvider
    extends $NotifierProvider<FoodieMapViewModel, FoodieMapPageState> {
  FoodieMapViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foodieMapViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foodieMapViewModelHash();

  @$internal
  @override
  FoodieMapViewModel create() => FoodieMapViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FoodieMapPageState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FoodieMapPageState>(value),
    );
  }
}

String _$foodieMapViewModelHash() =>
    r'34eb2e46bcda18a571093699880bf2395298b408';

abstract class _$FoodieMapViewModel extends $Notifier<FoodieMapPageState> {
  FoodieMapPageState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FoodieMapPageState, FoodieMapPageState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FoodieMapPageState, FoodieMapPageState>,
              FoodieMapPageState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(FoodieMapFoodListViewModel)
final foodieMapFoodListViewModelProvider = FoodieMapFoodListViewModelFamily._();

final class FoodieMapFoodListViewModelProvider
    extends
        $NotifierProvider<FoodieMapFoodListViewModel, FoodieMapFoodListState> {
  FoodieMapFoodListViewModelProvider._({
    required FoodieMapFoodListViewModelFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'foodieMapFoodListViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$foodieMapFoodListViewModelHash();

  @override
  String toString() {
    return r'foodieMapFoodListViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  FoodieMapFoodListViewModel create() => FoodieMapFoodListViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FoodieMapFoodListState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FoodieMapFoodListState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FoodieMapFoodListViewModelProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$foodieMapFoodListViewModelHash() =>
    r'959d35ea42c129348404ee3387d017a53b60958c';

final class FoodieMapFoodListViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          FoodieMapFoodListViewModel,
          FoodieMapFoodListState,
          FoodieMapFoodListState,
          FoodieMapFoodListState,
          int
        > {
  FoodieMapFoodListViewModelFamily._()
    : super(
        retry: null,
        name: r'foodieMapFoodListViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FoodieMapFoodListViewModelProvider call(int provinceId) =>
      FoodieMapFoodListViewModelProvider._(argument: provinceId, from: this);

  @override
  String toString() => r'foodieMapFoodListViewModelProvider';
}

abstract class _$FoodieMapFoodListViewModel
    extends $Notifier<FoodieMapFoodListState> {
  late final _$args = ref.$arg as int;
  int get provinceId => _$args;

  FoodieMapFoodListState build(int provinceId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
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
    return element.handleCreate(ref, () => build(_$args));
  }
}
