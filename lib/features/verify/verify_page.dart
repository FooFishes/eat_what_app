import 'dart:async';

import 'package:clock/clock.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/core/platform/captcha/human_verifier.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/models/current_user.dart';
import 'package:eat/domain/rules/account_rules.dart';
import 'package:eat/features/verify/verify_providers.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 学生认证（`G-Verify`）：山大统一认证或山大邮箱，结果记到当前账号上，不用重新登录。
///
/// 两种入口：新号码注册后的认证引导（[onboarding]，右上角「先逛逛」），以及设置、拦截面板
/// 进来的普通页面（左上角返回）。回到前台和打开页面时自动刷新认证状态。
class VerifyPage extends ConsumerStatefulWidget {
  const new({super.key, this.onboarding = false, this.from});

  final bool onboarding;

  /// 认证引导结束后去哪，来自登录前要去的页面；没有就去发现页。
  final String? from;

  @override
  ConsumerState<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends ConsumerState<VerifyPage> {
  late final AppLifecycleListener _lifecycle;
  final _email = TextEditingController();
  String? _emailError;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(sessionProvider.notifier).finishOnboarding();
      // Web 上统一认证完成后整页跳回这里，打开时就刷新一次。
      _refresh();
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _email.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  /// 人机验证弹在这一页上；页面已经关掉时当作用户取消。
  Future<CaptchaOutcome> _presentCaptcha(CaptchaParams params) async {
    if (!mounted) return const CaptchaCancelled();
    return ref.read(humanVerifierProvider).verify(context, params);
  }

  void _refresh() => ref.read(verifyProvider.notifier).refresh();

  void _leave() => context.go(widget.from ?? Paths.discover);

  Future<void> _sendEmail() async {
    final email = _email.text.trim();
    if (!AccountRules.isSduEmail(email)) {
      setState(() => _emailError = '请填写 @mail.sdu.edu.cn 或 @sdu.edu.cn 邮箱');
      return;
    }
    setState(() => _emailError = null);
    await ref.read(verifyProvider.notifier).sendEmail(_presentCaptcha, email);
    if (!mounted || ref.read(verifyProvider).resendAt == null) return;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final resendAt = ref.read(verifyProvider).resendAt;
      if (resendAt == null || !clock.now().isBefore(resendAt)) timer.cancel();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final user = switch (ref.watch(sessionProvider)) {
      SignedIn(:final user) => user,
      SignedOut() => null,
    };
    final verify = ref.watch(verifyProvider);
    final verified = user?.verified ?? false;
    final small = eat.text.meta.copyWith(height: 20 / 13, color: c.inkMuted);

    return PlainScaffold(
      title: '学生认证',
      subtitle: '认证后可以发布、点赞、评论和关注。认证仅用于确认学生身份，我们无法获取你的统一认证密码。',
      showBack: !widget.onboarding,
      actions: [
        if (widget.onboarding && !verified) _TextAction('先逛逛', onTap: _leave),
      ],
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (verified)
                _Verified(
                  method: user!.verifyMethod,
                  onboarding: widget.onboarding,
                  onLeave: _leave,
                )
              else
                _Unverified(
                  state: verify,
                  email: _email,
                  emailError: _emailError,
                  onSso: () => ref.read(verifyProvider.notifier).startSso(),
                  onSendEmail: _sendEmail,
                  onEditEmail: () =>
                      ref.read(verifyProvider.notifier).editEmail(),
                  onRefresh: () => ref
                      .read(verifyProvider.notifier)
                      .refresh(userAsked: true),
                ),
              const SizedBox(height: 28),
              Text('每个统一认证身份、每个邮箱只能认证一个账号。校外用户可以注册和浏览，但无法认证。', style: small),
            ],
          ),
        ),
      ],
    );
  }
}

class _Unverified extends StatelessWidget {
  const new({
    required this.state,
    required this.email,
    required this.emailError,
    required this.onSso,
    required this.onSendEmail,
    required this.onEditEmail,
    required this.onRefresh,
  });

  final VerifyState state;
  final TextEditingController email;
  final String? emailError;
  final VoidCallback onSso;
  final VoidCallback onSendEmail;
  final VoidCallback onEditEmail;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final sentTo = state.emailSentTo;
    final resendAt = state.resendAt;
    final secondsLeft = resendAt == null
        ? 0
        : (resendAt.difference(clock.now()).inMilliseconds / 1000).ceil();
    final body = eat.text.body.copyWith(height: 22 / 15, color: c.ink);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: '现在 '),
              TextSpan(
                text: '未认证',
                style: TextStyle(fontWeight: FontWeight.w700, color: c.ink),
              ),
            ],
          ),
          style: eat.text.meta.copyWith(color: c.inkMuted),
        ),
        const SizedBox(height: EatSpace.s14),
        _MethodRow(
          icon: EatIcons.school,
          title: '山大统一认证',
          subtitle: '跳转至学校页面，完成后自动返回',
          trailing: EatIcons.external,
          onTap: state.busy ? null : onSso,
        ),
        const SizedBox(height: EatSpace.s14),
        Container(height: 1, color: c.hairline),
        const SizedBox(height: EatSpace.s14),
        const _MethodRow(
          icon: EatIcons.mail,
          title: '山大邮箱',
          subtitle: '点击邮件中的链接即可完成认证',
        ),
        const SizedBox(height: EatSpace.s16),
        if (sentTo == null) ...[
          EatFormField(
            label: '邮箱',
            controller: email,
            hintText: '@mail.sdu.edu.cn 或 @sdu.edu.cn',
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSendEmail(),
            errorText: emailError,
          ),
          const SizedBox(height: EatSpace.s20),
          EatButton.solid('发送认证链接', onPressed: state.busy ? null : onSendEmail),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: EatSpace.s8,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: EatIcon(EatIcons.mailSend, size: 18, color: c.ink),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: '认证链接已发送至 '),
                      TextSpan(
                        text: sentTo,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const TextSpan(text: '，点击链接即可完成认证，返回此页后自动刷新。'),
                    ],
                  ),
                  style: body,
                ),
              ),
            ],
          ),
          const SizedBox(height: EatSpace.s16),
        ],
        if (sentTo != null || state.ssoStarted) ...[
          if (sentTo == null) const SizedBox(height: EatSpace.s10),
          EatButton.outline('我已完成，刷新状态', onPressed: onRefresh),
        ],
        if (sentTo != null) ...[
          const SizedBox(height: 6),
          if (secondsLeft > 0)
            Center(
              child: SizedBox(
                height: EatSize.touch,
                child: Center(
                  child: Text(
                    '未收到？$secondsLeft 秒后可重新发送',
                    style: eat.text.meta.copyWith(color: c.inkMuted),
                  ),
                ),
              ),
            )
          else
            _TextAction('未收到？更换邮箱或重新发送', onTap: onEditEmail, center: true),
        ],
        if (state.notice case final notice?) ...[
          const SizedBox(height: EatSpace.s14),
          Semantics(
            liveRegion: true,
            child: Row(
              spacing: 6,
              children: [
                EatIcon(EatIcons.warning, size: 18, color: c.warn),
                Expanded(
                  child: Text(
                    notice,
                    style: eat.text.meta.copyWith(color: c.warn),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Verified extends StatelessWidget {
  const new({
    required this.method,
    required this.onboarding,
    required this.onLeave,
  });

  final VerifyMethod? method;
  final bool onboarding;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          spacing: EatSpace.s14,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle),
              child: Center(
                child: EatIcon(EatIcons.verify, size: 28, color: c.paper),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '已认证',
                    style: eat.text.sectionTitle.copyWith(color: c.ink),
                  ),
                  if (method case final method?)
                    Text(
                      method.label,
                      style: eat.text.meta.copyWith(color: c.inkMuted),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: EatSpace.s16),
        Text(
          '认证长期有效，毕业后不会收回。之前受限的操作现在可以继续。',
          style: eat.text.body.copyWith(height: 22 / 15, color: c.inkSoft),
        ),
        if (onboarding) ...[
          const SizedBox(height: EatSpace.s24),
          EatButton.solid('去看看今天吃什么', onPressed: onLeave),
        ],
      ],
    );
  }
}

/// 一种认证方式：左边 `mist` 圆底图标，中间名字和一句说明，能点时右边是外链图标。
class _MethodRow extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final EatIcons icon;
  final String title;
  final String subtitle;
  final EatIcons? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final row = Row(
      spacing: EatSpace.s14,
      children: [
        Container(
          width: EatSize.avatar,
          height: EatSize.avatar,
          decoration: BoxDecoration(color: c.mist, shape: BoxShape.circle),
          child: Center(child: EatIcon(icon, size: 22, color: c.ink)),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: eat.text.rowTitle.copyWith(color: c.ink)),
              Text(subtitle, style: eat.text.meta.copyWith(color: c.inkMuted)),
            ],
          ),
        ),
        if (trailing case final trailing?)
          EatIcon(trailing, size: 20, color: c.inkMuted),
      ],
    );
    final tap = onTap;
    if (trailing == null) return row;
    return EatTappable(
      onTap: tap,
      label: title,
      focusShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(EatRadius.thumb),
      ),
      builder: (context, _) => row,
    );
  }
}

/// 顶栏或段落里的文字按钮，点击区域 44px 高。
class _TextAction extends StatelessWidget {
  const new(this.label, {required this.onTap, this.center = false});

  final String label;
  final VoidCallback onTap;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final action = EatTappable(
      onTap: onTap,
      label: label,
      focusShape: const StadiumBorder(),
      builder: (context, _) => SizedBox(
        height: EatSize.touch,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: eat.text.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: eat.colors.ink,
              ),
            ),
          ),
        ),
      ),
    );
    return center ? Center(child: action) : action;
  }
}
