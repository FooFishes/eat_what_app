// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_page_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(uploadRawClient)
final uploadRawClientProvider = UploadRawClientProvider._();

final class UploadRawClientProvider
    extends $FunctionalProvider<RequestClient, RequestClient, RequestClient>
    with $Provider<RequestClient> {
  UploadRawClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'uploadRawClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$uploadRawClientHash();

  @$internal
  @override
  $ProviderElement<RequestClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RequestClient create(Ref ref) {
    return uploadRawClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RequestClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RequestClient>(value),
    );
  }
}

String _$uploadRawClientHash() => r'3fd597c6c5329f085d6d9889b848e3038aeb9a3e';

@ProviderFor(uploadRepository)
final uploadRepositoryProvider = UploadRepositoryProvider._();

final class UploadRepositoryProvider
    extends
        $FunctionalProvider<
          UploadRepository,
          UploadRepository,
          UploadRepository
        >
    with $Provider<UploadRepository> {
  UploadRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'uploadRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$uploadRepositoryHash();

  @$internal
  @override
  $ProviderElement<UploadRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UploadRepository create(Ref ref) {
    return uploadRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UploadRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UploadRepository>(value),
    );
  }
}

String _$uploadRepositoryHash() => r'1d8d3f00611b4e2bf4b756c688e46c64ebf55fef';

@ProviderFor(UploadPageController)
final uploadPageControllerProvider = UploadPageControllerProvider._();

final class UploadPageControllerProvider
    extends $NotifierProvider<UploadPageController, UploadPageState> {
  UploadPageControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'uploadPageControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$uploadPageControllerHash();

  @$internal
  @override
  UploadPageController create() => UploadPageController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UploadPageState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UploadPageState>(value),
    );
  }
}

String _$uploadPageControllerHash() =>
    r'f440616567c9b06afce69731dfa651a823cb0d35';

abstract class _$UploadPageController extends $Notifier<UploadPageState> {
  UploadPageState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<UploadPageState, UploadPageState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UploadPageState, UploadPageState>,
              UploadPageState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
