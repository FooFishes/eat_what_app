import 'package:clock/clock.dart';
import 'package:eat/core/format/time_format.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/photo_viewer.dart';
import 'package:eat/domain/models/comment.dart';
import 'package:eat/domain/models/report.dart';
import 'package:eat/domain/rules/comment_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/features/system/report_panel.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/comments.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 一条评论: 头像, 昵称, 时间, 文字, 照片, 赞和 "回复", 下方为该评论的回复.
///
/// 菜品详情和全部评论共用本组件. 功能目录之间不能互相导入, 因此放在 `system`.
/// 右上角 "更多" 中, 自己的评论为 "删除", 别人的评论为 "举报".
class CommentCard extends ConsumerWidget {
  const new({super.key, required this.comment, this.highlighted = false});

  final Comment comment;

  /// 从消息或 "我的评论" 进入时, 以底色标出目标评论.
  final bool highlighted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final c = eat.colors;
    final now = clock.now();
    final body = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        EatAvatar(
          name: comment.authorName,
          color: avatarColorOf(comment.authorName),
          size: 36,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment.authorName,
                          style: eat.text.rowTitle.copyWith(
                            fontSize: 14,
                            color: c.ink,
                          ),
                        ),
                        Text(
                          TimeFormat.relative(comment.createdAt, now),
                          style: eat.text.caption.copyWith(color: c.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(12, 0),
                    child: EatIconButton(
                      EatIcons.more,
                      label: '更多',
                      color: c.inkMuted,
                      onPressed: () => showCommentMenu(context, ref, comment),
                    ),
                  ),
                ],
              ),
              if (comment.text.isNotEmpty)
                Text(comment.text, style: eat.text.body.copyWith(color: c.ink)),
              if (comment.images.isNotEmpty)
                _Photos(urls: comment.images, author: comment.authorName),
              Transform.translate(
                offset: const Offset(-10, 0),
                child: Row(
                  spacing: 8,
                  children: [
                    CommentLikeButton(comment: comment),
                    _TextAction(
                      '回复',
                      onTap: () => _reply(context, ref, comment, to: null),
                    ),
                  ],
                ),
              ),
              _Replies(comment: comment),
            ],
          ),
        ),
      ],
    );
    if (!highlighted) return body;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.mist,
        borderRadius: const BorderRadius.all(EatRadius.thumb),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
        child: body,
      ),
    );
  }
}

/// 头像的底色. 按昵称确定舞台色, 同一用户在各处颜色一致.
StageColor avatarColorOf(String name) {
  final sum = name.runes.fold(0, (a, b) => a + b);
  return StageColor.values[sum % StageColor.values.length];
}

/// 回复 [comment]. [to] 是被回复的那条回复, 回复评论本身时为 null.
Future<void> _reply(
  BuildContext context,
  WidgetRef ref,
  Comment comment, {
  required Comment? to,
}) async {
  if (!await guardAction(context, ref, Capability.reply) || !context.mounted) {
    return;
  }
  await context.push(
    Paths.writeComment(
      comment.dishId,
      reply: comment.id,
      to: to?.id,
      name: (to ?? comment).authorName,
    ),
  );
}

/// 心形加赞数. 赞过时为实心, 读屏报告为已按下.
class CommentLikeButton extends ConsumerWidget {
  const new({super.key, required this.comment, this.compact = false});

  final Comment comment;

  /// 回复行里的小号样式.
  ///
  /// 小号样式不查询是否赞过. 每条回复各查询一次会使一页评论的请求数成倍增加.
  /// 代价: 已赞过的回复显示为未赞. 此时点击发送的仍是赞, 计数以服务端返回为准.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final fetched = compact
        ? null
        : ref.watch(commentLikeOfProvider(comment.id)).value;
    final like =
        ref.watch(commentLikesProvider.select((m) => m[comment.id])) ??
        fetched ??
        CommentLike(liked: false, likes: comment.likes);
    return EatTappable(
      onTap: () => _toggle(context, ref, like),
      label: '赞，${like.likes}',
      toggled: like.liked,
      builder: (context, _) => ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: EatSize.touch,
            minHeight: EatSize.touch,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                EatIcon(
                  like.liked ? EatIcons.heartOn : EatIcons.heart,
                  size: compact ? 16 : 18,
                  color: eat.colors.ink,
                ),
                Text(
                  '${like.likes}',
                  style: eat.text.count.copyWith(
                    fontSize: 13,
                    color: eat.colors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    CommentLike current,
  ) async {
    if (!await guardAction(context, ref, Capability.like)) return;
    final failure = await ref
        .read(commentLikesProvider.notifier)
        .toggle(comment.id, current);
    if (failure != null && context.mounted) {
      await reportActionFailure(
        context,
        ref,
        failure,
        capability: Capability.like,
        fallback: '点赞失败，请重试',
      );
    }
  }
}

/// 文字按钮, 如 "回复". 点击区域不小于 44px.
class _TextAction extends StatelessWidget {
  const new(this.label, {required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return EatTappable(
      onTap: onTap,
      builder: (context, _) => ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: EatSize.touch,
          minHeight: EatSize.touch,
        ),
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            style: eat.text.meta.copyWith(
              fontWeight: FontWeight.w600,
              color: eat.colors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

// TODO: 评论照片的签名地址 30 秒后失效, 列表停留超过 30 秒后才滚动到的照片会加载失败. 后端延长有效期或提供按条刷新的接口后, 失败时重新获取地址.
/// 评论里的照片, 最多 3 张小图. 点击打开大图.
class _Photos extends StatelessWidget {
  const new({required this.urls, required this.author});

  final List<String> urls;
  final String author;

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    const size = 76.0;
    return Row(
      spacing: EatSpace.s8,
      children: [
        for (final (i, url) in urls.indexed)
          EatTappable(
            onTap: () => Navigator.of(context).push(
              PhotoViewer.route(
                photos: [
                  for (final u in urls) ViewerPhoto(url: u, credit: author),
                ],
                initialIndex: i,
              ),
            ),
            label: '看$author拍的第 ${i + 1} 张照片',
            focusShape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(EatRadius.thumb),
            ),
            builder: (context, _) => ClipRRect(
              borderRadius: const BorderRadius.all(EatRadius.thumb),
              child: SizedBox.square(
                dimension: size,
                child: ColoredBox(
                  color: c.mist,
                  child: CoverImage(image: networkImage(url, width: size)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// TODO: 回复接口只能按时间倒序分页, 回复超过一页时最早的几条不在第一页里, 显示的不是最早的 2 条. 接口支持正序后改为按正序请求第一页.
/// 评论下面的回复. 默认显示最早的 2 条, 其余折叠在 "展开 N 条回复" 中.
class _Replies extends ConsumerStatefulWidget {
  const new({required this.comment});

  final Comment comment;

  @override
  ConsumerState<_Replies> createState() => _RepliesState();
}

class _RepliesState extends ConsumerState<_Replies> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final replies = ref.watch(commentRepliesProvider(widget.comment.id));
    final list = replies.value;
    if (list == null) {
      if (replies.hasError && !replies.isLoading) {
        return _TextAction(
          '回复加载失败，重试',
          onTap: () =>
              ref.invalidate(commentRepliesProvider(widget.comment.id)),
        );
      }
      return const SizedBox.shrink();
    }
    if (list.items.isEmpty) return const SizedBox.shrink();
    final ordered = CommentRules.chronological(list.items);
    final shown = _expanded
        ? ordered
        : ordered.take(CommentRules.replyPreview).toList();
    final hidden = list.data.total - shown.length;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: c.hairline, width: 2)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final reply in shown)
              _ReplyLine(
                root: widget.comment,
                reply: reply,
                toName: CommentRules.replyToName(reply, list.items),
              ),
            if (!_expanded && hidden > 0)
              _ExpandButton(
                label: '展开 $hidden 条回复',
                onTap: () => setState(() => _expanded = true),
              )
            else if (_expanded && list.data.page.hasNext)
              _ExpandButton(
                label: list.moreError == null ? '更多回复' : '加载失败，重试',
                onTap: () => ref
                    .read(commentRepliesProvider(widget.comment.id).notifier)
                    .loadMore(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExpandButton extends StatelessWidget {
  const new({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return EatTappable(
      onTap: onTap,
      builder: (context, _) => SizedBox(
        height: EatSize.touch,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            Text(
              label,
              style: eat.text.meta.copyWith(
                fontWeight: FontWeight.w600,
                color: eat.colors.ink,
              ),
            ),
            EatIcon(EatIcons.chevronDown, size: 16, color: eat.colors.ink),
          ],
        ),
      ),
    );
  }
}

/// 一条回复: 昵称, "回复 小林", 文字, 右侧是赞和 "更多". 点击文字回复这条回复.
class _ReplyLine extends ConsumerWidget {
  const new({required this.root, required this.reply, required this.toName});

  final Comment root;
  final Comment reply;
  final String? toName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final c = eat.colors;
    final style = eat.text.body.copyWith(
      fontSize: 14,
      height: 22 / 14,
      color: c.ink,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: EatTappable(
            onTap: () => _reply(context, ref, root, to: reply),
            label: '回复${reply.authorName}',
            focusShape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(EatRadius.thumb),
            ),
            builder: (context, _) => ConstrainedBox(
              constraints: const BoxConstraints(minHeight: EatSize.touch),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: reply.authorName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (toName != null)
                        TextSpan(
                          text: ' 回复 $toName',
                          style: TextStyle(color: c.inkMuted),
                        ),
                      TextSpan(text: '　${reply.text}'),
                    ],
                  ),
                  style: style,
                ),
              ),
            ),
          ),
        ),
        CommentLikeButton(comment: reply, compact: true),
        EatIconButton(
          EatIcons.more,
          label: '更多',
          color: c.inkMuted,
          onPressed: () =>
              showCommentMenu(context, ref, reply, rootId: root.id),
        ),
      ],
    );
  }
}

enum _MenuAction { delete, report }

/// 评论的 "更多" 面板: 自己写的显示 "删除", 别人写的显示 "举报".
///
/// [rootId] 是回复所属评论的 id. 删除回复后据此从该评论的回复列表中移除.
/// 读取 "我的评论" 失败时按别人的评论处理, 只提供举报.
Future<void> showCommentMenu(
  BuildContext context,
  WidgetRef ref,
  Comment comment, {
  int? rootId,
}) async {
  final mine = await ref
      .read(myCommentIdsProvider.future)
      .then((ids) => ids.contains(comment.id), onError: (Object _) => false);
  if (!context.mounted) return;
  final action = await showPanel<_MenuAction>(
    context,
    builder: (panel) => EatPanel(
      title: comment.isReply ? '这条回复' : '这条评论',
      child: mine
          ? EatListRow(
              leading: const _MenuIcon(EatIcons.delete),
              title: const Text('删除'),
              onTap: () => Navigator.of(panel).pop(_MenuAction.delete),
            )
          : EatListRow(
              leading: const _MenuIcon(EatIcons.report),
              title: const Text('举报'),
              onTap: () => Navigator.of(panel).pop(_MenuAction.report),
            ),
    ),
  );
  if (!context.mounted) return;
  switch (action) {
    case _MenuAction.report:
      await showReportPanel(context, ref, ReportTarget.comment(comment.id));
    case _MenuAction.delete:
      await _delete(context, ref, comment, rootId: rootId);
    case null:
  }
}

Future<void> _delete(
  BuildContext context,
  WidgetRef ref,
  Comment comment, {
  required int? rootId,
}) async {
  if (!await guardAction(context, ref, Capability.deleteComment) ||
      !context.mounted ||
      !await _confirmDelete(context, comment)) {
    return;
  }
  final failure = await ref
      .read(commentWriterProvider.notifier)
      .delete(comment, rootId: rootId);
  if (!context.mounted) return;
  if (failure == null) {
    showToast(context, '已删除');
  } else {
    await reportActionFailure(
      context,
      ref,
      failure,
      capability: Capability.deleteComment,
      fallback: '删除失败，请重试',
    );
  }
}

Future<bool> _confirmDelete(BuildContext context, Comment comment) async =>
    await showPanel<bool>(
      context,
      builder: (panel) => EatPanel(
        icon: EatIcons.delete,
        title: comment.isReply ? '删除这条回复？' : '删除这条评论？',
        subtitle: comment.isReply ? null : '下面的回复会一起删除，删除后不能恢复。',
        actions: Row(
          spacing: EatSpace.s10,
          children: [
            Expanded(
              child: EatButton.mist(
                '先不删',
                onPressed: () => Navigator.of(panel).pop(false),
              ),
            ),
            Expanded(
              child: EatButton.solid(
                '删除',
                onPressed: () => Navigator.of(panel).pop(true),
              ),
            ),
          ],
        ),
      ),
    ) ??
    false;

class _MenuIcon extends StatelessWidget {
  const new(this.icon);

  final EatIcons icon;

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    return Container(
      width: EatSize.touch,
      height: EatSize.touch,
      decoration: BoxDecoration(color: c.mist, shape: BoxShape.circle),
      child: Center(child: EatIcon(icon, size: 20, color: c.ink)),
    );
  }
}
