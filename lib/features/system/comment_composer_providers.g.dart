// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_composer_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 评论输入框的草稿状态. 照片在提交时上传, 发送失败后重试时已上传成功的照片会复用存储 key 而不重复上传.
///
/// 按菜和 [rootId] 区分: 写评论的那一个 ([rootId] 为 null) 和每条评论下面回复用的互不影响.

@ProviderFor(CommentDraft)
final commentDraftProvider = CommentDraftFamily._();

/// 评论输入框的草稿状态. 照片在提交时上传, 发送失败后重试时已上传成功的照片会复用存储 key 而不重复上传.
///
/// 按菜和 [rootId] 区分: 写评论的那一个 ([rootId] 为 null) 和每条评论下面回复用的互不影响.
final class CommentDraftProvider
    extends $NotifierProvider<CommentDraft, Composer> {
  /// 评论输入框的草稿状态. 照片在提交时上传, 发送失败后重试时已上传成功的照片会复用存储 key 而不重复上传.
  ///
  /// 按菜和 [rootId] 区分: 写评论的那一个 ([rootId] 为 null) 和每条评论下面回复用的互不影响.
  CommentDraftProvider._({
    required CommentDraftFamily super.from,
    required (int, int?) super.argument,
  }) : super(
         retry: null,
         name: r'commentDraftProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$commentDraftHash();

  @override
  String toString() {
    return r'commentDraftProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  CommentDraft create() => CommentDraft();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Composer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Composer>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CommentDraftProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$commentDraftHash() => r'9a154c97d519c4a5114c3891b11cb72dcba0bb7f';

/// 评论输入框的草稿状态. 照片在提交时上传, 发送失败后重试时已上传成功的照片会复用存储 key 而不重复上传.
///
/// 按菜和 [rootId] 区分: 写评论的那一个 ([rootId] 为 null) 和每条评论下面回复用的互不影响.

final class CommentDraftFamily extends $Family
    with
        $ClassFamilyOverride<
          CommentDraft,
          Composer,
          Composer,
          Composer,
          (int, int?)
        > {
  CommentDraftFamily._()
    : super(
        retry: null,
        name: r'commentDraftProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 评论输入框的草稿状态. 照片在提交时上传, 发送失败后重试时已上传成功的照片会复用存储 key 而不重复上传.
  ///
  /// 按菜和 [rootId] 区分: 写评论的那一个 ([rootId] 为 null) 和每条评论下面回复用的互不影响.

  CommentDraftProvider call(int dishId, int? rootId) =>
      CommentDraftProvider._(argument: (dishId, rootId), from: this);

  @override
  String toString() => r'commentDraftProvider';
}

/// 评论输入框的草稿状态. 照片在提交时上传, 发送失败后重试时已上传成功的照片会复用存储 key 而不重复上传.
///
/// 按菜和 [rootId] 区分: 写评论的那一个 ([rootId] 为 null) 和每条评论下面回复用的互不影响.

abstract class _$CommentDraft extends $Notifier<Composer> {
  late final _$args = ref.$arg as (int, int?);
  int get dishId => _$args.$1;
  int? get rootId => _$args.$2;

  Composer build(int dishId, int? rootId);
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
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
