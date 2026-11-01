// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(uploadClient)
final uploadClientProvider = UploadClientProvider._();

final class UploadClientProvider
    extends $FunctionalProvider<UploadClient, UploadClient, UploadClient>
    with $Provider<UploadClient> {
  UploadClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'uploadClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$uploadClientHash();

  @$internal
  @override
  $ProviderElement<UploadClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UploadClient create(Ref ref) {
    return uploadClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UploadClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UploadClient>(value),
    );
  }
}

String _$uploadClientHash() => r'0e93e1368bfef6258e1c5d9409396b66707c2605';
