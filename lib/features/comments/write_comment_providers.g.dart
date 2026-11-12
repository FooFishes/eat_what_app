// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'write_comment_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 写评论页的草稿. 照片在发送时上传, 上传过的照片重试时不再上传.

@ProviderFor(CommentComposer)
final commentComposerProvider = CommentComposerFamily._();

/// 写评论页的草稿. 照片在发送时上传, 上传过的照片重试时不再上传.
final class CommentComposerProvider
    extends $NotifierProvider<CommentComposer, Composer> {
  /// 写评论页的草稿. 照片在发送时上传, 上传过的照片重试时不再上传.
  CommentComposerProvider._({
    required CommentComposerFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'commentComposerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$commentComposerHash();

  @override
  String toString() {
    return r'commentComposerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CommentComposer create() => CommentComposer();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Composer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Composer>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CommentComposerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$commentComposerHash() => r'bb43fc1e898221696f9100bcb4cc88bf0f3b7ba4';

/// 写评论页的草稿. 照片在发送时上传, 上传过的照片重试时不再上传.

final class CommentComposerFamily extends $Family
    with
        $ClassFamilyOverride<
          CommentComposer,
          Composer,
          Composer,
          Composer,
          int
        > {
  CommentComposerFamily._()
    : super(
        retry: null,
        name: r'commentComposerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 写评论页的草稿. 照片在发送时上传, 上传过的照片重试时不再上传.

  CommentComposerProvider call(int dishId) =>
      CommentComposerProvider._(argument: dishId, from: this);

  @override
  String toString() => r'commentComposerProvider';
}

/// 写评论页的草稿. 照片在发送时上传, 上传过的照片重试时不再上传.

abstract class _$CommentComposer extends $Notifier<Composer> {
  late final _$args = ref.$arg as int;
  int get dishId => _$args;

  Composer build(int dishId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Composer, Composer>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Composer, Composer>,
              Composer,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
