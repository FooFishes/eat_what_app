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

/// 写评论页的照片和发送状态. 文字在页面的输入框里.
class const Composer({
  final List<ComposerPhoto> photos = const [],
  final bool sending = false,
});

/// 写评论页的草稿. 照片在发送时上传, 上传过的照片重试时不再上传.
@riverpod
class CommentComposer extends _$CommentComposer {
  @override
  Composer build(int dishId) => const Composer();

  var _nextId = 0;

  /// 加入照片, 超出上限的部分丢弃.
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

  /// 上传照片并发表. [rootId] 不为 null 时回复该评论, 回复不带照片.
  ///
  /// 失败时抛出 [AppFailure].
  Future<CommentPosted> send(String text, {int? rootId, int? replyToId}) async {
    state = Composer(photos: state.photos, sending: true);
    try {
      final keys = <String>[];
      if (rootId == null) {
        for (final photo in state.photos) {
          final key =
              photo.key ??
              await ref
                  .read(uploaderProvider)
                  .upload(photo.photo.bytes, biz: UploadBiz.comments);
          keys.add(key);
          if (ref.mounted && photo.key == null) _keep(photo.id, key);
        }
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
