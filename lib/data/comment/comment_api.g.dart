// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(commentApi)
final commentApiProvider = CommentApiProvider._();

final class CommentApiProvider
    extends $FunctionalProvider<CommentApi, CommentApi, CommentApi>
    with $Provider<CommentApi> {
  CommentApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'commentApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$commentApiHash();

  @$internal
  @override
  $ProviderElement<CommentApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CommentApi create(Ref ref) {
    return commentApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CommentApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CommentApi>(value),
    );
  }
}

String _$commentApiHash() => r'750b72ab1ebc224a7739cf943124115a05c0e5b0';
