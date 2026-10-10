// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_food_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AddFoodViewModel)
final addFoodViewModelProvider = AddFoodViewModelProvider._();

final class AddFoodViewModelProvider
    extends $NotifierProvider<AddFoodViewModel, AddFoodState> {
  AddFoodViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addFoodViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addFoodViewModelHash();

  @$internal
  @override
  AddFoodViewModel create() => AddFoodViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AddFoodState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AddFoodState>(value),
    );
  }
}

String _$addFoodViewModelHash() => r'c9f9e4e61a4e9711e5c135d0213fcecb0d6188de';

abstract class _$AddFoodViewModel extends $Notifier<AddFoodState> {
  AddFoodState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AddFoodState, AddFoodState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AddFoodState, AddFoodState>,
              AddFoodState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
