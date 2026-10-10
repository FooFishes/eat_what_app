// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_info_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProfileInfoViewModel)
final profileInfoViewModelProvider = ProfileInfoViewModelProvider._();

final class ProfileInfoViewModelProvider
    extends $NotifierProvider<ProfileInfoViewModel, ProfileInfoState> {
  ProfileInfoViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileInfoViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileInfoViewModelHash();

  @$internal
  @override
  ProfileInfoViewModel create() => ProfileInfoViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileInfoState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileInfoState>(value),
    );
  }
}

String _$profileInfoViewModelHash() =>
    r'b39ef135357b778a601dd3d3bc3f94ede55331a7';

abstract class _$ProfileInfoViewModel extends $Notifier<ProfileInfoState> {
  ProfileInfoState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ProfileInfoState, ProfileInfoState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProfileInfoState, ProfileInfoState>,
              ProfileInfoState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
