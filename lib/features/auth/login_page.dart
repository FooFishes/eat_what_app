import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
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
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/features/auth/auth_providers.dart';
import 'package:eat/features/system/consent_dialog.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/consented_services.dart';
import 'package:eat/state/privacy_consent.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 登录页.
///
/// - 舞台: 汤色背景, 装饰转盘, 品牌文字与简介; 右上角卷起的页角为 "先逛逛" 游客入口.
/// - 抽屉: 包含 "手机注册 / 登录" 与 "账号密码登录" 两个按钮, 以及协议勾选行.
///   勾选即同时同意隐私政策, 用户协议和个人信息出境说明.
///
/// 点击 "手机注册 / 登录" 时, 若支持一键登录则拉起运营商授权页, 否则跳转验证码登录页;
/// 授权页中的 "其他号码登录" 同样跳转至验证码登录页.
///
/// 未勾选协议时, 两个登录按钮与 "先逛逛" 仍可点击, 点击后先弹出协议对话框, 用户同意后自动勾选并继续执行原操作.
///
/// [query] 携带地址中的 `from` 和 `expired` 参数, 跳转手机号或密码登录页时原样透传, 登录成功后路由守卫据此返回原页面.
class LoginPage extends ConsumerStatefulWidget {
  const new({
    super.key,
    this.query = const {},
    this.browseTarget = Paths.discover,
    this.preloadBrowseTarget,
  });

  final Map<String, String> query;

  /// 点击 "先逛逛" 后的目标路由, 由路由表根据 `from` 计算传入; 游客无权访问的地址已替换为发现页.
  final String browseTarget;

  final VoidCallback? preloadBrowseTarget;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _pageKey = GlobalKey();

  /// 试拉时只预取已同意过的目标页数据, 以免触发页面的权限提示或提前切换会话.
  Future<void> _prepareDrag() async {
    if (widget.preloadBrowseTarget == null ||
        !ref.read(loginAgreementProvider)) {
      return;
    }
    final agreed = await ref.read(privacyConsentStoreProvider).agreed();
    if (mounted && agreed && ref.read(loginAgreementProvider)) {
      widget.preloadBrowseTarget?.call();
    }
  }

  /// 确认用户已同意协议. 若尚未勾选则弹出协议对话框, 同意后自动勾选并返回 true.
  Future<bool> _ensureAgreed() async {
    if (ref.read(loginAgreementProvider)) return true;
    final agreed = await showAgreementDialog(context);
    if (!agreed || !mounted) return false;
    ref.read(loginAgreementProvider.notifier).set(agreed: true);
    return true;
  }

  Future<void> _start(String path) async {
    if (!await _ensureAgreed() || !mounted) return;
    _go(path);
  }

  void _go(String path, {Map<String, String> extra = const {}}) {
    final query = {...widget.query, ...extra};
    context.go(
      Uri(path: path, queryParameters: query.isEmpty ? null : query).toString(),
    );
  }

  /// 在当前页面弹出政策同意对话框; 若页面已卸载则按拒绝处理.
  Future<bool> _presentConsent() async {
    if (!mounted) return false;
    return showConsentDialog(context);
  }

  /// 发起手机号登录; 若一键登录可用则拉起运营商授权页, 否则跳转验证码登录页.
  Future<void> _startPhone() async {
    if (!await _ensureAgreed() || !mounted) return;
    final outcome = await ref
        .read(oneClickLoginProvider.notifier)
        .start(_presentConsent);
    if (!mounted) return;
    switch (outcome) {
      case OneClickSignedIn() || OneClickDismissed():
        break;
      case OneClickUseCode(:final revoking):
        _go(Paths.loginPhone, extra: {if (revoking) 'revoke': '1'});
      case OneClickFailed(:final failure):
        _showOneClickFailed(failure);
      case OneClickBlocked(:final failure):
        if (failure.code == BizCodes.accountDeletionPending) {
          _showDeletionPending(failure);
        } else {
          showToast(context, failure.message);
        }
    }
  }

  void _showOneClickFailed(AppFailure failure) => showEatDialog<void>(
    context,
    builder: (dialog) => EatDialog(
      icon: EatIcons.warning,
      title: failure.message,
      actions: Row(
        spacing: EatSpace.s10,
        children: [
          Expanded(
            child: EatButton.mist(
              '用验证码登录',
              onPressed: () {
                Navigator.of(dialog).pop();
                _go(Paths.loginPhone);
              },
            ),
          ),
          Expanded(
            child: EatButton.solid(
              '重试',
              onPressed: () {
                Navigator.of(dialog).pop();
                _startPhone();
              },
            ),
          ),
        ],
      ),
    ),
  );

  void _showDeletionPending(AppFailure failure) => showEatDialog<void>(
    context,
    builder: (dialog) => EatDialog(
      icon: EatIcons.warning,
      title: failure.message,
      actions: EatButton.solid(
        '知道了',
        onPressed: () => Navigator.of(dialog).pop(),
      ),
    ),
  );

  /// 以游客身份进入应用. 由于浏览同样会采集设备信息和使用记录, 游客也须先同意隐私政策.
  ///
  /// 写入同意记录并补启动崩溃上报等服务后再切换为游客状态; 路由守卫不重定向已位于登录页的游客, 因此由本页主动跳转.
  Future<bool> _browse(
    _CurlPainter fold,
    _BrowseHint hint,
    double releaseVelocity,
  ) async {
    if (!await _ensureAgreed() || !mounted) return false;
    // 先逛逛时没有请求服务端的政策版本, 同意记录只记时间.
    await ref.read(privacyConsentStoreProvider).record(null);
    if (!mounted) return false;
    widget.preloadBrowseTarget?.call();
    ui.Image? image;
    if (!MediaQuery.disableAnimationsOf(context)) {
      final boundary = _pageKey.currentContext?.findRenderObject();
      if (boundary is RenderRepaintBoundary && !boundary.debugNeedsPaint) {
        try {
          image = boundary.toImageSync(
            pixelRatio: MediaQuery.devicePixelRatioOf(context).clamp(1.0, 2.0),
          );
        } on Object {
          image = null;
        }
      }
    }
    if (image != null) {
      final captured = image;
      late final OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => _PagePeel(
          image: captured,
          fold: fold,
          hint: hint,
          releaseVelocity: releaseVelocity,
          onFinished: () {
            entry.remove();
            entry.dispose();
          },
        ),
      );
      Overlay.of(context, rootOverlay: true).insert(entry);
    }
    unawaited(ref.read(consentedServicesProvider.notifier).start());
    ref.read(sessionProvider.notifier).browse();
    context.go(widget.browseTarget);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final query = widget.query;
    final safe = MediaQuery.viewPaddingOf(context);
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
          _sheetBottom + safe.bottom,
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
                '手机注册 / 登录',
                icon: EatIcons.phone,
                loading: ref.watch(oneClickLoginProvider),
                onPressed: _startPhone,
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
    // 禁用越界回弹与拉伸, 避免拖动改变 SliverFillRemaining 高度而导致转盘变形.
    return EatStage(
      stage: StageColor.broth,
      child: LayoutBuilder(
        builder: (context, constraints) => _BrowseCorner(
          pageSize: constraints.biggest,
          onDragStart: _prepareDrag,
          onTap: _browse,
          page: RepaintBoundary(
            key: _pageKey,
            child: ColoredBox(
              color: StageTheme.of(context).background,
              child: _content(context, sheet),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, Widget sheet) {
    final safe = MediaQuery.viewPaddingOf(context);
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
                  safe.top + _brandTop,
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

  /// 抽屉顶部圆角半径, 取按钮圆角与内边距之和, 以保持两者同心.
  static const _sheetRadius = EatSize.button / 2 + _sheetInset;

  /// 抽屉内容与屏幕底边的间距, 略大于上边距以避免按钮贴近屏幕底部.
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

/// 协议勾选行, 左侧为勾选框, 右侧协议名称支持点击查看, 默认未勾选.
///
/// 单次勾选即同时同意隐私政策, 用户协议和个人信息出境说明, 服务端将三者合并记为同一份同意记录.
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

    // 勾选框触控热区大于圆形本身, 圆形两侧各留白 [inset].
    // 将文字左移至距圆 [gap] 处并在行尾补齐等宽空白, 使整行在居中时保持视觉对称.
    const inset = (EatSize.touch - 20) / 2;
    const gap = 6.0;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EatTappable(
          onTap: toggle,
          label: '同意隐私政策、用户协议和个人信息出境说明',
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
    return Align(heightFactor: 1, child: row);
  }
}

/// 管理《隐私政策》《用户协议》和《个人信息出境说明》的链接点击器, 点击后通过浏览器打开对应页面, 使用完毕需调用 [dispose].
class _AgreementLinks {
  _AgreementLinks(this._ref);

  final WidgetRef _ref;

  late final _privacy = TapGestureRecognizer()
    ..onTap = () => _open(_ref.read(appConfigProvider).privacyUrl);
  late final _terms = TapGestureRecognizer()
    ..onTap = () => _open(_ref.read(appConfigProvider).termsUrl);
  late final _crossBorder = TapGestureRecognizer()
    ..onTap = () => _open(_ref.read(appConfigProvider).crossBorderUrl);

  void _open(String url) {
    if (url.isNotEmpty) _ref.read(browserProvider).open(Uri.parse(url));
  }

  /// 构建 "《隐私政策》《用户协议》和《个人信息出境说明》" 富文本片段, 协议名加粗并绘制 [underline] 色下划线.
  List<InlineSpan> spans(Color underline) => [
    _link('隐私政策', _privacy, underline),
    _link('用户协议', _terms, underline),
    const TextSpan(text: '和'),
    _link('个人信息出境说明', _crossBorder, underline),
  ];

  /// 仅在协议名称下方绘制下划线而不包含书名号, 避免下划线两端悬空.
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
    _crossBorder.dispose();
  }
}

/// 协议确认对话框, 在未勾选协议时点击登录按钮或 "先逛逛" 弹出, 返回 true 表示用户点击了 "同意并继续".
///
/// 主次按钮排布与其他对话框一致 ("同意并继续" 为主按钮, "不同意" 为次按钮).
/// 点击 "不同意", 点击遮罩或触发系统返回均视为拒绝, 停留在登录页且不再重复弹窗.
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
            const TextSpan(text: '使用时会收集设备信息和使用记录，传到境外服务器存储和处理。继续前请阅读并同意'),
            ..._links.spans(c.ink),
            const TextSpan(text: '。'),
          ],
        ),
        style: eat.text.body.copyWith(color: c.inkSoft),
      ),
    );
  }
}

/// 登录页的游客入口. 拖动和换页共用同一张纸的折痕与卷边.
class _BrowseCorner extends StatefulWidget {
  const new({
    required this.pageSize,
    required this.onDragStart,
    required this.onTap,
    required this.page,
  });

  final Size pageSize;
  final VoidCallback onDragStart;
  final Future<bool> Function(_CurlPainter, _BrowseHint, double) onTap;
  final Widget page;

  @override
  State<_BrowseCorner> createState() => _BrowseCornerState();
}

class _BrowseCornerState extends State<_BrowseCorner>
    with TickerProviderStateMixin {
  static const _rest = 106.0;
  static const _entranceDuration = Duration(milliseconds: 480);
  static const _maxEntranceFrame = Duration(milliseconds: 32);
  static const _pressExtra = 16.0;
  static const _liftExtra = 8.0;
  static const _dragRevealExtra = 64.0;
  static const _dragThreshold = 56.0;
  static const _eyesShown = 34.0;
  static const _eyesPeek = 5.0;

  final _entrance = ValueNotifier(0.0);
  late final _entranceTicker = createTicker(_advanceEntrance);
  Duration _lastEntranceTick = Duration.zero;
  Animation<double>? _routeTransition;
  bool _reduceMotion = false;
  late final _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  late final _return = AnimationController(vsync: this);
  late final _press = AnimationController(vsync: this);

  _CurlPose? _held;
  Offset? _dragOrigin;
  late _CurlPose _dragStart;
  late _CurlPainter _paintedFold;
  late _BrowseHint _paintedHint;
  double _pull = 0;
  bool _committing = false;

  double get _lift {
    final t = (_idle.value - 0.55) / 0.2;
    if (t <= 0 || t >= 1) return 0;
    final wave = math.sin(math.pi * t);
    return wave * wave;
  }

  void _dragBegin(DragStartDetails details) {
    if (_committing) return;
    widget.onDragStart();
    _return.stop();
    _idle.stop();
    _dragStart = _paintedFold.pose;
    _dragOrigin = details.globalPosition;
    setState(() => _held = _dragStart);
  }

  void _dragUpdate(DragUpdateDetails details) {
    final origin = _dragOrigin;
    if (origin == null) return;
    final delta = details.globalPosition - origin;
    _pull = (delta.dy - delta.dx) / math.sqrt2;
    final restingReveal = _CurlPose.rest(
      MediaQuery.paddingOf(context).top + _rest,
    ).revealSize;
    final limit = Size(
      restingReveal.width + _dragRevealExtra,
      restingReveal.height + _dragRevealExtra,
    );
    setState(() => _held = _dragStart.follow(delta, limit));
  }

  void _settle() {
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _held = null);
      return;
    }
    _return
        .animateWith(
          SpringSimulation(
            const SpringDescription(mass: 1, stiffness: 260, damping: 25),
            0,
            1,
            0,
          ),
        )
        .then((_) {
          if (!mounted) return;
          setState(() => _held = null);
          if (!MediaQuery.disableAnimationsOf(context)) _idle.repeat();
        });
  }

  void _dragEnd(DragEndDetails details) {
    if (_dragOrigin == null) return;
    final screenVelocity = details.velocity.pixelsPerSecond;
    final velocity = (screenVelocity.dy - screenVelocity.dx) / math.sqrt2;
    final accepted =
        _pull >= _dragThreshold ||
        (_pull > _dragThreshold * 0.55 && velocity > 800);
    setState(() {
      _dragOrigin = null;
      _pull = 0;
    });
    if (accepted) {
      _activate(release: _held, velocity: velocity);
    } else {
      _settle();
    }
  }

  void _dragCancel() {
    if (_dragOrigin == null) return;
    setState(() {
      _dragOrigin = null;
      _pull = 0;
    });
    _settle();
  }

  Future<void> _activate({_CurlPose? release, double velocity = 0}) async {
    if (_committing) return;
    _return.stop();
    _idle.stop();
    final pose = release ?? _paintedFold.pose;
    final fold = _paintedFold.withPose(pose);
    final hint = _paintedHint;
    setState(() {
      _committing = true;
      _held = fold.pose;
    });
    final accepted = await widget.onTap(fold, hint, velocity);
    if (!mounted || accepted) return;
    setState(() => _committing = false);
    _settle();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final transition = ModalRoute.of(context)?.animation;
    if (!identical(transition, _routeTransition)) {
      _routeTransition?.removeStatusListener(_onRouteTransition);
      _routeTransition = transition;
      transition?.addStatusListener(_onRouteTransition);
    }
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _entranceTicker.stop();
      _entrance.value = 1;
      _idle
        ..stop()
        ..value = 0;
      return;
    }
    _startCornerMotion();
  }

  void _onRouteTransition(AnimationStatus status) {
    if (status == AnimationStatus.forward && _entrance.value == 0) {
      /// 声明式导航可能先构建页面, 再启动路由进场. 此时取消已排队的卷角首帧.
      _entranceTicker.stop();
      _idle.stop();
    }
    if (status == AnimationStatus.completed) _startCornerMotion();
  }

  /// 等路由进场结束后再掀开右上角, 以免卷角从屏幕外开始播放.
  void _startCornerMotion() {
    if (_reduceMotion ||
        (_routeTransition?.status ?? AnimationStatus.completed) !=
            AnimationStatus.completed) {
      return;
    }
    if (_entrance.value == 0 && !_entranceTicker.isActive) {
      _lastEntranceTick = Duration.zero;
      _entranceTicker.start();
    }
    if (_held == null && !_idle.isAnimating) _idle.repeat();
  }

  /// 限制单帧推进的入场时间, 避免首屏长帧让卷角直接跳到展开状态.
  void _advanceEntrance(Duration elapsed) {
    final frame = elapsed - _lastEntranceTick;
    _lastEntranceTick = elapsed;
    final step = math.min(
      frame.inMicroseconds,
      _maxEntranceFrame.inMicroseconds,
    );
    _entrance.value = math.min(
      1.0,
      _entrance.value + step / _entranceDuration.inMicroseconds,
    );
    if (_entrance.value == 1) _entranceTicker.stop();
  }

  @override
  void dispose() {
    _routeTransition?.removeStatusListener(_onRouteTransition);
    _press.dispose();
    _return.dispose();
    _idle.dispose();
    _entranceTicker.dispose();
    _entrance.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    _press.animateTo(
      pressed ? 1 : 0,
      duration: context.motion(EatMotion.press),
      curve: EatMotion.press.curve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final top = MediaQuery.paddingOf(context).top;
    final stage = StageTheme.of(context).background;
    return AnimatedBuilder(
      animation: Listenable.merge([_entrance, _idle, _return, _press]),
      child: widget.page,
      builder: (context, page) {
        final lift = _lift;
        final restingHeight = top + _rest;
        final rest = _CurlPose.rest(restingHeight + _liftExtra * lift);
        final entrance = _entrance.value;
        final held = _held;
        final pose = held == null
            ? _CurlPose.rest(
                restingHeight * Curves.easeOutCubic.transform(entrance) +
                    _pressExtra * _press.value +
                    _liftExtra * lift,
              )
            : _return.isAnimating
            ? held.lerp(rest, _return.value)
            : held;
        final hint = _committing
            ? _paintedHint
            : _BrowseHint(
                top: top,
                opacity: const Interval(0.18, 0.75).transform(entrance),
                eyesShown:
                    (_eyesShown + _eyesPeek * lift) *
                    const Interval(
                      0.18,
                      1,
                      curve: Curves.easeOutCubic,
                    ).transform(entrance),
                label: Text(
                  _pull >= _dragThreshold ? '松手进入' : '先逛逛？',
                  textScaler: MediaQuery.textScalerOf(context)
                      .clamp(maxScaleFactor: 1.2),
                  style: eat.text.subhead.copyWith(color: eat.colors.inkMuted),
                ),
              );
        final fold = _CurlPainter(
          pose: pose,
          paper: eat.colors.paper,
          front: stage,
          shadow: eat.colors.shade,
        );
        _paintedFold = fold;
        _paintedHint = hint;
        final revealed = pose.revealSize;
        return Stack(
          fit: StackFit.expand,
          children: [
            _BrowseMask(paper: fold.paper, hint: hint),
            _LoginPaper(fold: fold, child: page!),
            Align(
              alignment: Alignment.topRight,
              child: SizedBox(
                key: const ValueKey('browse-corner-hit-area'),
                width: revealed.width.clamp(
                  math.min(EatSize.touch, widget.pageSize.width),
                  widget.pageSize.width,
                ),
                height: revealed.height.clamp(
                  math.min(EatSize.touch, widget.pageSize.height),
                  widget.pageSize.height,
                ),
                child: Listener(
                  onPointerDown: (_) => _setPressed(true),
                  onPointerUp: (_) => _setPressed(false),
                  onPointerCancel: (_) {
                    _setPressed(false);
                    _dragCancel();
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    excludeFromSemantics: true,
                    dragStartBehavior: DragStartBehavior.down,
                    onPanStart: _committing ? null : _dragBegin,
                    onPanUpdate: _dragUpdate,
                    onPanEnd: _dragEnd,
                    onPanCancel: _dragCancel,
                    child: EatTappable(
                      onTap: _committing ? null : _activate,
                      label: '先逛逛',
                      tapHint: '不登录先看看',
                      focusShape: const RoundedRectangleBorder(),
                      dimOnPress: false,
                      builder: (_, _) => const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BrowseHint extends StatelessWidget {
  const new({
    required this.top,
    required this.opacity,
    required this.eyesShown,
    required this.label,
    this.labelShift = 0,
  });

  final double top;
  final double opacity;
  final double eyesShown;
  final Widget label;
  final double labelShift;

  static const _eyesSize = 44.0;

  _BrowseHint exiting(double progress) {
    final exit = const Interval(
      0,
      0.65,
      curve: Curves.easeInCubic,
    ).transform(progress);
    return _BrowseHint(
      top: top,
      opacity: opacity * (1 - exit),
      eyesShown: ui.lerpDouble(eyesShown, -8, exit)!,
      labelShift: 16 * exit,
      label: label,
    );
  }

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: opacity,
    child: Stack(
      children: [
        Positioned(top: top + 10, right: 14 - labelShift, child: label),
        Positioned(
          top: top + 30,
          right: eyesShown - _eyesSize,
          child: Transform.rotate(
            angle: -12 * math.pi / 180,
            child: const EmojiImage(Emoji.eyes, size: _eyesSize),
          ),
        ),
      ],
    ),
  );
}

/// 纸色与提示共用整屏遮罩. 遮罩变透明时一起露出实际目标页.
class _BrowseMask extends StatelessWidget {
  const new({required this.paper, required this.hint, this.opacity = 1});

  final Color paper;
  final Widget hint;
  final double opacity;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: Opacity(
        opacity: opacity,
        child: ColoredBox(color: paper, child: hint),
      ),
    ),
  );
}

/// 登录页沿当前折痕裁掉已掀开的区域, 卷边绘制在纸面上方.
class _LoginPaper extends StatelessWidget {
  const new({required this.fold, required this.child});

  final _CurlPainter fold;
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: fold,
    child: ClipPath(clipper: _LoginPaperClipper(fold.pose), child: child),
  );
}

/// 目标页先在底层绘制, 登录页再从松手时的折痕继续卷动.
class _PagePeel extends StatefulWidget {
  const new({
    required this.image,
    required this.fold,
    required this.hint,
    required this.releaseVelocity,
    required this.onFinished,
  });

  final ui.Image image;
  final _CurlPainter fold;
  final _BrowseHint hint;
  final double releaseVelocity;
  final VoidCallback onFinished;

  @override
  State<_PagePeel> createState() => _PagePeelState();
}

class _PagePeelState extends State<_PagePeel>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 700);

  late final _animation = AnimationController(vsync: this, duration: _duration);

  @override
  void initState() {
    super.initState();
    _animation.forward().then((_) {
      if (mounted) widget.onFinished();
    });
  }

  /// 沿用松手速度继续推动折痕, 并在终点减速至静止.
  double _peelProgress(double distance) {
    final t = _animation.value;
    final remaining = 1 - t;
    final durationSeconds = _duration.inMilliseconds / 1000;
    final initialSlope =
        (widget.releaseVelocity *
                durationSeconds /
                (2 * math.max(1.0, distance)))
            .clamp(0.65, 2.5);
    return t * (t * (3 - 2 * t) + initialSlope * remaining * remaining);
  }

  @override
  void dispose() {
    _animation.dispose();
    widget.image.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: AbsorbPointer(
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) => AnimatedBuilder(
            animation: _animation,
            child: RawImage(image: widget.image, fit: BoxFit.fill),
            builder: (context, page) {
              final size = constraints.biggest;
              final start = widget.fold.pose;
              final end = math.max(
                start.reach,
                start.farthestPoint(size) + math.pi * start.radius,
              );
              final progress = _peelProgress(end - start.reach);
              final reach = ui.lerpDouble(start.reach, end, progress)!;
              final pose = _animation.value == 0
                  ? start
                  : _CurlPose(reach, start.radius, start.lean);
              final remaining = 1 - progress;
              return Stack(
                fit: StackFit.expand,
                children: [
                  _BrowseMask(
                    paper: widget.fold.paper,
                    opacity: remaining * remaining,
                    hint: widget.hint.exiting(_animation.value),
                  ),
                  _LoginPaper(fold: widget.fold.withPose(pose), child: page!),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

/// 折痕由距右上角的垂直距离、圆柱半径及卷起方向确定.
class _CurlPose {
  const new(this.reach, this.radius, this.lean);

  factory _CurlPose.rest(double height) {
    const lean = 53 * math.pi / 180;
    final reach = height * math.sin(lean);
    return _CurlPose(reach, reach * 0.16, lean);
  }

  final double reach;
  final double radius;
  final double lean;

  Offset get axis => Offset(-math.cos(lean), math.sin(lean));

  Size get revealSize => Size(reach / -axis.dx, reach / axis.dy);

  double farthestPoint(Size size) =>
      -size.width * axis.dx + size.height * axis.dy;

  _CurlPose lerp(_CurlPose other, double t) => _CurlPose(
    ui.lerpDouble(reach, other.reach, t)!,
    ui.lerpDouble(radius, other.radius, t)!,
    ui.lerpDouble(lean, other.lean, t)!,
  );

  /// 用纸角落点反推折痕. 展平的纸角移动两倍折痕的距离.
  _CurlPose follow(Offset delta, Size revealLimit) {
    final rollOffset = (math.pi - 2) * radius;
    final tip = axis * (2 * reach - rollOffset) + delta;
    final inward = math.max(0.0, -tip.dx);
    final downward = math.max(0.0, tip.dy);
    final angle = math
        .atan2(downward, inward)
        .clamp(math.pi / 15, math.pi * 13 / 30);
    final distance = inward * math.cos(angle) + downward * math.sin(angle);
    final maxReach = math.min(
      revealLimit.width * math.cos(angle),
      revealLimit.height * math.sin(angle),
    );
    return _CurlPose(
      math.min(maxReach, math.max(radius, (distance + rollOffset) / 2)),
      radius,
      angle,
    );
  }

  Path paperPath(Size size) {
    if (reach == 0) return Path()..addRect(Offset.zero & size);
    final corner = Offset(size.width, 0);
    final normal = axis;
    final tangent = Offset(-normal.dy, normal.dx);
    final span = size.width + size.height;
    final line = corner + normal * reach;
    final across = tangent * span;
    final depth = normal * span;
    return Path()..addPolygon([
      line - across,
      line + across,
      line + across + depth,
      line - across + depth,
    ], true);
  }
}

class _LoginPaperClipper extends CustomClipper<Path> {
  const new(this.pose);

  final _CurlPose pose;

  @override
  Path getClip(Size size) => pose.paperPath(size);

  @override
  bool shouldReclip(_LoginPaperClipper oldClipper) => oldClipper.pose != pose;
}

/// 从俯视角绘制绕圆柱翻过半圈的纸. 每段先裁到原纸边界, 再投影到屏幕.
class _CurlPainter extends CustomPainter {
  const new({
    required this.pose,
    required this.paper,
    required this.front,
    required this.shadow,
  });

  final _CurlPose pose;
  final Color paper;
  final Color front;
  final Color shadow;

  _CurlPainter withPose(_CurlPose next) =>
      _CurlPainter(pose: next, paper: paper, front: front, shadow: shadow);

  @override
  void paint(Canvas canvas, Size size) {
    final r = pose.radius;
    if (r <= 0) return;
    final a = pose.reach + r;
    final half = math.pi * r / 2;
    final axis = pose.axis;
    final tangent = Offset(-axis.dy, axis.dx);
    Offset project(Offset point) => Offset(
      point.dx * axis.dx + point.dy * axis.dy,
      point.dx * tangent.dx + point.dy * tangent.dy,
    );

    final original = [
      Offset.zero,
      project(Offset(0, size.height)),
      project(Offset(-size.width, size.height)),
      project(Offset(-size.width, 0)),
    ];
    double onRoll(double p) => a - r * math.sin((a - p) / r);
    final under = _projectBand(original, a - half, a, onRoll, 12);
    final over = _projectBand(original, a - 2 * half, a - half, onRoll, 12)
      ..addPath(
        _projectBand(original, 0, a - 2 * half, (p) => 2 * a - 2 * half - p, 1),
        Offset.zero,
      );
    final shade = Paint()..color = Color.lerp(front, shadow, 0.14)!;
    final flap = Color.lerp(front, paper, 0.95)!;

    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..translate(size.width, 0)
      ..rotate(math.pi - pose.lean)
      ..drawPath(over.shift(Offset(r * 0.3, 0)), shade)
      ..drawPath(under, shade)
      ..drawPath(
        over,
        Paint()
          ..shader = LinearGradient(
            colors: [Color.lerp(flap, front, 0.3)!, flap],
          ).createShader(Rect.fromLTRB(a - r, 0, a, 1)),
      )
      ..restore();
  }

  static List<Offset> _clipAt(
    List<Offset> polygon,
    double p, {
    required bool keepRight,
  }) {
    if (polygon.isEmpty) return polygon;
    bool inside(Offset point) => keepRight ? point.dx >= p : point.dx <= p;
    final clipped = <Offset>[];
    var previous = polygon.last;
    for (final point in polygon) {
      if (inside(previous) != inside(point)) {
        clipped.add(
          Offset(
            p,
            ui.lerpDouble(
              previous.dy,
              point.dy,
              (p - previous.dx) / (point.dx - previous.dx),
            )!,
          ),
        );
      }
      if (inside(point)) clipped.add(point);
      previous = point;
    }
    return clipped;
  }

  static Path _projectBand(
    List<Offset> original,
    double start,
    double end,
    double Function(double) project,
    int steps,
  ) {
    final path = Path();
    if (start >= end) return path;
    final band = _clipAt(
      _clipAt(original, start, keepRight: true),
      end,
      keepRight: false,
    );
    if (band.length < 3) return path;
    var previous = band.last;
    path.moveTo(project(previous.dx), previous.dy);
    for (final point in band) {
      for (var i = 1; i <= steps; i++) {
        final sample = Offset.lerp(previous, point, i / steps)!;
        path.lineTo(project(sample.dx), sample.dy);
      }
      previous = point;
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_CurlPainter oldDelegate) =>
      oldDelegate.pose != pose ||
      oldDelegate.paper != paper ||
      oldDelegate.front != front ||
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
