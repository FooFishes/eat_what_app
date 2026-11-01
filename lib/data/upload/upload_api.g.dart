// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(uploadApi)
final uploadApiProvider = UploadApiProvider._();

final class UploadApiProvider
    extends $FunctionalProvider<UploadApi, UploadApi, UploadApi>
    with $Provider<UploadApi> {
  UploadApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'uploadApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$uploadApiHash();

  @$internal
  @override
  $ProviderElement<UploadApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UploadApi create(Ref ref) {
    return uploadApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UploadApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UploadApi>(value),
    );
  }
}

String _$uploadApiHash() => r'2224e73e44e471411bff12f95b21930efcb7b026';
