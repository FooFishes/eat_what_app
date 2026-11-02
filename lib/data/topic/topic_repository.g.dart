// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topic_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(topicRepository)
final topicRepositoryProvider = TopicRepositoryProvider._();

final class TopicRepositoryProvider
    extends
        $FunctionalProvider<TopicRepository, TopicRepository, TopicRepository>
    with $Provider<TopicRepository> {
  TopicRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'topicRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$topicRepositoryHash();

  @$internal
  @override
  $ProviderElement<TopicRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TopicRepository create(Ref ref) {
    return topicRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TopicRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TopicRepository>(value),
    );
  }
}

String _$topicRepositoryHash() => r'5daaabf501a533c383b97d89fbd9154da9e5bfee';
