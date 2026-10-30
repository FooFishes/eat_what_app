import 'dart:math' as math;

import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/platform/browser.dart';
import 'package:eat/design/icons/eat_icon.dart';
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

/// 登录页（`G-Login`）：汤色舞台上慢慢转的一圈菜，品牌字和一句介绍，底部白色抽屉里是
/// 「手机号登录」和协议勾选。没勾协议时按钮是灰的，点了不进下一页：协议那一行晃一下、手机轻震，
/// 勾选框下面提示先勾选。
///
/// [query] 是地址里的 `from`、`expired`，原样带进手机号登录页，登录后守卫按它回到原页面。
class LoginPage extends ConsumerStatefulWidget {
  const new({super.key, this.query = const {}});

  final Map<String, String> query;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  /// 没勾协议时点了几次按钮，每点一次协议那一行晃一下。勾上之后清零、收起提示，
  /// 再取消勾选也要等下次点按钮才提示。
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
        borderRadius: const BorderRadius.vertical(top: EatRadius.sheet),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          EatSpace.s20,
          EatSpace.s24,
          EatSpace.s20,
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
    // 品牌字在上、抽屉贴底，转盘画在两者之间的空隙里，下半圈被抽屉盖住。屏幕越高，多出来的
    // 高度按 1:8 分给品牌字上方和转盘：品牌字稍往下挪，转盘露出更多，中间不留一大块空。
    // 矮屏、大字号放不下时整页滚动，品牌字和抽屉不叠在一起。
    return EatStage(
      stage: StageColor.broth,
      child: CustomScrollView(
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

  /// 抽屉里的内容离屏幕底部的距离，比上边距大，按钮不贴着底边。
  static const _sheetBottom = 44.0;

  /// 品牌字离状态栏至少多远。
  static const _brandTop = 56.0;
}

class _Brand extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final palette = StageTheme.of(context);
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
                fontSize: 16,
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
            Text(
              '看看软件园的同学都在吃什么，\n再把你的好店分享出去。',
              style: eat.text.body.copyWith(
                height: 22 / 15,
                color: palette.secondaryForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 舞台下方慢慢转的一圈菜：90 秒一圈，系统开启减少动态效果时停住（产品 6.2）。
///
/// 和发现页的转盘长得一样，但不能拖、不能点，只是装饰，所以不用 `Turntable` 组件。
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

  /// 比发现页的转盘放大一些：登录页的菜只是装饰，放大了更有分量。
  static const _scale = 1.2;
  static const _dish = 220 * _scale;
  static const _radius = EatSize.turntableRadius * _scale;
  static const _ringOffset = Offset(-36 * _scale, -17 * _scale);
  static const _tableRadius = 600 * _scale;
  static const _tableRingRadius = 560 * _scale;

  /// 桌面圆心到最上面那道菜上缘的距离。
  static const _ringTop = _radius + _dish / 2 + 17 * _scale;
  static const _maxVisible = 320.0;

  /// 桌面圆比菜的上缘还高，留出这段才不越过空隙顶部。
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
          // 菜的圆心比桌面圆心往左上偏一些，转起来上缘不是一条平的弧。
          // 转盘在抽屉上方露出的高度随空隙变化，最多 [_maxVisible]；桌面和菜的上缘离空隙顶部
          // 至少 [_clearance]，不压到品牌字上。
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

/// 「我已阅读并同意《隐私政策》和《用户协议》」：左边 44px 的勾选框，协议名可以点开看。
///
/// [nudges] 每加一次，整行左右晃一下，下面淡入 `warn` 的「请先勾选同意协议」；为 0 时不提示。
/// 提示那一行一直占着位置，出现时抽屉不跟着变高。
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

  /// 晃动的幅度和来回次数：先大后小，像被轻轻拨了一下。
  static const _shakeAmplitude = 6.0;
  static const _shakeCycles = 3;

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

    TextSpan link(String text, TapGestureRecognizer recognizer) => TextSpan(
      text: text,
      style: const TextStyle(fontWeight: FontWeight.w600),
      recognizer: recognizer,
    );
    final style = eat.text.meta.copyWith(color: c.inkSoft);
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.translate(
          offset: const Offset(-12, 0),
          child: EatTappable(
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
        ),
        Expanded(
          child: Transform.translate(
            offset: const Offset(-12, 0),
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: GestureDetector(
                onTap: toggle,
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: '我已阅读并同意'),
                          link('《隐私政策》', _privacy),
                          const TextSpan(text: '和'),
                          link('《用户协议》', _terms),
                        ],
                      ),
                      style: style.copyWith(height: 20 / 13),
                    ),
                    ExcludeSemantics(
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
                              style: style.copyWith(
                                height: 20 / 13,
                                color: c.warn,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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
      child: row,
    );
  }
}

/// 勾选框：勾上时圆底从白过渡成 `ink`，对勾带一点回弹地放大出现。
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

/// 抽屉顶部的一行提示，`warn` 配图标。
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
