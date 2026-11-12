import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/format/time_format.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_dialog.dart';
import 'package:eat/design/widgets/eat_haptics.dart';
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
import 'package:eat/state/session.dart';
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
          color: avatarColorOf(comment.authorId),
          image: networkImage(comment.authorAvatar, width: 36),
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
                          style: eat.text.body.copyWith(
                            fontWeight: FontWeight.w600,
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

/// 没有头像时的底色. 按用户 id 确定舞台色, 与个人主页一致.
StageColor avatarColorOf(int userId) =>
    StageColor.values[userId % StageColor.values.length];

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
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final like =
        ref.watch(commentLikesProvider.select((m) => m[comment.id])) ??
        CommentLike(liked: comment.liked ?? false, likes: comment.likes);
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
                EatIconSwap(
                  like.liked ? EatIcons.heartOn : EatIcons.heart,
                  size: compact ? 16 : 18,
                  color: like.liked ? null : eat.colors.ink,
                ),
                Text(
                  '${like.likes}',
                  style: eat.text.count.copyWith(color: eat.colors.ink),
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
    EatHaptics.light();
    final failure = await ref
        .read(commentLikesProvider.notifier)
        .toggle(comment.id, current);
    if (failure != null && context.mounted) {
      if (_goneHandled(context, ref, comment, failure)) return;
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

/// 评论下面的回复. 默认显示最早的 2 条, 其余折叠在 "展开 N 条回复" 中.
///
/// 回复条数为 0 时不请求回复列表.
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
    if (widget.comment.replyCount <= 0) return const SizedBox.shrink();
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
    final shown = _expanded
        ? list.items
        : list.items.take(CommentRules.replyPreview).toList();
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
              _ReplyLine(root: widget.comment, reply: reply),
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

/// 一条回复. 第一行为昵称和 "回复 小林", 右端为赞和 "更多". 回复的文字另起一行, 宽度与回复区相同.
///
/// 文字与右侧按钮在同一行时, 每行只能显示七八个字, 短句也会折成多行.
/// 点击昵称或文字回复这条回复.
class _ReplyLine extends ConsumerWidget {
  const new({required this.root, required this.reply});

  final Comment root;
  final Comment reply;

  /// 昵称所在的行右端为赞和 "更多" 预留的宽度.
  static const _actionsWidth = 116.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final c = eat.colors;
    final style = eat.text.body.copyWith(color: c.ink);
    return Stack(
      children: [
        EatTappable(
          onTap: () => _reply(context, ref, root, to: reply),
          label: '回复${reply.authorName}',
          focusShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(EatRadius.thumb),
          ),
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: _actionsWidth),
                child: ConstrainedBox(
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
                          if (reply.replyToName case final toName?)
                            TextSpan(
                              text: ' 回复 $toName',
                              style: TextStyle(color: c.inkMuted),
                            ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(reply.text, style: style),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CommentLikeButton(comment: reply, compact: true),
              EatIconButton(
                EatIcons.more,
                label: '更多',
                color: c.inkMuted,
                onPressed: () => showCommentMenu(context, ref, reply),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _MenuAction { delete, report }

/// 评论的 "更多" 面板: 自己写的显示 "删除", 别人写的显示 "举报".
Future<void> showCommentMenu(
  BuildContext context,
  WidgetRef ref,
  Comment comment,
) async {
  final session = ref.read(sessionProvider);
  final mine = session is SignedIn && session.user?.id == comment.authorId;
  final action = await showPanel<_MenuAction>(
    context,
    builder: (panel) => EatPanel(
      title: comment.isReply ? '这条回复' : '这条评论',
      child: mine
          ? EatPanelAction(
              icon: EatIcons.delete,
              label: '删除',
              onTap: () => Navigator.of(panel).pop(_MenuAction.delete),
            )
          : EatPanelAction(
              icon: EatIcons.report,
              label: '举报',
              onTap: () => Navigator.of(panel).pop(_MenuAction.report),
            ),
    ),
  );
  if (!context.mounted) return;
  switch (action) {
    case _MenuAction.report:
      await showReportPanel(
        context,
        ref,
        ReportTarget.comment(comment.id),
        onGone: () =>
            ref.read(commentWriterProvider.notifier).removeLocal(comment),
      );
    case _MenuAction.delete:
      await _delete(context, ref, comment);
    case null:
  }
}

Future<void> _delete(
  BuildContext context,
  WidgetRef ref,
  Comment comment,
) async {
  if (!await guardAction(context, ref, Capability.deleteComment) ||
      !context.mounted ||
      !await _confirmDelete(context, comment)) {
    return;
  }
  final failure = await ref
      .read(commentWriterProvider.notifier)
      .delete(comment);
  if (!context.mounted) return;
  if (failure == null) {
    showToast(context, '已删除');
  } else if (isCommentGone(failure)) {
    showToast(context, _goneMessage(comment));
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

/// 服务端答复 [comment] 不存在时, 提示已删除并从列表中移除, 返回 true. 其他失败返回 false.
bool _goneHandled(
  BuildContext context,
  WidgetRef ref,
  Comment comment,
  AppFailure failure,
) {
  if (!isCommentGone(failure)) return false;
  ref.read(commentWriterProvider.notifier).removeLocal(comment);
  showToast(context, _goneMessage(comment));
  return true;
}

String _goneMessage(Comment comment) => comment.isReply ? '这条回复已删除' : '这条评论已删除';

Future<bool> _confirmDelete(BuildContext context, Comment comment) async =>
    await showEatDialog<bool>(
      context,
      builder: (dialog) => EatDialog(
        icon: EatIcons.delete,
        title: comment.isReply ? '删除这条回复？' : '删除这条评论？',
        subtitle: comment.isReply ? null : '下面的回复也会一并删除，且无法恢复。',
        actions: Row(
          spacing: EatSpace.s10,
          children: [
            Expanded(
              child: EatButton.mist(
                '取消',
                onPressed: () => Navigator.of(dialog).pop(false),
              ),
            ),
            Expanded(
              child: EatButton.solid(
                '删除',
                onPressed: () => Navigator.of(dialog).pop(true),
              ),
            ),
          ],
        ),
      ),
    ) ??
    false;
