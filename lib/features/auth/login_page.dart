import 'dart:math' as math;

import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/platform/browser.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/emoji.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/icons/illustrations.dart';
import 'package:eat/design/layout/eat_layout.dart';
import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/theme/stage_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_stage.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/features/auth/auth_providers.dart';
import 'package:eat/router/paths.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 登录页.
///
/// - 舞台: 汤色底, 装饰转盘, 品牌字和简介.
/// - 抽屉: "手机号登录" 按钮和协议勾选.
///
/// 未勾选协议时按钮显示为不可用样式, 但仍响应点击.
/// 点击后不跳转, 而是晃动协议行, 触发轻震, 并显示勾选提示.
///
/// [query] 包含地址中的 `from` 和 `expired`, 原样传给手机号登录页.
/// 登录成功后, 守卫据此返回原页面.
class LoginPage extends ConsumerStatefulWidget {
  const new({super.key, this.query = const {}});

  final Map<String, String> query;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  /// 未勾选协议时点击按钮的次数. 每次递增触发协议行晃动一次.
  ///
  /// 勾选后归零并隐藏提示. 之后取消勾选不会立即提示, 再次点击按钮时才提示.
  var _nudges = 0;

  void _start() {
    if (!ref.read(loginAgreementProvider)) {
      HapticFeedback.mediumImpact();
      setState(() => _nudges++);
      return;
    }
    final query = widget.query;
    context.go(
      Uri(
        path: Paths.loginPhone,
        queryParameters: query.isEmpty ? null : query,
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final query = widget.query;
    final agreed = ref.watch(loginAgreementProvider);
    ref.listen(loginAgreementProvider, (_, agreed) {
      if (agreed) setState(() => _nudges = 0);
    });
    final media = MediaQuery.of(context);
    final sheet = DecoratedBox(
      decoration: BoxDecoration(
        color: c.paper,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(_sheetRadius),
        ),
        boxShadow: eat.shadows.sheet.outer,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          _sheetInset,
          _sheetInset,
          _sheetInset,
          _sheetBottom + media.padding.bottom,
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: c.ink),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: EatSpace.s10,
            children: [
              if (query['expired'] == '1') const _Notice('登录已过期，请重新登录'),
              EatButton.solid(
                '手机号登录',
                icon: EatIcons.phone,
                muted: !agreed,
                onPressed: _start,
              ),
              AgreementCheck(nudges: _nudges),
            ],
          ),
        ),
      ),
    );
    // 纵向布局: 品牌字在顶部, 抽屉贴底, 转盘绘制在两者之间, 下半部分被抽屉遮挡.
    // 屏幕的富余高度按 1:8 分给品牌字上方留白和转盘, 避免中间出现大块空白.
    // 矮屏或大字号下内容超出屏幕时整页滚动, 避免品牌字与抽屉重叠.
    // 不回弹也不拉伸: 越界拖动会改变 SliverFillRemaining 的高度, 转盘随之变形.
    return EatStage(
      stage: StageColor.broth,
      child: CustomScrollView(
        scrollBehavior: ScrollConfiguration.of(
          context,
        ).copyWith(overscroll: false, physics: const ClampingScrollPhysics()),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              children: [
                const Spacer(),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    EatSpace.s24,
                    media.padding.top + _brandTop,
                    EatSpace.s24,
                    EatSpace.s24,
                  ),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: _Brand(),
                  ),
                ),
                const Expanded(
                  flex: 8,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [Positioned.fill(child: _Turntable())],
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: EatLayout.plainMaxWidth,
                  ),
                  child: sheet,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 抽屉上边和左右的内边距, 三边相等, 圆角才能和按钮同心.
  static const _sheetInset = EatSpace.s20;

  /// 抽屉顶部的圆角. 取按钮的半径加内边距, 和按钮的圆角同心.
  static const _sheetRadius = EatSize.button / 2 + _sheetInset;

  /// 抽屉内容与屏幕底边的距离. 大于上边距, 避免按钮贴近底边.
  static const _sheetBottom = 44.0;

  /// 品牌字与状态栏的最小距离.
  static const _brandTop = 36.0;
}

class _Brand extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final palette = StageTheme.of(context);
    final intro = eat.text.body.copyWith(
      height: 22 / 15,
      color: palette.secondaryForeground,
    );
    return Semantics(
      header: true,
      label: '沙软今天吃什么',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '沙软',
              style: eat.text.body.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: palette.foreground,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '今天\n吃什么',
              textScaler: TextScaler.noScaling,
              style: eat.text.loginDisplay.copyWith(color: palette.foreground),
            ),
            const SizedBox(height: EatSpace.s14),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: '是啊，吃什么'),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: EmojiImage(Emoji.thinking, size: intro.fontSize!),
                    ),
                  ),
                ],
              ),
              style: intro,
            ),
          ],
        ),
      ),
    );
  }
}

/// 登录页的装饰转盘. 匀速旋转, 系统开启减少动态效果时停止.
///
/// 外观与发现页转盘一致, 但不响应拖动和点击, 因此不复用 `Turntable`.
class _Turntable extends StatefulWidget {
  const new();

  @override
  State<_Turntable> createState() => _TurntableState();
}

class _TurntableState extends State<_Turntable>
    with SingleTickerProviderStateMixin {
  static const _dishes = [
    Illustration.yuntun,
    Illustration.niunan,
    Illustration.yangzhi,
    Illustration.luosifen,
    Illustration.tieguodun,
    Illustration.xiangguo,
    Illustration.niandoubao,
    Illustration.jiaozi,
    Illustration.yuntun,
    Illustration.yangzhi,
    Illustration.xiangguo,
    Illustration.jiaozi,
  ];

  /// 相对发现页转盘的放大倍数. 登录页没有主角菜, 转盘作为舞台的视觉主体.
  static const _scale = 1.2;
  static const _dish = 220 * _scale;
  static const _radius = EatSize.turntableRadius * _scale;
  static const _ringOffset = Offset(-36 * _scale, -17 * _scale);
  static const _tableRadius = 600 * _scale;
  static const _tableRingRadius = 560 * _scale;

  /// 桌面圆心到最上方菜品上缘的距离.
  static const _ringTop = _radius + _dish / 2 + 17 * _scale;
  static const _maxVisible = 320.0;

  /// 空隙顶部到菜品上缘的最小距离.
  ///
  /// 桌面圆的顶部高于菜品上缘. 预留这段距离, 桌面才不会越过空隙顶部.
  static const _clearance = _tableRadius - _ringTop + 4;

  late final _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 90),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _spin.stop();
    } else if (!_spin.isAnimating) {
      _spin.repeat();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = StageTheme.of(context);
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 菜品环的圆心相对桌面圆心向左上偏移, 旋转时菜品上缘因此高低起伏, 不形成平滑圆弧.
          // 转盘在抽屉上方的露出高度随空隙变化, 上限为 [_maxVisible].
          // 桌面和菜品上缘与空隙顶部至少相距 [_clearance], 避免压住品牌字.
          final gap = constraints.maxHeight;
          final visible = (gap - _clearance).clamp(0.0, _maxVisible);
          final table = Offset(
            constraints.maxWidth / 2,
            gap + _ringTop - visible,
          );
          final center = table + _ringOffset;
          const radius = _radius;
          const extent = radius + _dish / 2;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: table.dx - _tableRadius,
                top: table.dy - _tableRadius,
                child: Container(
                  width: _tableRadius * 2,
                  height: _tableRadius * 2,
                  decoration: BoxDecoration(
                    color: palette.table,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: table.dx - _tableRingRadius,
                top: table.dy - _tableRingRadius,
                child: Container(
                  width: _tableRingRadius * 2,
                  height: _tableRingRadius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: palette.tableRing, width: 1.5),
                  ),
                ),
              ),
              Positioned(
                left: center.dx - extent,
                top: center.dy - extent,
                width: extent * 2,
                height: extent * 2,
                child: RotationTransition(
                  turns: ReverseAnimation(_spin),
                  child: Stack(
                    children: [
                      for (final (i, dish) in _dishes.indexed)
                        Positioned(
                          left:
                              extent +
                              radius * math.sin(i * math.pi / 6) -
                              _dish / 2,
                          top:
                              extent -
                              radius * math.cos(i * math.pi / 6) -
                              _dish / 2,
                          child: Transform.rotate(
                            angle: i * math.pi / 6,
                            child: IllustrationImage(dish, size: _dish),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 协议勾选行. 左侧为勾选框, 协议名可点击查看.
///
/// [nudges] 每递增一次, 整行水平晃动一次.
/// [nudges] 大于 0 时, 下方淡入 `warn` 色提示 "请先勾选同意协议".
/// 提示行始终占位, 提示出现时抽屉高度不变.
class AgreementCheck extends ConsumerStatefulWidget {
  const new({super.key, this.nudges = 0});

  final int nudges;

  @override
  ConsumerState<AgreementCheck> createState() => _AgreementCheckState();
}

class _AgreementCheckState extends ConsumerState<AgreementCheck>
    with SingleTickerProviderStateMixin {
  late final _privacy = TapGestureRecognizer()
    ..onTap = () => _open(ref.read(appConfigProvider).privacyUrl);
  late final _terms = TapGestureRecognizer()
    ..onTap = () => _open(ref.read(appConfigProvider).termsUrl);
  late final _shake = AnimationController(
    vsync: this,
    duration: _shakeDuration,
  );

  static const _shakeDuration = Duration(milliseconds: 420);

  /// 晃动的初始振幅和往返次数. 振幅随动画进度线性衰减到 0.
  static const _shakeAmplitude = 6.0;
  static const _shakeCycles = 3;

  /// 文字相对勾选框上移的距离. 汉字字面在行框里偏下,
  /// 行框和圆按几何中心对齐时文字看起来比圆低, 上移后两者的视觉中心对齐.
  static const _opticalLift = 1.0;

  @override
  void didUpdateWidget(AgreementCheck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.nudges > oldWidget.nudges &&
        !MediaQuery.disableAnimationsOf(context)) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _privacy.dispose();
    _terms.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _open(String url) {
    if (url.isNotEmpty) ref.read(browserProvider).open(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final agreed = ref.watch(loginAgreementProvider);
    final showHint = widget.nudges > 0 && !agreed;
    final fade = context.motion(EatMotion.select);
    void toggle() {
      HapticFeedback.selectionClick();
      ref.read(loginAgreementProvider.notifier).set(agreed: !agreed);
    }

    /// 下划线只画在协议名下, 书名号不画, 否则线两端会悬空.
    TextSpan link(String name, TapGestureRecognizer recognizer) => TextSpan(
      style: const TextStyle(fontWeight: FontWeight.w600),
      children: [
        TextSpan(text: '《', recognizer: recognizer),
        TextSpan(
          text: name,
          style: TextStyle(
            decoration: TextDecoration.underline,
            decorationColor: c.inkSoft,
          ),
          recognizer: recognizer,
        ),
        TextSpan(text: '》', recognizer: recognizer),
      ],
    );
    final style = eat.text.meta.copyWith(color: c.inkSoft, height: 20 / 13);

    /// 勾选框的点击区域比圆大, 圆的左右各空出 [inset].
    /// 文字左移到离圆 [gap] 处, 行尾补同样宽的空白, 整行左右的空白相等,
    /// 居中后看到的圆加文字一组正好在中间.
    const inset = (EatSize.touch - 20) / 2;
    const gap = 6.0;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EatTappable(
          onTap: toggle,
          label: '同意隐私政策和用户协议',
          checked: agreed,
          button: false,
          focusShape: const CircleBorder(),
          builder: (context, _) => SizedBox.square(
            dimension: EatSize.touch,
            child: Center(child: _CheckCircle(checked: agreed)),
          ),
        ),
        Flexible(
          child: Transform.translate(
            offset: const Offset(gap - inset, 0),
            child: Padding(
              padding: const EdgeInsets.only(
                top: (EatSize.touch - 20) / 2 - _opticalLift,
              ),
              child: GestureDetector(
                onTap: toggle,
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: '我已阅读并同意'),
                      link('隐私政策', _privacy),
                      const TextSpan(text: '和'),
                      link('用户协议', _terms),
                    ],
                  ),
                  style: style,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: gap),
      ],
    );
    final hint = ExcludeSemantics(
      excluding: !showHint,
      child: AnimatedSlide(
        offset: showHint ? Offset.zero : const Offset(0, -0.3),
        duration: fade,
        curve: EatMotion.select.curve,
        child: AnimatedOpacity(
          opacity: showHint ? 1 : 0,
          duration: fade,
          curve: EatMotion.select.curve,
          child: Semantics(
            liveRegion: true,
            child: Text(
              '请先勾选同意协议',
              textAlign: TextAlign.center,
              style: style.copyWith(color: c.warn),
            ),
          ),
        ),
      ),
    );

    /// 行尾的全角 "》" 字面只占左半边, 右半边是空白.
    /// 整组按这段空白的一半右移, 看上去才居中.
    final bracketSpace =
        MediaQuery.textScalerOf(context).scale(style.fontSize!) / 2;

    /// 提示紧贴协议文字下方, 和勾选框的点击区域重叠, 所以用 Stack 而不是 Column.
    final content = Align(
      heightFactor: 1,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: inset - _opticalLift + 20 + EatSpace.s4,
            ),
            child: hint,
          ),
          Transform.translate(offset: Offset(bracketSpace / 2, 0), child: row),
        ],
      ),
    );
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        final dx =
            math.sin(t * math.pi * 2 * _shakeCycles) *
            _shakeAmplitude *
            (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: content,
    );
  }
}

/// 勾选框. 勾选时圆底由 `paper` 过渡到 `ink`, 对勾以回弹曲线放大出现.
class _CheckCircle extends StatelessWidget {
  const new({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    final duration = context.motion(EatMotion.select);
    return AnimatedContainer(
      duration: duration,
      curve: EatMotion.select.curve,
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? c.ink : c.paper,
        border: Border.all(color: checked ? c.ink : c.lineStrong, width: 1.5),
      ),
      child: Center(
        child: AnimatedScale(
          scale: checked ? 1 : 0,
          duration: duration,
          curve: checked ? Curves.easeOutBack : Curves.easeIn,
          child: EatIcon(EatIcons.check, size: 12, color: c.paper),
        ),
      ),
    );
  }
}

/// 抽屉顶部的提示行, `warn` 色文字配图标.
class _Notice extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return Row(
      spacing: 6,
      children: [
        EatIcon(EatIcons.warning, size: 18, color: eat.colors.warn),
        Expanded(
          child: Text(
            text,
            style: eat.text.meta.copyWith(color: eat.colors.warn),
          ),
        ),
      ],
    );
  }
}
