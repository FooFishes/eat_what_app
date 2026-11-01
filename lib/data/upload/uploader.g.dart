// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'uploader.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(uploader)
final uploaderProvider = UploaderProvider._();

final class UploaderProvider
    extends $FunctionalProvider<Uploader, Uploader, Uploader>
    with $Provider<Uploader> {
  UploaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'uploaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$uploaderHash();

  @$internal
  @override
  $ProviderElement<Uploader> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Uploader create(Ref ref) {
    return uploader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Uploader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Uploader>(value),
    );
  }
}

String _$uploaderHash() => r'bf6d7073a1f22540bf989651b7b27b626e043510';
