// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_restaurant_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AddRestaurantViewModel)
final addRestaurantViewModelProvider = AddRestaurantViewModelProvider._();

final class AddRestaurantViewModelProvider
    extends $NotifierProvider<AddRestaurantViewModel, AddRestaurantState> {
  AddRestaurantViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addRestaurantViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addRestaurantViewModelHash();

  @$internal
  @override
  AddRestaurantViewModel create() => AddRestaurantViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AddRestaurantState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AddRestaurantState>(value),
    );
  }
}

String _$addRestaurantViewModelHash() =>
    r'3b80d52644edb6b5facfc2aa7c8c8ff2f1be420c';

abstract class _$AddRestaurantViewModel extends $Notifier<AddRestaurantState> {
  AddRestaurantState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AddRestaurantState, AddRestaurantState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AddRestaurantState, AddRestaurantState>,
              AddRestaurantState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
