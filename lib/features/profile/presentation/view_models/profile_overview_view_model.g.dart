// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_overview_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProfileOverviewViewModel)
final profileOverviewViewModelProvider = ProfileOverviewViewModelProvider._();

final class ProfileOverviewViewModelProvider
    extends $NotifierProvider<ProfileOverviewViewModel, ProfileOverviewState> {
  ProfileOverviewViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileOverviewViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileOverviewViewModelHash();

  @$internal
  @override
  ProfileOverviewViewModel create() => ProfileOverviewViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileOverviewState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileOverviewState>(value),
    );
  }
}

String _$profileOverviewViewModelHash() =>
    r'f67329e09f028f890788953004f7e3bea3786a74';

abstract class _$ProfileOverviewViewModel
    extends $Notifier<ProfileOverviewState> {
  ProfileOverviewState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ProfileOverviewState, ProfileOverviewState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProfileOverviewState, ProfileOverviewState>,
              ProfileOverviewState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
