// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deep_links.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(linkSource)
final linkSourceProvider = LinkSourceProvider._();

final class LinkSourceProvider
    extends $FunctionalProvider<LinkSource, LinkSource, LinkSource>
    with $Provider<LinkSource> {
  LinkSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'linkSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$linkSourceHash();

  @$internal
  @override
  $ProviderElement<LinkSource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LinkSource create(Ref ref) {
    return linkSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LinkSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LinkSource>(value),
    );
  }
}

String _$linkSourceHash() => r'ba078e7094f13e70a7a3acf6b14bd513515328f0';
