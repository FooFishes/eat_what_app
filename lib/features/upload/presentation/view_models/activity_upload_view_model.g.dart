// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_upload_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ActivityUploadViewModel)
final activityUploadViewModelProvider = ActivityUploadViewModelProvider._();

final class ActivityUploadViewModelProvider
    extends $NotifierProvider<ActivityUploadViewModel, ActivityUploadState> {
  ActivityUploadViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activityUploadViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activityUploadViewModelHash();

  @$internal
  @override
  ActivityUploadViewModel create() => ActivityUploadViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActivityUploadState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActivityUploadState>(value),
    );
  }
}

String _$activityUploadViewModelHash() =>
    r'92f0ae0e19297922042d9240163f45bdc226cdd7';

abstract class _$ActivityUploadViewModel
    extends $Notifier<ActivityUploadState> {
  ActivityUploadState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ActivityUploadState, ActivityUploadState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ActivityUploadState, ActivityUploadState>,
              ActivityUploadState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
