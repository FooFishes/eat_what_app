import 'dart:math' as math;

import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/platform/browser.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/icons/illustrations.dart';
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
/// 「手机号登录」和协议勾选。没勾协议时按钮不可用。
///
/// [query] 是地址里的 `from`、`expired`，原样带进手机号登录页，登录后守卫按它回到原页面。
class LoginPage extends ConsumerWidget {
  const new({super.key, this.query = const {}});

  final Map<String, String> query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final c = eat.colors;
    final agreed = ref.watch(loginAgreementProvider);
    final media = MediaQuery.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: EatStage(
        stage: StageColor.broth,
        child: Stack(
          children: [
            const Positioned.fill(child: _Turntable()),
            Positioned(
              left: EatSpace.s24,
              right: EatSpace.s24,
              top: media.padding.top + 60,
              child: const _Brand(),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.paper,
                      borderRadius: const BorderRadius.vertical(
                        top: EatRadius.sheet,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        EatSpace.s20,
                        EatSpace.s24,
                        EatSpace.s20,
                        30 + media.padding.bottom,
                      ),
                      child: DefaultTextStyle.merge(
                        style: TextStyle(color: c.ink),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: EatSpace.s10,
                          children: [
                            if (query['expired'] == '1')
                              const _Notice('登录已过期，请重新登录'),
                            EatButton.solid(
                              '手机号登录',
                              icon: EatIcons.phone,
                              onPressed: agreed
                                  ? () => context.go(
                                      Uri(
                                        path: Paths.loginPhone,
                                        queryParameters: query.isEmpty
                                            ? null
                                            : query,
                                      ).toString(),
                                    )
                                  : null,
                            ),
                            const AgreementCheck(),
                          ],
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
    );
  }
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
          // 按 390×844 的画板排：转盘圆心在抽屉顶部往下 323、离左边 159，菜离圆心 430。
          final center = Offset(
            constraints.maxWidth * 159 / 390,
            constraints.maxHeight - 284 + 323,
          );
          const radius = EatSize.turntableRadius;
          const extent = radius + 110;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: center.dx + 36 - 600,
                top: center.dy + 17 - 600,
                child: Container(
                  width: 1200,
                  height: 1200,
                  decoration: BoxDecoration(
                    color: palette.table,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: center.dx + 36 - 560,
                top: center.dy + 17 - 560,
                child: Container(
                  width: 1120,
                  height: 1120,
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
                              extent + radius * math.sin(i * math.pi / 6) - 110,
                          top:
                              extent - radius * math.cos(i * math.pi / 6) - 110,
                          child: Transform.rotate(
                            angle: i * math.pi / 6,
                            child: IllustrationImage(dish, size: 220),
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
/// 没勾时下面用 `warn` 写「请先勾选同意协议」。
class AgreementCheck extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<AgreementCheck> createState() => _AgreementCheckState();
}

class _AgreementCheckState extends ConsumerState<AgreementCheck> {
  late final _privacy = TapGestureRecognizer()
    ..onTap = () => _open(ref.read(appConfigProvider).privacyUrl);
  late final _terms = TapGestureRecognizer()
    ..onTap = () => _open(ref.read(appConfigProvider).termsUrl);

  @override
  void dispose() {
    _privacy.dispose();
    _terms.dispose();
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
    void toggle() =>
        ref.read(loginAgreementProvider.notifier).set(agreed: !agreed);
    TextSpan link(String text, TapGestureRecognizer recognizer) => TextSpan(
      text: text,
      style: const TextStyle(fontWeight: FontWeight.w600),
      recognizer: recognizer,
    );
    final style = eat.text.meta.copyWith(color: c.inkSoft);
    return Row(
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
                    if (!agreed)
                      Text(
                        '请先勾选同意协议',
                        style: style.copyWith(height: 20 / 13, color: c.warn),
                      ),
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

class _CheckCircle extends StatelessWidget {
  const new({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? c.ink : c.paper,
        border: checked ? null : Border.all(color: c.lineStrong, width: 1.5),
      ),
      child: checked
          ? Center(child: EatIcon(EatIcons.check, size: 14, color: c.paper))
          : null,
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
