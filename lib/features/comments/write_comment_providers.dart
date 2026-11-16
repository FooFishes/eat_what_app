import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/platform/photo_picker.dart';
import 'package:eat/data/upload/upload_api.dart';
import 'package:eat/data/upload/uploader.dart';
import 'package:eat/domain/models/comment.dart';
import 'package:eat/domain/rules/comment_rules.dart';
import 'package:eat/state/comments.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'write_comment_providers.g.dart';

/// 写评论页的一张照片. [key] 是上传完成后的存储 key, 上传前为 null.
class const ComposerPhoto({
  required final int id,
  required final PickedPhoto photo,
  final String? key,
});

/// 写评论页的照片列表与发送状态; 文本内容由页面的输入框控制器管理.
class const Composer({
  final List<ComposerPhoto> photos = const [],
  final bool sending = false,
});

/// 写评论页草稿状态管理器. 照片在提交时上传, 发送失败后重试时已上传成功的照片会复用存储 key 而不重复上传.
@riverpod
class CommentComposer extends _$CommentComposer {
  @override
  Composer build(int dishId) => const Composer();

  var _nextId = 0;

  /// 追加待上传照片, 超出数量上限的部分将被截断丢弃.
  void addPhotos(List<PickedPhoto> picked) {
    final room = CommentRules.photoMax - state.photos.length;
    if (room <= 0 || picked.isEmpty) return;
    state = Composer(
      photos: [
        ...state.photos,
        for (final photo in picked.take(room))
          ComposerPhoto(id: _nextId++, photo: photo),
      ],
      sending: state.sending,
    );
  }

  void removePhoto(int id) => state = Composer(
    photos: [
      for (final p in state.photos)
        if (p.id != id) p,
    ],
    sending: state.sending,
  );

  /// 上传照片并提交内容. 当 [rootId] 非空时表示回复该评论, 此时不携带照片.
  ///
  /// 失败时抛出 [AppFailure].
  Future<CommentPosted> send(String text, {int? rootId, int? replyToId}) async {
    state = Composer(photos: state.photos, sending: true);
    try {
      final keys = <String>[];
      if (rootId == null) {
        final photos = state.photos;
        final uploaded = {for (final p in photos) p.id: ?p.key};
        final pending = [...photos.where((p) => p.key == null)];
        await ref
            .read(uploaderProvider)
            .uploadAll(
              [for (final p in pending) p.photo.bytes],
              biz: UploadBiz.comments,
              onEach: (i, key) {
                uploaded[pending[i].id] = key;
                if (ref.mounted) _keep(pending[i].id, key);
              },
            );
        keys.addAll([for (final p in photos) uploaded[p.id]!]);
      }
      return await ref
          .read(commentWriterProvider.notifier)
          .post(
            dishId,
            text: text,
            pictureKeys: keys,
            rootId: rootId,
            replyToId: replyToId,
          );
    } finally {
      if (ref.mounted) state = Composer(photos: state.photos);
    }
  }

  void _keep(int id, String key) => state = Composer(
    photos: [
      for (final p in state.photos)
        p.id == id ? ComposerPhoto(id: p.id, photo: p.photo, key: key) : p,
    ],
    sending: state.sending,
  );
}
