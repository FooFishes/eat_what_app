// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'write_comment_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 写评论页草稿状态管理器. 照片在提交时上传, 发送失败后重试时已上传成功的照片会复用存储 key 而不重复上传.

@ProviderFor(CommentComposer)
final commentComposerProvider = CommentComposerFamily._();

/// 写评论页草稿状态管理器. 照片在提交时上传, 发送失败后重试时已上传成功的照片会复用存储 key 而不重复上传.
final class CommentComposerProvider
    extends $NotifierProvider<CommentComposer, Composer> {
  /// 写评论页草稿状态管理器. 照片在提交时上传, 发送失败后重试时已上传成功的照片会复用存储 key 而不重复上传.
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

String _$commentComposerHash() => r'afb9f1c58c2bf6cf24f81575a5c9c9381d736580';

/// 写评论页草稿状态管理器. 照片在提交时上传, 发送失败后重试时已上传成功的照片会复用存储 key 而不重复上传.

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

  /// 写评论页草稿状态管理器. 照片在提交时上传, 发送失败后重试时已上传成功的照片会复用存储 key 而不重复上传.

  CommentComposerProvider call(int dishId) =>
      CommentComposerProvider._(argument: dishId, from: this);

  @override
  String toString() => r'commentComposerProvider';
}

/// 写评论页草稿状态管理器. 照片在提交时上传, 发送失败后重试时已上传成功的照片会复用存储 key 而不重复上传.

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
