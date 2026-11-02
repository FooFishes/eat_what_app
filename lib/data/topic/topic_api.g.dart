// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topic_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(topicApi)
final topicApiProvider = TopicApiProvider._();

final class TopicApiProvider
    extends $FunctionalProvider<TopicApi, TopicApi, TopicApi>
    with $Provider<TopicApi> {
  TopicApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'topicApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$topicApiHash();

  @$internal
  @override
  $ProviderElement<TopicApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TopicApi create(Ref ref) {
    return topicApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TopicApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TopicApi>(value),
    );
  }
}

String _$topicApiHash() => r'8807bbf23f5d59c3652467797e18bfc4fe8f87cc';
