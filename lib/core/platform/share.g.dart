// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(linkSharer)
final linkSharerProvider = LinkSharerProvider._();

final class LinkSharerProvider
    extends $FunctionalProvider<LinkSharer, LinkSharer, LinkSharer>
    with $Provider<LinkSharer> {
  LinkSharerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'linkSharerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$linkSharerHash();

  @$internal
  @override
  $ProviderElement<LinkSharer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LinkSharer create(Ref ref) {
    return linkSharer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LinkSharer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LinkSharer>(value),
    );
  }
}

String _$linkSharerHash() => r'26d5793f8b1100592ccb89240e4760dc84264bef';
