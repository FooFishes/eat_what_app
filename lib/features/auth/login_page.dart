import 'dart:async';
import 'dart:math' as math;

import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/platform/browser.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/icons/emoji.dart';
import 'package:eat/design/icons/illustrations.dart';
import 'package:eat/design/layout/eat_layout.dart';
import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/theme/stage_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_dialog.dart';
import 'package:eat/design/widgets/eat_stage.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/features/auth/auth_providers.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/consented_services.dart';
import 'package:eat/state/privacy_consent.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 登录页.
///
/// - 舞台: 汤色底, 装饰转盘, 品牌字和简介. 右上角卷起的页角是 "先逛逛", 点了不登录进去看看.
/// - 抽屉: "验证码登录" 和 "账号密码登录" 两个黑色按钮, 协议勾选.
///
/// 没勾协议时两个登录按钮和 "先逛逛" 照常可点, 点了先弹协议对话框. 同意后勾上并直接继续刚才那一步.
///
/// [query] 包含地址中的 `from` 和 `expired`, 原样传给手机号登录页和密码登录页.
/// 登录成功后, 守卫据此返回原页面.
class LoginPage extends ConsumerStatefulWidget {
  const new({
    super.key,
    this.query = const {},
    this.browseTarget = Paths.discover,
  });

  final Map<String, String> query;

  /// 点 "先逛逛" 后去的地址. 由路由表按 `from` 算好传入, 游客进不去的地址已换成发现页.
  final String browseTarget;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  /// 已勾选协议时返回 true. 没勾时弹协议对话框, 同意后勾上并返回 true.
  Future<bool> _ensureAgreed() async {
    if (ref.read(loginAgreementProvider)) return true;
    final agreed = await showAgreementDialog(context);
    if (!agreed || !mounted) return false;
    ref.read(loginAgreementProvider.notifier).set(agreed: true);
    return true;
  }

  Future<void> _start(String path) async {
    if (!await _ensureAgreed() || !mounted) return;
    final query = widget.query;
    context.go(
      Uri(path: path, queryParameters: query.isEmpty ? null : query).toString(),
    );
  }

  /// 不登录进去看看. 游客也要先同意隐私政策, 因为浏览同样会用到设备信息和使用记录.
  ///
  /// 先写入同意记录, 首次同意时补启动崩溃上报等服务, 再成为游客.
  /// 守卫对停在登录页的游客不做处理, 所以由本页跳转.
  Future<void> _browse() async {
    if (!await _ensureAgreed() || !mounted) return;
    await ref.read(privacyConsentStoreProvider).record();
    unawaited(ref.read(consentedServicesProvider.notifier).start());
    ref.read(sessionProvider.notifier).browse();
    if (mounted) context.go(widget.browseTarget);
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final query = widget.query;
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
                '验证码登录',
                icon: EatIcons.phone,
                onPressed: () => _start(Paths.loginPhone),
              ),
              EatButton.solid(
                '账号密码登录',
                icon: EatIcons.lock,
                onPressed: () => _start(Paths.loginPassword),
              ),
              const AgreementCheck(),
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
      child: Stack(
        children: [
          Positioned.fill(child: _content(context, sheet)),
          Positioned(top: 0, right: 0, child: _BrowseCorner(onTap: _browse)),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, Widget sheet) {
    final media = MediaQuery.of(context);
    return CustomScrollView(
      scrollBehavior: ScrollConfiguration.of(context)
          .copyWith(overscroll: false, physics: const ClampingScrollPhysics()),
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
    final intro = eat.text.subhead.copyWith(
      fontWeight: FontWeight.w400,
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
              style: eat.text.title.copyWith(color: palette.foreground),
            ),
            const SizedBox(height: 2),
            Text(
              '今天\n吃什么',
              textScaler: TextScaler.noScaling,
              style: eat.text.display.copyWith(color: palette.foreground),
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

/// 协议勾选行. 左侧为勾选框, 协议名可点击查看. 默认不勾.
class AgreementCheck extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<AgreementCheck> createState() => _AgreementCheckState();
}

class _AgreementCheckState extends ConsumerState<AgreementCheck> {
  late final _links = _AgreementLinks(ref);

  /// 文字相对勾选框上移的距离. 汉字字面在行框里偏下,
  /// 行框和圆按几何中心对齐时文字看起来比圆低, 上移后两者的视觉中心对齐.
  static const _opticalLift = 1.0;

  @override
  void dispose() {
    _links.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final agreed = ref.watch(loginAgreementProvider);
    void toggle() {
      HapticFeedback.selectionClick();
      ref.read(loginAgreementProvider.notifier).set(agreed: !agreed);
    }

    final style = eat.text.meta.copyWith(color: c.inkSoft);

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
              padding: const EdgeInsets.only(top: inset - _opticalLift),
              child: GestureDetector(
                onTap: toggle,
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: '我已阅读并同意'),
                      ..._links.spans(c.inkSoft),
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

    /// 行尾的全角 "》" 字面只占左半边, 右半边是空白.
    /// 整组按这段空白的一半右移, 看上去才居中.
    final bracketSpace =
        MediaQuery.textScalerOf(context).scale(style.fontSize!) / 2;
    return Align(
      heightFactor: 1,
      child: Transform.translate(
        offset: Offset(bracketSpace / 2, 0),
        child: row,
      ),
    );
  }
}

/// 《隐私政策》和《用户协议》两个链接, 点击用浏览器打开. 用完调用 [dispose].
class _AgreementLinks {
  _AgreementLinks(this._ref);

  final WidgetRef _ref;

  late final _privacy = TapGestureRecognizer()
    ..onTap = () => _open(_ref.read(appConfigProvider).privacyUrl);
  late final _terms = TapGestureRecognizer()
    ..onTap = () => _open(_ref.read(appConfigProvider).termsUrl);

  void _open(String url) {
    if (url.isNotEmpty) _ref.read(browserProvider).open(Uri.parse(url));
  }

  /// "《隐私政策》和《用户协议》". 协议名加粗, 下划线用 [underline] 色.
  List<InlineSpan> spans(Color underline) => [
    _link('隐私政策', _privacy, underline),
    const TextSpan(text: '和'),
    _link('用户协议', _terms, underline),
  ];

  /// 下划线只画在协议名下, 书名号不画, 否则线两端会悬空.
  static TextSpan _link(
    String name,
    TapGestureRecognizer recognizer,
    Color underline,
  ) => TextSpan(
    style: const TextStyle(fontWeight: FontWeight.w600),
    children: [
      TextSpan(text: '《', recognizer: recognizer),
      TextSpan(
        text: name,
        style: TextStyle(
          decoration: TextDecoration.underline,
          decorationColor: underline,
        ),
        recognizer: recognizer,
      ),
      TextSpan(text: '》', recognizer: recognizer),
    ],
  );

  void dispose() {
    _privacy.dispose();
    _terms.dispose();
  }
}

/// 协议对话框. 没勾协议时点登录按钮或 "先逛逛" 弹出, 返回 true 表示用户点了 "同意并继续".
///
/// "同意并继续" 是主按钮, "不同意" 是次按钮, 和其他对话框一致.
/// 点击 "不同意", 点击遮罩和系统返回都视为不同意, 停在登录页不再追问.
Future<bool> showAgreementDialog(BuildContext context) async =>
    await showEatDialog<bool>(
      context,
      builder: (dialog) => const _AgreementDialog(),
    ) ??
    false;

class _AgreementDialog extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_AgreementDialog> createState() => _AgreementDialogState();
}

class _AgreementDialogState extends ConsumerState<_AgreementDialog> {
  late final _links = _AgreementLinks(ref);

  @override
  void dispose() {
    _links.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    return EatDialog(
      title: '同意后继续',
      actions: Row(
        spacing: EatSpace.s10,
        children: [
          Expanded(
            child: EatButton.mist(
              '不同意',
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ),
          Expanded(
            child: EatButton.solid(
              '同意并继续',
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ),
        ],
      ),
      child: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: '使用时会用到设备信息和使用记录，详见'),
            ..._links.spans(c.ink),
            const TextSpan(text: '。'),
          ],
        ),
        style: eat.text.body.copyWith(color: c.inkSoft),
      ),
    );
  }
}

/// 登录页右上角的 "先逛逛": 页角向左下卷起, 露出下面一层纸色, 上面写 "先逛逛".
/// 卷起的页角后面探出一双眼睛 ([Emoji.eyes]), 像有人掀着页角往外偷看.
///
/// 进页面时页角减速卷起, 不回弹, 快卷好时眼睛从页角后面探出来. 按下时再多卷一点.
/// 之后每隔 [_idlePeriod] 把页角缓缓多掀起一点再放回去, 眼睛跟着多探出来一些.
/// 系统开启减少动态效果时直接显示卷好的样子, 眼睛不动.
/// 这是登录页特有的入口, 不用胶囊按钮.
///
/// 点击区域是贴着右上角的矩形: 对角线右上方露出纸色, 左下方是卷起的页角, 画法见 [_CurlPainter].
/// 卷起的页角会画到矩形外面一点.
class _BrowseCorner extends StatefulWidget {
  const new({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_BrowseCorner> createState() => _BrowseCornerState();
}

class _BrowseCornerState extends State<_BrowseCorner>
    with TickerProviderStateMixin {
  late final _curl = AnimationController(vsync: this, duration: _curlDuration);

  /// 纸不会越过终点再弹回来, 所以不用转盘的回弹曲线.
  late final _curve = CurvedAnimation(
    parent: _curl,
    curve: Curves.easeOutCubic,
  );

  /// 眼睛探出来的进度. 页角卷到大半才开始, 从页角后面升起.
  late final _peek = CurvedAnimation(
    parent: _curl,
    curve: const Interval(0.55, 1, curve: Curves.easeOutCubic),
  );

  static const _curlDuration = Duration(milliseconds: 900);

  /// 卷好之后循环掀页角, 值是一轮里的进度.
  late final _idle = AnimationController(vsync: this, duration: _idlePeriod);

  static const _idlePeriod = Duration(seconds: 6);

  /// 掀页角时多卷的长度.
  static const _liftExtra = 8.0;

  /// 卷好时纸色三角右边的长度, 不含状态栏. 要让 "先逛逛" 整个落在纸色三角里.
  static const _rest = 106.0;

  /// 按下时多卷的长度.
  static const _pressExtra = 16.0;

  /// "先逛逛" 与页面右边和状态栏的距离.
  static const _labelInset = 14.0;
  static const _labelTop = 10.0;

  /// 眼睛图片的边长. 图里两只眼睛约占宽的八成, 高的六成.
  static const _eyesSize = 44.0;

  /// 眼睛中心越过卷起的边的距离, 和掀页角时多探出的距离. 平时下面小半截被页角挡住.
  static const _eyesOut = 3.0;
  static const _eyesPeek = 5.0;

  /// 眼睛探出来之前藏在页角后面的深度.
  static const _eyesHidden = _eyesSize * 0.6;

  /// 眼睛顺着卷起的边往左上挪的距离, 避开 "先逛逛".
  static const _eyesAlong = 6.0;

  /// "先逛逛" 跟随系统字号放大的上限. 再大就超出纸色三角.
  static const _maxTextScale = 1.2;

  /// 掀页角: 一轮里占 [_liftSpan], 缓起缓落, 不落到卷好的位置以下. 1 为掀到最高.
  static double _liftAt(double t) {
    final x = (t - _liftStart) / _liftSpan;
    if (x <= 0 || x >= 1) return 0;
    return math.pow(math.sin(math.pi * x), 2).toDouble();
  }

  static const _liftStart = 0.55;
  static const _liftSpan = 0.2;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _curl.value = 1;
      _idle
        ..stop()
        ..value = 0;
      return;
    }
    if (_curl.isDismissed) _curl.forward();
    if (!_idle.isAnimating) _idle.repeat();
  }

  @override
  void dispose() {
    _idle.dispose();
    _peek.dispose();
    _curve.dispose();
    _curl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final stage = StageTheme.of(context).background;
    final top = MediaQuery.paddingOf(context).top;
    final rest = top + _rest;
    final label = Text(
      '先逛逛？',
      textScaler: MediaQuery.textScalerOf(context)
          .clamp(maxScaleFactor: _maxTextScale),
      style: eat.text.subhead.copyWith(color: c.inkMuted),
    );
    return EatTappable(
      onTap: widget.onTap,
      label: '先逛逛',
      tapHint: '不登录先看看',
      focusShape: const RoundedRectangleBorder(),
      dimOnPress: false,
      builder: (context, pressed) => TweenAnimationBuilder<double>(
        tween: Tween(end: pressed ? 1 : 0),
        duration: context.motion(EatMotion.press),
        curve: EatMotion.press.curve,
        builder: (context, press, _) => AnimatedBuilder(
          animation: Listenable.merge([_curve, _idle]),
          builder: (context, _) {
            final lift = _liftAt(_idle.value);
            final extent = math.max(
              0.0,
              rest * _curve.value + _pressExtra * press + _liftExtra * lift,
            );
            final out =
                _eyesOut + _eyesPeek * lift - _eyesHidden * (1 - _peek.value);
            final eyes =
                _CurlPainter.edgePoint(extent) +
                _CurlPainter.towardCorner * out +
                _CurlPainter.alongEdge * _eyesAlong;
            const eyesSize = _eyesSize;
            return SizedBox(
              width: extent * _CurlPainter.aspect,
              height: extent,
              child: CustomPaint(
                painter: _CurlPainter(
                  paper: c.paper,
                  back: stage,
                  shadow: c.ink,
                ),
                child: ClipPath(
                  clipper: const _RevealClipper(),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: eyes.dx - eyesSize / 2,
                        top: eyes.dy - eyesSize / 2,
                        child: Transform.rotate(
                          angle: _CurlPainter.edgeAngle,
                          child: const EmojiImage(Emoji.eyes, size: eyesSize),
                        ),
                      ),
                      Positioned(
                        top: top + _labelTop,
                        right: _labelInset,
                        child: label,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 对角线右上方露出的纸色三角. 矩形的右上角是原来的页角.
class _RevealClipper extends CustomClipper<Path> {
  const new();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..close();

  @override
  bool shouldReclip(_RevealClipper oldClipper) => false;
}

/// 画卷起的页角: 页角绕一根圆柱卷过半圈, 再平着盖回页面上方, 画的是从正上方看到的样子.
///
/// 坐标以页角为原点, p 沿卷起的方向指向页面内, w 与之垂直. 卷起的方向比对角线偏 [_lean],
/// 盖回去的页角因此是斜的. 圆柱半径 r, 页面在 p = a 处离开桌面,
/// 页面上原来在 p = t 的一条线, 纸长 u = a - t, 卷起后落在:
///
/// - 圆柱上 (u <= πr): p = a - r·sin(u/r).
/// - 盖回去的平面上 (u > πr): p = a + u - πr.
///
/// 这条线的宽度不变, 所以页面原来的两条直边在圆柱上投影成曲线.
/// 以平涂的色块为主, 不画高光和模糊投影. 由下到上:
///
/// 1. 纸色: p < a 的三角, 即页角原来盖住的地方. 可见部分是画布对角线右上的一半.
/// 2. 影子: 卷起部分向页面内错开一点的硬边色块, 只落在舞台上.
/// 3. 圆柱下半圈: 页面正面向上弯起的部分, 比上半圈宽, 在两端露出来.
/// 4. 圆柱上半圈和盖回去的页角: 朝上的是页面背面. 圆柱上的一段由外沿向内渐变到页角的颜色.
class _CurlPainter extends CustomPainter {
  const new({required this.paper, required this.back, required this.shadow});

  final Color paper;

  /// 舞台色, 即页面正面的颜色.
  final Color back;
  final Color shadow;

  /// 卷起的方向与页面上边的夹角. 45° 时页角沿对角线卷, 盖回去的两条边横平竖直, 显得呆板.
  static const _lean = 53 * math.pi / 180;

  /// 画布的宽高比.
  static final double aspect = math.tan(_lean);

  /// 卷起的边在屏幕上的倾角. 这条边是画布的对角线, 从左上到右下.
  static const edgeAngle = math.pi / 2 - _lean;

  /// 从卷起的边指向页角的单位向量.
  static final Offset towardCorner = Offset(math.cos(_lean), -math.sin(_lean));

  /// 顺着卷起的边指向左上的单位向量.
  static final Offset alongEdge = Offset(-math.sin(_lean), -math.cos(_lean));

  /// 画布高为 [extent] 时, 页角到卷起的边的垂足.
  static Offset edgePoint(double extent) {
    final reach = extent * math.sin(_lean);
    return Offset(extent * aspect, 0) - towardCorner * reach;
  }

  /// 圆柱半径与纸色三角高度之比.
  static const _radiusRatio = 0.16;

  /// 每四分之一圈的采样段数.
  static const _steps = 12;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final visible = size.height * math.sin(_lean);
    final r = visible * _radiusRatio;
    final a = visible + r;
    final half = math.pi * r / 2;
    final tip = 2 * a - math.pi * r;
    final topSlope = math.tan(_lean);
    final rightSlope = -1 / topSlope;

    Offset onRoll(double u, double slope) =>
        Offset(a - r * math.sin(u / r), slope * (a - u));

    final under = Path()..moveTo(a, a * topSlope);
    final over = Path()..moveTo(a - r, (a - half) * topSlope);
    for (var i = 1; i <= _steps; i++) {
      final u = half * i / _steps;
      final lower = onRoll(u, topSlope);
      final upper = onRoll(half + u, topSlope);
      under.lineTo(lower.dx, lower.dy);
      over.lineTo(upper.dx, upper.dy);
    }
    over.lineTo(tip, 0);
    for (var i = _steps; i >= 0; i--) {
      final u = half * i / _steps;
      final lower = onRoll(u, rightSlope);
      final upper = onRoll(half + u, rightSlope);
      under.lineTo(lower.dx, lower.dy);
      over.lineTo(upper.dx, upper.dy);
    }
    under.close();
    over.close();

    final reveal = Path()
      ..moveTo(0, 0)
      ..lineTo(a, a * topSlope)
      ..lineTo(a, a * rightSlope)
      ..close();
    final shade = Paint()..color = Color.lerp(back, shadow, 0.14)!;
    final flap = Color.lerp(back, paper, 0.95)!;

    canvas
      ..save()
      ..translate(size.width, 0)
      ..rotate(math.pi - _lean)
      ..drawPath(reveal, Paint()..color = paper)
      ..drawPath(over.shift(Offset(r * 0.3, 0)), shade)
      ..drawPath(under, shade)
      ..drawPath(over, Paint()..color = flap)
      ..clipRect(Rect.fromLTRB(a - r, a * rightSlope, a, a * topSlope))
      ..drawPath(
        over,
        Paint()
          ..shader = LinearGradient(
            colors: [Color.lerp(flap, back, 0.3)!, flap],
          ).createShader(Rect.fromLTRB(a - r, 0, a, 1)),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_CurlPainter oldDelegate) =>
      oldDelegate.paper != paper ||
      oldDelegate.back != back ||
      oldDelegate.shadow != shadow;
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
