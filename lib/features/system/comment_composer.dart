import 'dart:async';

import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/core/platform/photo_picker.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/code_point_limit.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_dialog.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/morph_card.dart';
import 'package:eat/design/widgets/tap_outside.dart';
import 'package:eat/domain/rules/comment_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/system/comment_composer_providers.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/state/comments.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart'
    show Material, MaterialType, TextField, InputDecoration, InputBorder;

/// 写评论或回复的输入框, 不跳新页面.
///
/// - 写评论 ([reply] 为 null): 放在评论区里. 平时是一条 "吃过的话，说两句" 的胶囊, 右边一个相机; 点了就地展开成多行输入, 弹出键盘.
///   文字最多 200 字, 照片最多 3 张, 两者至少有一样. 展开后右下角是 "发送", 左下角是加照片和 "全屏".
/// - 回复: 由 [showReplyBar] 放在屏幕最下面的横条里, 贴着键盘, 一出现就弹键盘. 占位写 "回复 小林", 只能写字;
///   输入框右边是 "全屏", 横条最右边是 "发送". 发出或点横条外面时收起.
/// - 全屏时同一份草稿铺满屏幕写, 收起后回到原处.
/// - 发送成功后清空并收起, 内容立即公开; 失败时保留内容以便重试.
/// - 写了内容没发就离开页面时确认是否放弃.
class CommentComposer extends ConsumerStatefulWidget {
  const new({super.key, required this.dishId, this.reply});

  final int dishId;

  /// 回复的对象. 为 null 时写的是评论.
  final ReplyTarget? reply;

  @override
  ConsumerState<CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends ConsumerState<CommentComposer> {
  final _text = TextEditingController();
  final _focus = FocusNode();

  /// 输入框外面那个框. 全屏从它展开.
  final _box = GlobalKey();

  /// 收起时右边的相机.
  final _camera = GlobalKey();

  /// 展开后工具行里的相机.
  final _toolbarCamera = GlobalKey();

  /// 写评论的输入框是否展开. 回复框一出现就是展开的.
  late var _open = widget.reply != null;

  bool get _isReply => widget.reply != null;

  CommentDraftProvider get _draft =>
      commentDraftProvider(widget.dishId, widget.reply?.rootId);

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
    _focus.addListener(_onFocus);
    if (_isReply) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _focus
      ..removeListener(_onFocus)
      ..dispose();
    super.dispose();
  }

  bool get _empty =>
      _text.text.trim().isEmpty && ref.read(_draft).photos.isEmpty;

  /// 写评论的输入框没内容又失去焦点时收回成胶囊.
  void _onFocus() {
    if (!_focus.hasFocus) _collapseIfEmpty();
  }

  /// 上面盖着全屏或卡片时不收: 焦点是被它们拿走的, 回来时再看.
  void _collapseIfEmpty() {
    if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
    if (!_isReply && _empty && _open) {
      setState(() => _open = false);
    }
  }

  /// 点在框外面: 失焦, 没内容就收回. 输入框不在焦点上时 (如刚从全屏回来) 不会再有失焦, 所以这里也要收.
  /// 上面盖着全屏或卡片时, 点的是它们, 不算点在外面.
  void _tapOutside(PointerDownEvent event) {
    if (ModalRoute.of(context)?.isCurrent == false) return;
    _focus.unfocus();
    _collapseIfEmpty();
  }

  /// 展开输入框并弹键盘. [photo] 时先从相机展开加照片的卡片, 选到照片才展开, 没选就保持原样.
  Future<void> _expand({bool photo = false}) async {
    if (!await guardAction(context, ref, Capability.comment) || !mounted) {
      return;
    }
    if (photo) {
      final picked = await _pickPhotos(
        CommentRules.photoMax,
        origin: _camera,
        from: context.eat.colors.mist,
        fromRadius: const Radius.circular(24),
        face: (_) => const _CameraCircle(),
      );
      if (!mounted || picked.isEmpty) return;
      ref.read(_draft.notifier).addPhotos(picked);
      setState(() => _open = true);
      return;
    }
    setState(() => _open = true);
    _focus.requestFocus();
  }

  /// 从 [origin] 那个相机按钮加照片.
  Future<void> _addPhotos(GlobalKey origin) async {
    final room = CommentRules.photoMax - ref.read(_draft).photos.length;
    if (room <= 0) return;
    final photos = await _pickPhotos(
      room,
      origin: origin,
      from: context.eat.colors.paper,
      fromRadius: const Radius.circular(EatSize.touch / 2),
      face: (_) => const _CameraIcon(),
    );
    if (!mounted || photos.isEmpty) return;
    ref.read(_draft.notifier).addPhotos(photos);
  }

  /// 从相机按钮展开 "加照片" 的卡片 (和评分卡一样), 选相册或拍照. 最多选 [limit] 张.
  Future<List<PickedPhoto>> _pickPhotos(
    int limit, {
    required GlobalKey origin,
    required Color from,
    required Radius fromRadius,
    required WidgetBuilder face,
  }) async {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4);
    final camera = await showMorphCard<bool>(
      context,
      origin: origin,
      from: from,
      fromRadius: fromRadius,
      height: 172 * scale,
      barrierLabel: '加照片',
      face: face,
      builder: (_) => const _PhotoSourceCard(),
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

  /// 发送. 成功时返回 true.
  Future<bool> _send() async {
    final reply = widget.reply;
    final capability = _isReply ? Capability.reply : Capability.comment;
    if (!await guardAction(context, ref, capability) || !mounted) return false;
    try {
      await ref
          .read(_draft.notifier)
          .send(_text.text, replyToId: reply?.replyToId);
      if (!mounted) return true;
      showToast(context, '发送成功');
      _text.clear();
      ref.read(_draft.notifier).clear();
      _focus.unfocus();
      if (reply != null) {
        _closeBar();
      } else {
        setState(() => _open = false);
      }
      return true;
    } on AppFailure catch (e) {
      if (!mounted) return false;
      if (reply != null && e.code == BizCodes.stateNotAllowed) {
        showToast(context, '无法回复对方');
        return false;
      }
      if (reply != null && isCommentGone(e)) {
        ref
            .read(commentWriterProvider.notifier)
            .refreshThread(widget.dishId, reply.rootId);
        _closeBar();
        showToast(context, '这条评论已删除');
        return false;
      }
      await reportActionFailure(
        context,
        ref,
        e,
        capability: capability,
        fallback: '发送失败，请重试',
      );
      return false;
    }
  }

  /// 收起回复横条. 清空后要等重建, [PopScope] 换成可以返回了再退出, 否则会被当成没发出而拦下.
  void _closeBar() {
    _focus.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<bool> _confirmDiscard() async =>
      await showEatDialog<bool>(
        context,
        builder: (dialog) => EatDialog(
          icon: EatIcons.warning,
          title: _isReply ? '放弃这条回复？' : '放弃这条评论？',
          actions: Row(
            spacing: EatSpace.s10,
            children: [
              Expanded(
                child: EatButton.mist(
                  '放弃',
                  onPressed: () => Navigator.of(dialog).pop(true),
                ),
              ),
              Expanded(
                child: EatButton.solid(
                  '继续写',
                  onPressed: () => Navigator.of(dialog).pop(false),
                ),
              ),
            ],
          ),
        ),
      ) ??
      false;

  /// 输入框从原处展开到全屏, 退出时收回原处. 两边共用同一份文字和照片.
  Future<void> _fullscreen() async {
    final c = context.eat.colors;
    await showMorphCard<void>(
      context,
      origin: _box,
      from: _isReply ? c.mist : c.paper,
      fromRadius: _isReply ? const Radius.circular(22) : EatRadius.thumbLg,
      fullscreen: true,
      barrierLabel: _isReply ? '回复 ${widget.reply!.name}' : '写一条',
      face: (_) => const SizedBox(),
      builder: (route) => _FullscreenEditor(
        dishId: widget.dishId,
        reply: widget.reply,
        text: _text,
        onAddPhotos: _addPhotos,
        onSend: () async {
          final sent = await _send();
          if (sent && route.mounted) Navigator.of(route).pop();
        },
      ),
    );
    if (!mounted) return;
    if (_empty) {
      _collapseIfEmpty();
    } else {
      _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(_draft);
    final dirty = _text.text.trim().isNotEmpty || draft.photos.isNotEmpty;
    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!await _confirmDiscard() || !mounted) return;
        _text.clear();
        ref.read(_draft.notifier).clear();
        // 清空后要等重建, PopScope 换成可以返回了再退出, 否则会再拦一次.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(this.context).pop();
        });
      },
      child: _isReply ? _bar(context, draft) : _composer(context, draft),
    );
  }

  /// 展开和收起时高度平滑过渡. 系统开启减少动态效果时直接换, 时长为零的 [AnimatedSize] 会在布局中途重排.
  Widget _animatedSize(
    BuildContext context,
    Widget child, {
    Alignment alignment = Alignment.topCenter,
  }) {
    final duration = context.motion(EatMotion.select);
    if (duration == Duration.zero) return child;
    return AnimatedSize(
      duration: duration,
      alignment: alignment,
      curve: Curves.easeOutCubic,
      child: child,
    );
  }

  /// 写评论: 收起时是一条胶囊, 右边一个相机; 展开时胶囊自己长成描边的框, 里面是多行输入, 已加的照片和工具行.
  /// 底色, 描边, 圆角和高度一起过渡, 里面的内容交叉淡入淡出, 相机向右收起.
  Widget _composer(BuildContext context, Composer draft) {
    final c = context.eat.colors;
    final duration = context.motion(EatMotion.select);
    const curve = Curves.easeOutCubic;
    final open = _open;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFieldTapRegion(
            onTapOutside: open ? _tapOutside : null,
            child: AnimatedContainer(
              key: _box,
              duration: duration,
              curve: curve,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: open ? c.paper : c.mist,
                borderRadius: BorderRadius.all(
                  open ? EatRadius.thumbLg : const Radius.circular(24),
                ),
                border: Border.all(color: open ? c.ink : c.mist, width: 1.5),
              ),
              child: _animatedSize(
                context,
                AnimatedSwitcher(
                  duration: duration,
                  // 旧内容很快退掉, 两句占位不会叠在一起.
                  reverseDuration: duration ~/ 3,
                  switchInCurve: curve,
                  switchOutCurve: curve,
                  // 旧内容不撑高度, 高度跟着新内容走, 和淡入淡出同时过渡.
                  layoutBuilder: (current, previous) => Stack(
                    children: [
                      for (final child in previous)
                        Positioned(left: 0, right: 0, top: 0, child: child),
                      ?current,
                    ],
                  ),
                  child: open
                      ? KeyedSubtree(
                          key: const ValueKey(true),
                          child: _expandedContent(context, draft),
                        )
                      : KeyedSubtree(
                          key: const ValueKey(false),
                          child: _collapsedContent(context),
                        ),
                ),
              ),
            ),
          ),
        ),
        _animatedSize(
          context,
          open
              ? const SizedBox(height: 48)
              : Padding(
                  padding: const EdgeInsets.only(left: EatSpace.s10),
                  child: EatTappable(
                    key: _camera,
                    onTap: () => _expand(photo: true),
                    label: '带照片写一条',
                    focusShape: const CircleBorder(),
                    builder: (context, _) => const _CameraCircle(),
                  ),
                ),
          alignment: Alignment.centerLeft,
        ),
      ],
    );
  }

  /// 收起时胶囊里: 笔和 "吃过的话，说两句".
  Widget _collapsedContent(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    return EatTappable(
      onTap: _expand,
      label: '写一条',
      builder: (context, _) => SizedBox(
        height: 45,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: EatSpace.s14),
          child: Row(
            spacing: EatSpace.s10,
            children: [
              EatIcon(EatIcons.edit, size: 18, color: c.ink),
              Expanded(
                child: Text(
                  '吃过的话，说两句',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: eat.text.body.copyWith(color: c.inkMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 展开时框里: 多行输入, 已加的照片, 下面一行工具和 "发送".
  Widget _expandedContent(BuildContext context, Composer draft) {
    final ready = CommentRules.canSend(
      _text.text,
      photos: draft.photos.length,
      reply: false,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EatSpace.s14 - 1.5,
        EatSpace.s8 - 1.5,
        EatSpace.s8 - 1.5,
        EatSpace.s8 - 1.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Field(
            controller: _text,
            focusNode: _focus,
            hint: _hint,
            label: '评论内容',
            minLines: 3,
            maxLines: 8,
          ),
          if (draft.photos.isNotEmpty) ...[
            const SizedBox(height: EatSpace.s8),
            _PhotoStrip(
              draft: draft,
              onRemove: (id) => ref.read(_draft.notifier).removePhoto(id),
            ),
          ],
          const SizedBox(height: EatSpace.s4),
          _Toolbar(
            length: CommentRules.length(_text.text),
            reply: false,
            canAddPhoto: draft.photos.length < CommentRules.photoMax,
            sending: draft.sending,
            ready: ready,
            cameraKey: _toolbarCamera,
            onAddPhotos: () => _addPhotos(_toolbarCamera),
            onFullscreen: _fullscreen,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  /// 回复横条: 浅底的输入框随字数长高 (最多 5 行), 框里右边是 "全屏", 框外最右边是 "发送".
  Widget _bar(BuildContext context, Composer draft) {
    final c = context.eat.colors;
    final ready = CommentRules.canSend(_text.text, photos: 0, reply: true);
    return TextFieldTapRegion(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: EatSpace.s10,
        children: [
          Expanded(
            child: Container(
              key: _box,
              constraints: const BoxConstraints(minHeight: EatSize.touch),
              padding: const EdgeInsets.only(left: EatSpace.s16),
              decoration: BoxDecoration(
                color: c.mist,
                borderRadius: const BorderRadius.all(Radius.circular(22)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _Field(
                      controller: _text,
                      focusNode: _focus,
                      hint: _hint,
                      label: '回复内容',
                      minLines: 1,
                      maxLines: 5,
                      vertical: 11,
                    ),
                  ),
                  EatIconButton(
                    EatIcons.expand,
                    label: '全屏',
                    size: 20,
                    color: c.inkMuted,
                    onPressed: _fullscreen,
                  ),
                ],
              ),
            ),
          ),
          EatButton.solid(
            '发送',
            height: EatSize.touch,
            loading: draft.sending,
            onPressed: ready ? _send : null,
          ),
        ],
      ),
    );
  }

  String get _hint => switch (widget.reply) {
    final reply? => '回复 ${reply.name}',
    null => '吃过的话，说两句',
  };
}

/// 不带边框的多行输入. 外面的框由使用者画.
class _Field extends StatelessWidget {
  const new({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.label,
    this.minLines,
    this.maxLines,
    this.expands = false,
    this.vertical = EatSpace.s8,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final String label;
  final int? minLines;
  final int? maxLines;
  final bool expands;

  /// 文字上下的留白. 回复横条里只有一行时要撑够 44px 的点击高度.
  final double vertical;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final style = eat.text.body.copyWith(color: c.ink);
    return Semantics(
      label: label,
      child: Material(
        type: MaterialType.transparency,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onTapOutside: unfocusOnTapOutside,
          minLines: expands ? null : minLines,
          maxLines: expands ? null : maxLines,
          expands: expands,
          textAlignVertical: TextAlignVertical.top,
          keyboardType: TextInputType.multiline,
          inputFormatters: const [
            CodePointLengthLimitingFormatter(CommentRules.textMax),
          ],
          style: style,
          cursorColor: c.ink,
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: vertical),
            hintText: hint,
            hintStyle: style.copyWith(color: c.inkMuted),
          ),
        ),
      ),
    );
  }
}

/// 输入框下面一行: 左边加照片和全屏, 右边字数和发送, 发送贴着右边.
class _Toolbar extends StatelessWidget {
  const new({
    required this.length,
    required this.reply,
    required this.canAddPhoto,
    required this.sending,
    required this.ready,
    required this.cameraKey,
    required this.onAddPhotos,
    required this.onFullscreen,
    required this.onSend,
    this.fullscreen = false,
  });

  final int length;
  final bool reply;
  final bool canAddPhoto;
  final bool sending;
  final bool ready;

  /// 加照片按钮. "加照片" 的卡片从它展开.
  final GlobalKey cameraKey;
  final VoidCallback onAddPhotos;
  final VoidCallback onFullscreen;
  final VoidCallback onSend;

  /// 是否在全屏编辑里. 全屏时 "全屏" 换成 "退出全屏".
  final bool fullscreen;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final counter = eat.text.count.copyWith(color: c.inkMuted);
    return Row(
      children: [
        if (!reply)
          KeyedSubtree(
            key: cameraKey,
            child: EatIconButton(
              EatIcons.camera,
              label: '加照片',
              color: c.ink,
              onPressed: canAddPhoto && !sending ? onAddPhotos : null,
            ),
          ),
        EatIconButton(
          fullscreen ? EatIcons.collapse : EatIcons.expand,
          label: fullscreen ? '退出全屏' : '全屏',
          size: 20,
          color: c.ink,
          onPressed: onFullscreen,
        ),
        Expanded(
          child: ExcludeSemantics(
            child: Text(
              '$length / ${CommentRules.textMax}',
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              textAlign: TextAlign.end,
              style: counter,
            ),
          ),
        ),
        const SizedBox(width: EatSpace.s8),
        EatButton.solid(
          '发送',
          height: 36,
          loading: sending,
          onPressed: ready ? onSend : null,
        ),
      ],
    );
  }
}

/// 已加的照片, 一排小图, 每张右上角一个去掉的按钮.
class _PhotoStrip extends StatelessWidget {
  const new({required this.draft, required this.onRemove, this.size = 72});

  final Composer draft;
  final ValueChanged<int> onRemove;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    return Wrap(
      spacing: EatSpace.s10,
      runSpacing: EatSpace.s10,
      children: [
        for (final (i, photo) in draft.photos.indexed)
          SizedBox.square(
            dimension: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(EatRadius.thumb),
                  child: SizedBox.square(
                    dimension: size,
                    child: CoverImage(image: MemoryImage(photo.photo.bytes)),
                  ),
                ),
                Positioned(
                  right: -12,
                  top: -12,
                  child: EatTappable(
                    onTap: draft.sending ? null : () => onRemove(photo.id),
                    label: '去掉第 ${i + 1} 张照片',
                    focusShape: const CircleBorder(),
                    builder: (context, _) => SizedBox.square(
                      dimension: EatSize.touch,
                      child: Center(
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: c.ink,
                            shape: BoxShape.circle,
                            border: Border.all(color: c.paper, width: 2),
                          ),
                          child: Center(
                            child: EatIcon(
                              EatIcons.close,
                              size: 12,
                              color: c.paper,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 在屏幕最下面弹出回复 [target] 的横条, 贴着键盘. 点横条外面收起; 写了内容时先确认是否放弃.
Future<void> showReplyBar(
  BuildContext context, {
  required int dishId,
  required ReplyTarget target,
}) => Navigator.of(context).push(
  _ReplyBarRoute(
    dishId: dishId,
    target: target,
    scrim: context.eat.colors.scrim.withValues(alpha: 0.2),
  ),
);

/// 回复横条的路由: 一层很淡的遮罩, 横条从下面滑上来.
class _ReplyBarRoute extends PopupRoute<void> {
  _ReplyBarRoute({
    required this.dishId,
    required this.target,
    required this.scrim,
  });

  final int dishId;
  final ReplyTarget target;
  final Color scrim;

  @override
  Color? get barrierColor => scrim;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => '收起回复';

  @override
  Duration get transitionDuration => EatMotion.dialog.duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final c = context.eat.colors;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final safe = MediaQuery.paddingOf(context).bottom;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.paper,
            border: Border(top: BorderSide(color: c.hairline)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              EatSpace.s16,
              EatSpace.s10,
              EatSpace.s16,
              EatSpace.s10 + (keyboard > 0 ? 0 : safe),
            ),
            child: CommentComposer(dishId: dishId, reply: target),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return SlideTransition(
      position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
        CurvedAnimation(parent: animation, curve: EatMotion.dialog.curve),
      ),
      child: child,
    );
  }
}

/// 全屏编辑: 和就地的输入框共用同一份文字和照片. 上面一行是退出全屏和标题, 下面整屏是输入区, 最下面是照片和工具行.
class _FullscreenEditor extends ConsumerStatefulWidget {
  const new({
    required this.dishId,
    required this.reply,
    required this.text,
    required this.onAddPhotos,
    required this.onSend,
  });

  final int dishId;
  final ReplyTarget? reply;
  final TextEditingController text;
  final ValueChanged<GlobalKey> onAddPhotos;
  final VoidCallback onSend;

  @override
  ConsumerState<_FullscreenEditor> createState() => _FullscreenEditorState();
}

class _FullscreenEditorState extends ConsumerState<_FullscreenEditor> {
  final _focus = FocusNode();
  final _camera = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.text.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    widget.text.removeListener(_changed);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final reply = widget.reply;
    final provider = commentDraftProvider(widget.dishId, reply?.rootId);
    final draft = ref.watch(provider);
    final padding = MediaQuery.paddingOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final dish = ref.watch(commentedDishProvider(widget.dishId)).value;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: c.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: c.paper,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            EatSpace.s20,
            padding.top + EatSpace.s8,
            EatSpace.s14,
            (keyboard > 0 ? keyboard : padding.bottom) + EatSpace.s8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            reply == null ? '写一条' : '回复 ${reply.name}',
                            style: eat.text.heading.copyWith(color: c.ink),
                          ),
                        ),
                        if (dish != null)
                          Text(
                            [dish.name, ?dish.shopName].join('  '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: eat.text.meta.copyWith(color: c.inkMuted),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: EatSpace.s10),
              Expanded(
                child: _Field(
                  controller: widget.text,
                  focusNode: _focus,
                  hint: reply == null ? '吃过的话，说两句' : '回复 ${reply.name}',
                  label: reply == null ? '评论内容' : '回复内容',
                  expands: true,
                ),
              ),
              if (draft.photos.isNotEmpty) ...[
                const SizedBox(height: EatSpace.s8),
                _PhotoStrip(
                  draft: draft,
                  size: 64,
                  onRemove: (id) => ref.read(provider.notifier).removePhoto(id),
                ),
              ],
              const SizedBox(height: EatSpace.s4),
              _Toolbar(
                length: CommentRules.length(widget.text.text),
                reply: reply != null,
                canAddPhoto: draft.photos.length < CommentRules.photoMax,
                sending: draft.sending,
                ready: CommentRules.canSend(
                  widget.text.text,
                  photos: draft.photos.length,
                  reply: reply != null,
                ),
                cameraKey: _camera,
                onAddPhotos: () => widget.onAddPhotos(_camera),
                onFullscreen: () => Navigator.of(context).pop(),
                onSend: widget.onSend,
                fullscreen: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 收起时右边的相机: 浅底圆, 和胶囊一样高.
class _CameraCircle extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: c.mist, shape: BoxShape.circle),
      child: Center(child: EatIcon(EatIcons.camera, size: 22, color: c.ink)),
    );
  }
}

/// 工具行里的相机图标, "加照片" 的卡片展开和收回时画它.
class _CameraIcon extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: EatSize.touch,
    child: Center(
      child: EatIcon(EatIcons.camera, size: 22, color: context.eat.colors.ink),
    ),
  );
}

/// "加照片" 卡片: 标题和提示, 下面 "从相册选" 和 "拍一张". 关掉时返回 null, 选相册返回 false, 拍照返回 true.
class _PhotoSourceCard extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EatSpace.s20,
        EatSpace.s14,
        EatSpace.s8,
        EatSpace.s20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        '加照片',
                        style: eat.text.heading.copyWith(color: c.ink),
                      ),
                    ),
                    Text(
                      '请上传这道菜的实拍，不要用网图或菜单截图',
                      style: eat.text.meta.copyWith(color: c.inkMuted),
                    ),
                  ],
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
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: EatSpace.s14 - 2),
            child: Row(
              spacing: EatSpace.s10,
              children: [
                Expanded(
                  child: EatButton.mist(
                    '从相册选',
                    icon: EatIcons.image,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                Expanded(
                  child: EatButton.solid(
                    '拍一张',
                    icon: EatIcons.camera,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
