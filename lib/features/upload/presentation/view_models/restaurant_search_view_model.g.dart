// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant_search_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RestaurantSearchViewModel)
final restaurantSearchViewModelProvider = RestaurantSearchViewModelProvider._();

final class RestaurantSearchViewModelProvider
    extends
        $NotifierProvider<RestaurantSearchViewModel, RestaurantSearchState> {
  RestaurantSearchViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'restaurantSearchViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$restaurantSearchViewModelHash();

  @$internal
  @override
  RestaurantSearchViewModel create() => RestaurantSearchViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RestaurantSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RestaurantSearchState>(value),
    );
  }
}

String _$restaurantSearchViewModelHash() =>
    r'a204b0d37f57b0d875eb7bbe0d4327c080d615ec';

abstract class _$RestaurantSearchViewModel
    extends $Notifier<RestaurantSearchState> {
  RestaurantSearchState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RestaurantSearchState, RestaurantSearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RestaurantSearchState, RestaurantSearchState>,
              RestaurantSearchState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
