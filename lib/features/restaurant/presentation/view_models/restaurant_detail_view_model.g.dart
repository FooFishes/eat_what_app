// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant_detail_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RestaurantDetailViewModel)
final restaurantDetailViewModelProvider = RestaurantDetailViewModelFamily._();

final class RestaurantDetailViewModelProvider
    extends
        $NotifierProvider<RestaurantDetailViewModel, RestaurantDetailState> {
  RestaurantDetailViewModelProvider._({
    required RestaurantDetailViewModelFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'restaurantDetailViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$restaurantDetailViewModelHash();

  @override
  String toString() {
    return r'restaurantDetailViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RestaurantDetailViewModel create() => RestaurantDetailViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RestaurantDetailState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RestaurantDetailState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RestaurantDetailViewModelProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$restaurantDetailViewModelHash() =>
    r'e619a97cb7d114dcc124489b2db84d4741a46e67';

final class RestaurantDetailViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          RestaurantDetailViewModel,
          RestaurantDetailState,
          RestaurantDetailState,
          RestaurantDetailState,
          int
        > {
  RestaurantDetailViewModelFamily._()
    : super(
        retry: null,
        name: r'restaurantDetailViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RestaurantDetailViewModelProvider call(int restaurantId) =>
      RestaurantDetailViewModelProvider._(argument: restaurantId, from: this);

  @override
  String toString() => r'restaurantDetailViewModelProvider';
}

abstract class _$RestaurantDetailViewModel
    extends $Notifier<RestaurantDetailState> {
  late final _$args = ref.$arg as int;
  int get restaurantId => _$args;

  RestaurantDetailState build(int restaurantId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RestaurantDetailState, RestaurantDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RestaurantDetailState, RestaurantDetailState>,
              RestaurantDetailState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
