import 'dart:async';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/format/time_format.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/emoji.dart';
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
import 'package:eat/design/widgets/like_heart.dart';
import 'package:eat/design/widgets/morph_card.dart';
import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/widgets/photo_viewer.dart';
import 'package:eat/domain/models/comment.dart';
import 'package:eat/domain/models/report.dart';
import 'package:eat/domain/rules/comment_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/system/comment_composer.dart';
import 'package:eat/features/system/comment_composer_providers.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/features/system/report_panel.dart';
import 'package:eat/state/comments.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 一条评论, 照抖音评论区的排法: 左边头像; 右边一行灰色的昵称 (上传者自己的评论带 "上传者" 小标), 下面是正文, 附图,
/// 表情回应, 最下面一行是时间, "回复" "回应", 这一行右边是赞和 "更多".
///
/// - 点昵称或正文也是回复, 长按打开 "更多" 的菜单.
/// - 回复挂在正文下面, 和正文对齐, 头像小一号, 写成 "A 回复 B".
/// - 回复在屏幕最下面的横条里写 ([showReplyBar]); "回应" 从按钮展开成卡片 ([showMorphCard]).
/// - 条与条之间不画线, 只靠留白 ([CommentGap]).
///
/// 由菜品详情页与全部评论页共用 (为避免功能模块间相互导入而置于 `system` 目录).
/// "更多" 菜单对本人评论提供 "删除", 对他人评论提供 "举报".
class CommentCard extends ConsumerWidget {
  const new({super.key, required this.comment, this.highlighted = false});

  final Comment comment;

  /// 从消息或 "我的评论" 进入时, 以底色标出目标评论.
  final bool highlighted;

  /// 评论头像的直径.
  static const avatar = 32.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reactions = _reactionsOf(ref, comment);
    final body = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: EatSpace.s10,
      children: [
        EatAvatar(
          name: comment.authorName,
          color: avatarColorOf(comment.authorId),
          image: networkImage(comment.authorAvatar, width: avatar),
          size: avatar,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Text(
                comment: comment,
                onReply: () => _reply(context, ref, comment, to: null),
              ),
              if (comment.images.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: EatSpace.s8),
                  child: _Photos(
                    urls: comment.images,
                    author: comment.authorName,
                  ),
                ),
              _Actions(comment: comment, reactions: reactions),
              _Replies(comment: comment),
            ],
          ),
        ),
      ],
    );
    if (!highlighted) return body;
    return _Highlight(child: body);
  }
}

/// 从消息或 "我的评论" 进来时标出目标评论: 底色先亮着, 停一会儿再褪掉. 底色画在评论外面一圈, 不挪动评论本身.
class _Highlight extends StatefulWidget {
  const new({required this.child});

  final Widget child;

  @override
  State<_Highlight> createState() => _HighlightState();
}

class _HighlightState extends State<_Highlight> {
  var _shown = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _shown = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -EatSpace.s10,
          right: -EatSpace.s10,
          top: -EatSpace.s8,
          bottom: 0,
          child: AnimatedContainer(
            duration: context.motion(EatMotion.reveal) * 3,
            decoration: BoxDecoration(
              color: _shown ? c.mist : c.mist.withValues(alpha: 0),
              borderRadius: const BorderRadius.all(EatRadius.thumb),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

/// 两条评论之间的留白. 评论最下面一行本身带着一段空, 合起来比评论里面的间距大得多, 不用画线.
class CommentGap extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(height: EatSpace.s10);
}

/// 昵称和正文, 右边是 "回复" 和一个大箭头: 点它或文字都是回复, 长按文字打开 "更多" 的菜单. 读屏走箭头按钮, 文字只读不点.
class _Text extends ConsumerWidget {
  const new({required this.comment, required this.onReply});

  final Comment comment;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.eat.colors;
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onReply,
            onLongPress: () => showCommentMenu(context, ref, comment),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                _Byline(comment: comment),
                if (comment.text.isNotEmpty) _Body(comment.text),
              ],
            ),
          ),
        ),
        EatTappable(
          onTap: onReply,
          label: '回复',
          focusShape: const StadiumBorder(),
          builder: (context, _) => ExcludeSemantics(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: EatSize.touch,
                minHeight: EatSize.touch,
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: EatSpace.s8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '回复',
                      style: context.eat.text.meta.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: c.inkSoft,
                      ),
                    ),
                    EatIcon(EatIcons.chevronRight, size: 22, color: c.inkMuted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 昵称一行: 灰色细字. 上传者自己的评论后面带 "上传者" 小标; 回复写成 "A 回复 B".
class _Byline extends ConsumerWidget {
  const new({required this.comment});

  final Comment comment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final c = eat.colors;
    final uploader = ref.watch(
      commentedDishProvider(comment.dishId).select((d) => d.value?.uploaderId),
    );
    final style = eat.text.meta.copyWith(color: c.inkMuted);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: comment.authorName),
          if (uploader != null && uploader == comment.authorId) ...[
            const TextSpan(text: ' '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: _UploaderTag(),
            ),
          ],
          if (comment.replyToName case final toName?) ...[
            TextSpan(
              text: ' 回复 ',
              style: TextStyle(color: c.inkSoft),
            ),
            TextSpan(text: toName),
          ],
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}

/// "上传者" 小标: 浅底小字.
class _UploaderTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.mist,
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Text(
          '上传者',
          style: eat.text.meta.copyWith(
            fontSize: 10,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: c.inkSoft,
          ),
        ),
      ),
    );
  }
}

/// 正文: 正文字号, 行距放宽一点, 读起来不挤.
class _Body extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return Text(
      text,
      style: eat.text.body.copyWith(color: eat.colors.ink, height: 1.45),
    );
  }
}

/// 正文和附图下面: 有人回应过时先是各种回应的胶囊, 放不下再折行; 最下面一行是时间和 "回应", 右边是赞和 "更多".
/// 回复在正文右边的箭头上.
///
/// 有胶囊时, 胶囊和最下面一行露出来的都比 44px 矮, 排紧以后点击区上下压着. 两者都套在 [_TouchBand] 里,
/// 版面上只占看得见的那一截, 点击区照旧是 44px; 交叠的地方由 [_TouchScope] 分配.
class _Actions extends ConsumerWidget {
  const new({required this.comment, required this.reactions});

  final Comment comment;
  final List<ReactionCount> reactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final c = eat.colors;
    final timeStyle = eat.text.meta.copyWith(fontSize: 12, color: c.inkMuted);
    final row = Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  TimeFormat.relative(comment.createdAt, clock.now()),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: timeStyle,
                ),
              ),
              const SizedBox(width: EatSpace.s8),
              _ReactButton(comment: comment),
            ],
          ),
        ),
        CommentLikeButton(comment: comment),
        Transform.translate(
          offset: const Offset(12, 0),
          child: EatIconButton(
            EatIcons.more,
            label: '更多',
            size: 18,
            color: c.inkMuted,
            onPressed: () => showCommentMenu(context, ref, comment),
          ),
        ),
      ],
    );
    if (reactions.isEmpty) return row;
    return _TouchScope(
      child: Padding(
        padding: const EdgeInsets.only(top: EatSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: EatSpace.s4,
          children: [
            _ReactionBar(comment: comment, reactions: reactions),
            // 这一行下面的留白隔开下一条, 只裁上面.
            _TouchBand(
              visual: math.max(
                _lineHeight(context, timeStyle),
                _lineHeight(context, eat.text.count),
              ),
              trimBottom: false,
              yields: true,
              child: row,
            ),
          ],
        ),
      ),
    );
  }
}

/// [style] 的一行字在当前字号缩放下的高度.
double _lineHeight(BuildContext context, TextStyle style) =>
    MediaQuery.textScalerOf(context).scale(style.fontSize!) *
    (style.height ?? 1);

/// 看得见的部分比点击区矮的一块: 子组件照常排成 44px 高, 看得见的部分在中间; 版面上上下各裁掉多出来的一截,
/// 只占 [visual] 那么高, 子组件伸出去画. [trimBottom] 为 false 时只裁上面.
///
/// Flutter 只在一块自己的大小里找点中的东西, 伸出去的那截收不到点击, 由外层的 [_TouchScope] 绕过这一层直接交给子组件.
/// 读屏的框仍是子组件的 44px.
class _TouchBand extends SingleChildRenderObjectWidget {
  const new({
    required this.visual,
    this.trimBottom = true,
    this.yields = false,
    required super.child,
  });

  final double visual;
  final bool trimBottom;

  /// 伸出去的点击区和别的交叠时让给别的. 最下面一行让着胶囊, 两者之间的空隙归胶囊.
  final bool yields;

  @override
  _RenderTouchBand createRenderObject(BuildContext context) =>
      _RenderTouchBand(visual: visual, trimBottom: trimBottom, yields: yields);

  @override
  void updateRenderObject(BuildContext context, _RenderTouchBand renderObject) {
    renderObject
      ..visual = visual
      ..trimBottom = trimBottom
      ..yields = yields;
  }
}

class _RenderTouchBand extends RenderShiftedBox {
  _RenderTouchBand({
    required this._visual,
    required this._trimBottom,
    required this.yields,
  }) : super(null);

  double _visual;
  set visual(double value) {
    if (value == _visual) return;
    _visual = value;
    markNeedsLayout();
  }

  bool _trimBottom;
  set trimBottom(bool value) {
    if (value == _trimBottom) return;
    _trimBottom = value;
    markNeedsLayout();
  }

  bool yields;

  ({double top, double bottom}) _trim(double height) {
    final overhang = math.max(0.0, (height - _visual) / 2);
    return (top: overhang, bottom: _trimBottom ? overhang : 0.0);
  }

  double _trimmed(double height) {
    final trim = _trim(height);
    return height - trim.top - trim.bottom;
  }

  /// 高度不设限, 子组件按自己的点击区排.
  BoxConstraints _childConstraints(BoxConstraints constraints) =>
      BoxConstraints(
        minWidth: constraints.minWidth,
        maxWidth: constraints.maxWidth,
      );

  @override
  double computeMinIntrinsicHeight(double width) =>
      _trimmed(child?.getMinIntrinsicHeight(width) ?? 0);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _trimmed(child?.getMaxIntrinsicHeight(width) ?? 0);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    final full = child.getDryLayout(_childConstraints(constraints));
    return constraints.constrain(Size(full.width, _trimmed(full.height)));
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(_childConstraints(constraints), parentUsesSize: true);
    final trim = _trim(child.size.height);
    (child.parentData! as BoxParentData).offset = Offset(0, -trim.top);
    size = constraints.constrain(
      Size(child.size.width, child.size.height - trim.top - trim.bottom),
    );
  }

  /// [position] 落在点击区里时离看得见的部分有多远, 不在点击区里时为 null.
  double? reach(Offset position) {
    final child = this.child;
    if (child == null) return null;
    final touch = (child.parentData! as BoxParentData).offset & child.size;
    if (!touch.contains(position)) return null;
    final dx = math.max(0.0, math.max(-position.dx, position.dx - size.width));
    final dy = math.max(0.0, math.max(-position.dy, position.dy - size.height));
    return Offset(dx, dy).distance;
  }

  /// 不看自己的大小, 在整个点击区里找点中的东西.
  bool hitTestTouch(BoxHitTestResult result, Offset position) {
    if (!hitTestChildren(result, position: position)) return false;
    result.add(BoxHitTestEntry(this, position));
    return true;
  }
}

/// 收着几块 [_TouchBand]. 先照常找点中的东西, 看得见的部分优先, 正文在这一块外面, 也优先;
/// 都没点中时交给点击区罩着这一点的那块, 几块都罩着时给看得见的部分离得最近的, [_TouchBand.yields] 的排在最后.
class _TouchScope extends SingleChildRenderObjectWidget {
  const new({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderTouchScope();
}

class _RenderTouchScope extends RenderProxyBox {
  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (super.hitTestChildren(result, position: position)) return true;
    final candidates = <(_RenderTouchBand, Matrix4, double)>[];
    void collect(RenderObject node) {
      if (node is! _RenderTouchBand) {
        node.visitChildren(collect);
        return;
      }
      final transform = node.getTransformTo(this);
      final inverse = Matrix4.tryInvert(transform);
      if (inverse == null) return;
      final distance = node.reach(
        MatrixUtils.transformPoint(inverse, position),
      );
      if (distance != null) candidates.add((node, transform, distance));
    }

    visitChildren(collect);
    candidates.sort(
      (a, b) => a.$1.yields != b.$1.yields
          ? (a.$1.yields ? 1 : -1)
          : a.$3.compareTo(b.$3),
    );
    for (final (band, transform, _) in candidates) {
      final hit = result.addWithPaintTransform(
        transform: transform,
        position: position,
        hitTest: (result, local) => band.hitTestTouch(result, local),
      );
      if (hit) return true;
    }
    return false;
  }
}

/// 计算用户默认头像的底色, 按用户 id 映射为固定舞台色以与个人主页保持一致.
StageColor avatarColorOf(int userId) =>
    StageColor.values[userId % StageColor.values.length];

/// 回复主评论 [comment], 若针对某条楼中楼回复进行回复, 则通过 [to] 指定目标回复. 在屏幕最下面弹出回复横条.
Future<void> _reply(
  BuildContext context,
  WidgetRef ref,
  Comment comment, {
  required Comment? to,
}) async {
  if (!await guardAction(context, ref, Capability.reply) || !context.mounted) {
    return;
  }
  await showReplyBar(
    context,
    dishId: comment.dishId,
    target: ReplyTarget(
      rootId: comment.id,
      replyToId: to?.id,
      name: (to ?? comment).authorName,
    ),
  );
}

/// 评论的赞: 心形加赞数, 放在评论最下面一行的右边. 赞上时心形弹一下.
/// 已点赞时呈实心图标并向读屏工具报告为已选中状态.
class CommentLikeButton extends ConsumerWidget {
  const new({super.key, required this.comment});

  final Comment comment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final c = eat.colors;
    final like =
        ref.watch(commentLikesProvider.select((m) => m[comment.id])) ??
        CommentLike(liked: comment.liked ?? false, likes: comment.likes);
    return EatTappable(
      onTap: () => _toggle(context, ref, like),
      label: '赞，${like.likes}',
      toggled: like.liked,
      dimOnPress: false,
      focusShape: const StadiumBorder(),
      builder: (context, _) => ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: EatSize.touch,
            minHeight: EatSize.touch,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: EatSpace.s8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: EatSpace.s4,
              children: [
                LikeHeart(liked: like.liked, size: 18, color: c.inkMuted),
                if (like.likes > 0)
                  Text(
                    '${like.likes}',
                    style: eat.text.count.copyWith(
                      fontSize: 13,
                      color: like.liked ? c.ink : c.inkMuted,
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

/// [comment] 当前的表情回应: 本地点过的以覆盖值为准, 否则取评论自带的.
List<ReactionCount> _reactionsOf(WidgetRef ref, Comment comment) =>
    ref.watch(commentReactionsProvider.select((m) => m[comment.id])) ??
    comment.reactions;

ReactionEmoji _emojiOf(CommentReaction reaction) =>
    ReactionEmoji.values.byName(reaction.name);

/// 点一种回应: 没选过就选上 (换掉自己原来那种), 选过就取消. 回应和赞要求的身份相同.
Future<void> _react(
  BuildContext context,
  WidgetRef ref,
  Comment comment,
  CommentReaction reaction,
) async {
  if (!await guardAction(context, ref, Capability.react)) return;
  EatHaptics.light();
  final before =
      ref.read(commentReactionsProvider)[comment.id] ?? comment.reactions;
  final failure = await ref
      .read(commentReactionsProvider.notifier)
      .toggle(comment.id, before, reaction);
  if (failure != null && context.mounted) {
    if (_goneHandled(context, ref, comment, failure)) return;
    await reportActionFailure(
      context,
      ref,
      failure,
      capability: Capability.react,
      fallback: '回应失败，请重试',
    );
  }
}

/// "回应" 按钮: 点了从按钮展开成回应卡片, 和评分卡一样.
class _ReactButton extends ConsumerStatefulWidget {
  const new({required this.comment});

  final Comment comment;

  @override
  ConsumerState<_ReactButton> createState() => _ReactButtonState();
}

class _ReactButtonState extends ConsumerState<_ReactButton> {
  final _origin = GlobalKey();

  Future<void> _open() async {
    if (!await guardAction(context, ref, Capability.react) || !mounted) {
      return;
    }
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4);
    await showMorphCard<void>(
      context,
      origin: _origin,
      from: context.eat.colors.paper,
      height: 148 * scale,
      barrierLabel: widget.comment.isReply ? '回应这条回复' : '回应这条评论',
      face: (_) => const _TextActionFace('回应'),
      builder: (_) => _ReactionCard(comment: widget.comment, onPick: _pick),
    );
  }

  /// 卡片选完就收回, 请求的结果晚于卡片回来, 失败时用评论这边的 context 和 ref 提示.
  void _pick(CommentReaction reaction) =>
      unawaited(_react(context, ref, widget.comment, reaction));

  @override
  Widget build(BuildContext context) =>
      _TextAction('回应', key: _origin, onTap: _open);
}

/// 回应卡片: 六种表情排成一行, 下面是各自的人数, 自己选的那种带底色. 点一种就选上 (再点取消),
/// 停一拍让选中的样子露出来, 卡片随即收回.
class _ReactionCard extends ConsumerStatefulWidget {
  const new({required this.comment, required this.onPick});

  final Comment comment;

  /// 选上或取消一种回应. 卡片随后就关, 请求和失败提示交给打开卡片的那一边.
  final ValueChanged<CommentReaction> onPick;

  @override
  ConsumerState<_ReactionCard> createState() => _ReactionCardState();
}

class _ReactionCardState extends ConsumerState<_ReactionCard> {
  Timer? _close;

  @override
  void dispose() {
    _close?.cancel();
    super.dispose();
  }

  void _pick(CommentReaction reaction) {
    if (_close != null) return;
    widget.onPick(reaction);
    _close = Timer(context.motion(EatMotion.select), () {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route == null || !route.isActive) return;
      // 失败的提示可能已经盖在卡片上面, 这时只拿掉卡片.
      if (route.isCurrent) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).removeRoute(route);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final eat = context.eat;
    final c = eat.colors;
    final current = _reactionsOf(ref, comment);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EatSpace.s20,
        EatSpace.s14,
        EatSpace.s8,
        EatSpace.s14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    comment.isReply ? '回应这条回复' : '回应这条评论',
                    style: eat.text.heading.copyWith(color: c.ink),
                  ),
                ),
              ),
              EatIconButton(
                EatIcons.close,
                label: '关闭',
                color: c.inkMuted,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: EatSpace.s8),
          Padding(
            padding: const EdgeInsets.only(right: EatSpace.s10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final reaction in CommentReaction.values)
                  _ReactionOption(
                    reaction: reaction,
                    count:
                        current
                            .where((r) => r.reaction == reaction)
                            .firstOrNull
                            ?.count ??
                        0,
                    selected: current.any(
                      (r) => r.reaction == reaction && r.selected,
                    ),
                    onTap: () => _pick(reaction),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionOption extends StatelessWidget {
  const new({
    required this.reaction,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final CommentReaction reaction;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final duration = context.motion(EatMotion.select) * 2;
    return EatTappable(
      onTap: onTap,
      label: '${reaction.label}，$count',
      toggled: selected,
      dimOnPress: false,
      focusShape: const CircleBorder(),
      builder: (context, _) => ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            DecoratedBox(
              decoration: ShapeDecoration(
                shape: const CircleBorder(),
                color: selected ? c.mist : null,
              ),
              child: SizedBox.square(
                dimension: 48,
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(selected),
                    tween: Tween(begin: selected ? 1.35 : 1, end: 1),
                    duration: duration,
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: ReactionEmojiImage(_emojiOf(reaction), size: 28),
                  ),
                ),
              ),
            ),
            Text(
              count > 0 ? '$count' : ' ',
              style: eat.text.count.copyWith(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? c.ink : c.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 有人选过的表情回应, 每种一个 "表情 人数" 胶囊, 自己选的那种描边, 人数加粗. 点胶囊选上或取消这一种.
/// 胶囊各自带 44px 的点击区, 套在 [_TouchBand] 里只占看得见的高度, 折行后上下两行也挨得近.
class _ReactionBar extends ConsumerWidget {
  const new({required this.comment, required this.reactions});

  final Comment comment;
  final List<ReactionCount> reactions;

  static const _emoji = 16.0;
  static const _padding = EdgeInsets.symmetric(horizontal: 10, vertical: 5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final c = eat.colors;
    final visual =
        math.max(_emoji, _lineHeight(context, eat.text.count)) +
        _padding.vertical;
    return Wrap(
      spacing: 6,
      runSpacing: EatSpace.s4,
      children: [
        for (final r in reactions)
          _TouchBand(
            visual: visual,
            child: EatTappable(
              onTap: () => _react(context, ref, comment, r.reaction),
              label: '${r.reaction.label}，${r.count}',
              toggled: r.selected,
              focusShape: const StadiumBorder(),
              builder: (context, _) => ExcludeSemantics(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: EatSize.touch,
                    minHeight: EatSize.touch,
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: c.mist,
                        shape: StadiumBorder(
                          side: r.selected
                              ? BorderSide(color: c.ink, width: 1.5)
                              : BorderSide.none,
                        ),
                      ),
                      child: Padding(
                        padding: _padding,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 4,
                          children: [
                            ReactionEmojiImage(
                              _emojiOf(r.reaction),
                              size: _emoji,
                            ),
                            Text(
                              '${r.count}',
                              style: eat.text.count.copyWith(
                                color: c.ink,
                                fontWeight: r.selected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 最下面一行的文字按钮 (如 "回复"), 灰色加粗小字, 点击热区不小于 44px.
class _TextAction extends StatelessWidget {
  const new(this.label, {super.key, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => EatTappable(
    onTap: onTap,
    builder: (context, _) => _TextActionFace(label),
  );
}

/// [_TextAction] 的样子, 回应卡片展开和收回时也画它.
class _TextActionFace extends StatelessWidget {
  const new(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: EatSize.touch,
        minHeight: EatSize.touch,
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          label,
          style: eat.text.meta.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: eat.colors.inkSoft,
          ),
        ),
      ),
    );
  }
}

/// 评论附图缩略图列表 (最多 3 张), 点击后进入大图浏览.
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

/// 主评论下方的回复列表, 默认展示最早的 2 条并将剩余回复折叠为 "展开 N 条回复".
///
/// 当主评论回复数为 0 时不会请求回复列表. 起初只请求这 2 条, 点 "展开" 后才加载完整的第 1 页.
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
    final provider = commentRepliesProvider(widget.comment.id);
    final replies = ref.watch(provider);
    final list = replies.value;
    if (list == null) {
      if (replies.hasError && !replies.isLoading) {
        return _TextAction('回复加载失败，重试', onTap: () => ref.invalidate(provider));
      }
      return const SizedBox.shrink();
    }
    if (list.items.isEmpty) return const SizedBox.shrink();
    final shown = _expanded
        ? list.items
        : list.items.take(CommentRules.replyPreview).toList();
    final hidden = list.data.total - shown.length;
    final more = _expanded && list.data.page.hasNext;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final reply in shown)
          _ReplyLine(root: widget.comment, reply: reply),
        // 完整的第 1 页加载完之前仍是预览, 按钮保持 "展开 N 条回复", 不闪成 "展开更多".
        if ((!_expanded || list.preview) && hidden > 0)
          _ExpandButton(
            label: _expanded && list.moreError != null
                ? '加载失败，重试'
                : '展开 $hidden 条回复',
            onTap: () {
              setState(() => _expanded = true);
              if (list.preview) {
                unawaited(ref.read(provider.notifier).loadMore());
              }
            },
          )
        else if (more)
          _ExpandButton(
            label: list.moreError == null ? '展开更多' : '加载失败，重试',
            onTap: () => ref.read(provider.notifier).loadMore(),
          )
        else if (_expanded && list.items.length > CommentRules.replyPreview)
          _ExpandButton(
            label: '收起',
            up: true,
            onTap: () => setState(() => _expanded = false),
          ),
      ],
    );
  }
}

/// "—— 展开 N 条回复 ⌄": 前面一小段横线, 灰色加粗小字. [up] 时箭头朝上, 用于 "收起".
class _ExpandButton extends StatelessWidget {
  const new({required this.label, required this.onTap, this.up = false});

  final String label;
  final VoidCallback onTap;
  final bool up;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return EatTappable(
      onTap: onTap,
      builder: (context, _) => SizedBox(
        height: EatSize.touch,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: EatSpace.s8,
          children: [
            SizedBox(
              width: 20,
              height: 1,
              child: ColoredBox(color: eat.colors.inkMuted),
            ),
            Text(
              label,
              style: eat.text.meta.copyWith(
                fontWeight: FontWeight.w600,
                color: eat.colors.ink,
              ),
            ),
            RotatedBox(
              quarterTurns: up ? 2 : 0,
              child: EatIcon(
                EatIcons.chevronDown,
                size: 16,
                color: eat.colors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 一条回复: 和评论同样的排法, 头像小一号, 写成 "A 回复 B".
class _ReplyLine extends ConsumerWidget {
  const new({required this.root, required this.reply});

  final Comment root;
  final Comment reply;

  static const _avatar = 24.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reactions = _reactionsOf(ref, reply);
    void onReply() => _reply(context, ref, root, to: reply);
    return Padding(
      padding: const EdgeInsets.only(top: EatSpace.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: EatSpace.s8,
        children: [
          EatAvatar(
            name: reply.authorName,
            color: avatarColorOf(reply.authorId),
            image: networkImage(reply.authorAvatar, width: _avatar),
            size: _avatar,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Text(comment: reply, onReply: onReply),
                _Actions(comment: reply, reactions: reactions),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _MenuAction { delete, report }

/// 打开评论操作面板, 本人评论显示 "删除", 他人评论显示 "举报".
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mine)
            EatPanelAction(
              icon: EatIcons.delete,
              label: '删除',
              onTap: () => Navigator.of(panel).pop(_MenuAction.delete),
            )
          else
            EatPanelAction(
              icon: EatIcons.report,
              label: '举报',
              onTap: () => Navigator.of(panel).pop(_MenuAction.report),
            ),
        ],
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

/// 若服务端返回 [comment] 已不存在, 则提示已删除并将其从本地列表移除后返回 true. 其他失败返回 false.
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
