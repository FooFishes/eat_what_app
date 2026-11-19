import 'dart:async';
import 'dart:math' as math;

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
  });

  final Map<String, String> query;

  /// 点击 "先逛逛" 后的目标路由, 由路由表根据 `from` 计算传入; 游客无权访问的地址已替换为发现页.
  final String browseTarget;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
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
      child: Stack(
        children: [
          Positioned.fill(child: _content(context, sheet)),
          Positioned(top: 0, right: 0, child: _BrowseCorner(onTap: _browse)),
        ],
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

/// 登录页右上角的 "先逛逛" 卷角入口: 页角向左下卷起, 露出下层纸色区域与 "先逛逛" 文案, 下方伴随从屏幕右侧探出的眼睛 ([Emoji.eyes]).
///
/// 进入页面时页角以减速曲线卷起且不回弹, 接近完成时眼睛从右侧滑入; 按下时页角进一步卷起.
/// 随后每隔 [_idlePeriod] 触发一次轻幅掀动与回落动画, 眼睛同步小幅探出.
/// 系统开启减少动态效果时直接呈现最终静止状态. 该入口为登录页专用样式, 不采用胶囊按钮.
///
/// 交互热区为紧贴右上角的矩形, 对角线右上方显示下层纸色, 左下方绘制卷起的页角 (详见 [_CurlPainter]), 卷边会略微超出矩形边界.
class _BrowseCorner extends StatefulWidget {
  const new({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_BrowseCorner> createState() => _BrowseCornerState();
}

class _BrowseCornerState extends State<_BrowseCorner>
    with TickerProviderStateMixin {
  late final _curl = AnimationController(vsync: this, duration: _curlDuration);

  /// 页角卷动不发生过冲回弹, 因此不采用转盘的回弹曲线.
  late final _curve = CurvedAnimation(
    parent: _curl,
    curve: Curves.easeOutCubic,
  );

  /// 眼睛滑入的动画进度, 在页角卷动过半后启动.
  late final _peek = CurvedAnimation(
    parent: _curl,
    curve: const Interval(0.55, 1, curve: Curves.easeOutCubic),
  );

  static const _curlDuration = Duration(milliseconds: 900);

  /// 静置后周期性掀动页角的循环动画, 数值代表单轮周期进度.
  late final _idle = AnimationController(vsync: this, duration: _idlePeriod);

  static const _idlePeriod = Duration(seconds: 6);

  /// 周期性掀动时页角额外卷起的长度.
  static const _liftExtra = 8.0;

  /// 静止状态下纸色三角右侧边的长度 (不含状态栏高度), 需保证 "先逛逛" 文案完整落入三角区域内.
  static const _rest = 106.0;

  /// 按下态时页角额外卷起的长度.
  static const _pressExtra = 16.0;

  /// "先逛逛" 与页面右边和状态栏的距离.
  static const _labelInset = 14.0;
  static const _labelTop = 10.0;

  /// 眼睛图片的边长. 图里两只眼睛约占宽的八成, 高的六成.
  static const _eyesSize = 44.0;

  /// 眼睛在屏幕内的露出宽度及掀动时的额外探出宽度, 右侧边缘保留在屏幕外.
  static const _eyesShown = 34.0;
  static const _eyesPeek = 5.0;

  /// 眼睛图片顶部距状态栏的距离, 位于 "先逛逛" 下方 (图片本身顶部含透明留白).
  static const _eyesTop = 30.0;

  /// 眼睛图片的逆时针倾角.
  static const _eyesTilt = -12 * math.pi / 180;

  /// "先逛逛" 文本跟随系统字号放大的上限, 超过该倍率会溢出纸色三角区域.
  static const _maxTextScale = 1.2;

  /// 计算单个静置周期内 [t] 时刻的页角掀动幅度, 仅在 [_liftSpan] 区间内缓起缓落, 取值范围 0 到 1.
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
            final shown = (_eyesShown + _eyesPeek * lift) * _peek.value;
            return SizedBox(
              width: extent * _CurlPainter.aspect,
              height: extent,
              child: CustomPaint(
                painter: _CurlPainter(
                  paper: c.paper,
                  back: stage,
                  shadow: c.shade,
                ),
                child: ClipPath(
                  clipper: const _RevealClipper(),
                  child: Stack(
                    children: [
                      Positioned(
                        top: top + _labelTop,
                        right: _labelInset,
                        child: label,
                      ),
                      Positioned(
                        top: top + _eyesTop,
                        right: shown - _eyesSize,
                        child: Transform.rotate(
                          angle: _eyesTilt,
                          child: const EmojiImage(Emoji.eyes, size: _eyesSize),
                        ),
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

/// 绘制卷起的页角: 模拟页角绕圆柱卷过半圈后平铺覆盖在页面上方, 从正上方俯视的几何投影.
///
/// 以页角为坐标原点, p 轴沿卷起方向指向页面内部, w 轴与之垂直. 卷起方向相对对角线偏移 [_lean], 使翻折后的页角呈倾斜状.
/// 设圆柱半径为 r, 页面在 p = a 处离开桌面, 原位于 p = t 的线段展开长度 u = a - t, 卷起后坐标为:
///
/// - 圆柱段 (u <= πr): p = a - r·sin(u/r).
/// - 覆盖平面段 (u > πr): p = a + u - πr.
///
/// 线段宽度保持不变, 页面原有的两条直边在圆柱段上投影为曲线.
/// 整体采用扁平色块绘制, 不加高光与模糊阴影, 图层由下至上依次为:
///
/// 1. 纸色底区: p < a 的三角区域, 可见部分为画布对角线右上方的一半.
/// 2. 阴影色块: 卷起部分向页面内侧偏移的硬边投影, 仅落在舞台底色上.
/// 3. 圆柱下半圈: 页面正面向上弯曲的部分, 因比上半圈宽而在两端露出.
/// 4. 圆柱上半圈与翻折页角: 朝上的一面为页面背面, 圆柱上缘向内绘制渐变过渡到页角背面的颜色.
class _CurlPainter extends CustomPainter {
  const new({required this.paper, required this.back, required this.shadow});

  final Color paper;

  /// 舞台色, 即页面正面的颜色.
  final Color back;
  final Color shadow;

  /// 卷起方向与页面顶边的夹角. 若取 45° 则页角沿对角线翻折, 翻折后的两条边呈水平和垂直方向, 视觉较呆板.
  static const _lean = 53 * math.pi / 180;

  /// 画布的宽高比.
  static final double aspect = math.tan(_lean);

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
