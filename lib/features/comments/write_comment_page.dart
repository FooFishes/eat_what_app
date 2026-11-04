import 'dart:async';

import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/platform/photo_picker.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/code_point_limit.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/rules/comment_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/comments/write_comment_providers.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/state/comments.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 写评论或回复.
///
/// - 写评论: 文字最多 200 字, 照片最多 3 张, 两者至少填写一项.
/// - 回复: 只能写字, 输入框提示 "回复 小林".
///
/// 发送后回到上一页. 进入审核时提示 "已提交审核, 通过后公开".
/// 已填写内容时返回需要确认. 发送失败时保留内容, 可重新发送.
class WriteCommentPage extends ConsumerStatefulWidget {
  const new({
    super.key,
    required this.dishId,
    this.rootId,
    this.replyToId,
    this.replyToName,
    this.pickOnOpen = false,
  });

  final int dishId;

  /// 回复时所属评论的 id. 为 null 时写评论.
  final int? rootId;

  /// 被回复的回复的 id. 回复评论本身时为 null.
  final int? replyToId;

  /// 被回复人的昵称.
  final String? replyToName;

  /// 打开页面后立即打开照片选择.
  final bool pickOnOpen;

  @override
  ConsumerState<WriteCommentPage> createState() => _WriteCommentPageState();
}

class _WriteCommentPageState extends ConsumerState<WriteCommentPage> {
  final _text = TextEditingController();
  var _sent = false;

  bool get _reply => widget.rootId != null;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
    if (widget.pickOnOpen && !_reply) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_addPhotos());
      });
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _dirty =>
      !_sent &&
      (_text.text.trim().isNotEmpty ||
          ref.read(commentComposerProvider(widget.dishId)).photos.isNotEmpty);

  Future<void> _leave() async {
    if (_dirty && !await _confirmLeave()) return;
    if (!mounted) return;
    _sent = true;
    BackFallback.back(context);
  }

  Future<bool> _confirmLeave() async =>
      await showPanel<bool>(
        context,
        builder: (panel) => EatPanel(
          icon: EatIcons.warning,
          title: _reply ? '这条回复还未发送，确定放弃吗？' : '这条评论还未发送，确定放弃吗？',
          actions: Row(
            spacing: EatSpace.s10,
            children: [
              Expanded(
                child: EatButton.mist(
                  '放弃',
                  onPressed: () => Navigator.of(panel).pop(true),
                ),
              ),
              Expanded(
                child: EatButton.solid(
                  '继续写',
                  onPressed: () => Navigator.of(panel).pop(false),
                ),
              ),
            ],
          ),
        ),
      ) ??
      false;

  Future<void> _addPhotos() async {
    final composer = ref.read(commentComposerProvider(widget.dishId));
    final room = CommentRules.photoMax - composer.photos.length;
    if (room <= 0) return;
    final photos = await _pickPhotos(room);
    if (!mounted || photos.isEmpty) return;
    ref.read(commentComposerProvider(widget.dishId).notifier).addPhotos(photos);
  }

  Future<List<PickedPhoto>> _pickPhotos(int limit) async {
    final camera = await showPanel<bool>(
      context,
      builder: (panel) => EatPanel(
        title: '加照片',
        subtitle: '要是这道菜的实拍，不用网图和菜单截图',
        actions: Row(
          spacing: EatSpace.s10,
          children: [
            Expanded(
              child: EatButton.mist(
                '从相册选',
                icon: EatIcons.image,
                onPressed: () => Navigator.of(panel).pop(false),
              ),
            ),
            Expanded(
              child: EatButton.solid(
                '拍一张',
                icon: EatIcons.camera,
                onPressed: () => Navigator.of(panel).pop(true),
              ),
            ),
          ],
        ),
      ),
    );
    if (camera == null) return const [];
    final picker = ref.read(photoPickerProvider);
    try {
      return camera
          ? [?await picker.takePhoto()]
          : await picker.pickFromGallery(limit: limit);
    } on PhotoPickException catch (e) {
      if (mounted) {
        showToast(context, switch (e.reason) {
          PhotoPickFailure.denied => '请在系统设置中允许访问相机和相册',
          PhotoPickFailure.unsupported => '不支持该照片格式，请更换',
        });
      }
    } on Object {
      if (mounted) showToast(context, '照片读取失败，请重试');
    }
    return const [];
  }

  Future<void> _send() async {
    final capability = _reply ? Capability.reply : Capability.comment;
    if (!await guardAction(context, ref, capability) || !mounted) return;
    try {
      final posted = await ref
          .read(commentComposerProvider(widget.dishId).notifier)
          .send(_text.text, rootId: widget.rootId, replyToId: widget.replyToId);
      if (!mounted) return;
      showToast(context, posted.pending ? '已提交审核，通过后公开' : '发送成功');
      _sent = true;
      BackFallback.back(context);
    } on AppFailure catch (e) {
      if (!mounted) return;
      await reportActionFailure(
        context,
        ref,
        e,
        capability: capability,
        fallback: '发送失败，请重试',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final composer = ref.watch(commentComposerProvider(widget.dishId));
    final dish = ref.watch(commentedDishProvider(widget.dishId)).value;
    final length = CommentRules.length(_text.text);
    final ready = CommentRules.canSend(
      _text.text,
      photos: composer.photos.length,
      reply: _reply,
    );
    final name = widget.replyToName ?? '同学';
    final counter = eat.text.count.copyWith(color: c.inkMuted);
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: PlainScaffold(
        title: _reply ? '回复' : '写一条',
        subtitle: dish == null ? null : [dish.name, ?dish.shopName].join('  '),
        onBack: _leave,
        actions: [
          EatButton.solid(
            '发送',
            height: 36,
            loading: composer.sending,
            onPressed: ready ? _send : null,
          ),
        ],
        slivers: [
          SliverList.list(
            children: [
              EatFormField.multiline(
                label: _reply ? '回复内容' : '评论内容',
                controller: _text,
                autofocus: true,
                hintText: _reply ? '回复 $name' : '吃过的话，说两句',
                inputFormatters: const [
                  CodePointLengthLimitingFormatter(CommentRules.textMax),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '$length', style: counter),
                      TextSpan(
                        text: ' / ${CommentRules.textMax}',
                        style: counter,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: EatSpace.s20),
              if (_reply)
                Text(
                  '回复暂不支持添加照片',
                  style: eat.text.caption.copyWith(color: c.inkMuted),
                )
              else ...[
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: '照片，最多 3 张  '),
                      TextSpan(
                        text: '${composer.photos.length}',
                        style: counter,
                      ),
                      TextSpan(
                        text: ' / ${CommentRules.photoMax}',
                        style: counter,
                      ),
                    ],
                  ),
                  style: eat.text.meta.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: EatSpace.s10),
                Wrap(
                  spacing: EatSpace.s10,
                  runSpacing: EatSpace.s10,
                  children: [
                    for (final (i, photo) in composer.photos.indexed)
                      _Photo(
                        image: MemoryImage(photo.photo.bytes),
                        label: '去掉第 ${i + 1} 张照片',
                        onRemove: composer.sending
                            ? null
                            : () => ref
                                  .read(
                                    commentComposerProvider(widget.dishId)
                                        .notifier,
                                  )
                                  .removePhoto(photo.id),
                      ),
                    if (composer.photos.length < CommentRules.photoMax)
                      _AddPhoto(onTap: composer.sending ? null : _addPhotos),
                  ],
                ),
                const SizedBox(height: EatSpace.s10),
                Text(
                  '照片要是这道菜的实拍，会和上传者的照片一起出现在大图里',
                  style: eat.text.caption.copyWith(color: c.inkMuted),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// 一张已添加的照片, 右上角按钮移除该照片.
class _Photo extends StatelessWidget {
  const new({required this.image, required this.label, required this.onRemove});

  final ImageProvider image;
  final String label;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    const size = 96.0;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(EatRadius.thumbLg),
            child: SizedBox.square(
              dimension: size,
              child: CoverImage(image: image),
            ),
          ),
          Positioned(
            right: -10,
            top: -10,
            child: EatTappable(
              onTap: onRemove,
              label: label,
              focusShape: const CircleBorder(),
              builder: (context, _) => SizedBox.square(
                dimension: EatSize.touch,
                child: Center(
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: c.ink,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.paper, width: 2),
                    ),
                    child: Center(
                      child: EatIcon(EatIcons.close, size: 14, color: c.paper),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "加照片" 方块: 虚线框内为相机图标.
class _AddPhoto extends StatelessWidget {
  const new({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    return EatTappable(
      onTap: onTap,
      label: '加照片',
      focusShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(EatRadius.thumbLg),
      ),
      builder: (context, _) => Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: c.mist,
          borderRadius: const BorderRadius.all(EatRadius.thumbLg),
        ),
        child: Center(child: EatIcon(EatIcons.camera, size: 24, color: c.ink)),
      ),
    );
  }
}
