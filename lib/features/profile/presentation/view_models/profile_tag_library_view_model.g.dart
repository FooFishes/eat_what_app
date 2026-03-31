// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_tag_library_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProfileTagLibraryViewModel)
final profileTagLibraryViewModelProvider =
    ProfileTagLibraryViewModelProvider._();

final class ProfileTagLibraryViewModelProvider
    extends
        $NotifierProvider<ProfileTagLibraryViewModel, ProfileTagLibraryState> {
  ProfileTagLibraryViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileTagLibraryViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileTagLibraryViewModelHash();

  @$internal
  @override
  ProfileTagLibraryViewModel create() => ProfileTagLibraryViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileTagLibraryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileTagLibraryState>(value),
    );
  }
}

String _$profileTagLibraryViewModelHash() =>
    r'87144d0d129de11a15659d9299d1d5e7bcb55565';

abstract class _$ProfileTagLibraryViewModel
    extends $Notifier<ProfileTagLibraryState> {
  ProfileTagLibraryState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<ProfileTagLibraryState, ProfileTagLibraryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProfileTagLibraryState, ProfileTagLibraryState>,
              ProfileTagLibraryState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
