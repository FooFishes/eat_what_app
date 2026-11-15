import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/core/platform/captcha/human_verifier.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/rules/account_rules.dart';
import 'package:eat/features/settings/settings_providers.dart';
import 'package:eat/features/settings/widgets/code_field.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 换绑手机. 账号还没有手机号时改为绑定手机.
///
/// - 换绑分三步: 用当前号码的验证码确认身份, 验证新号码, 提交. 不能用密码代替当前号码.
/// - 新号码已注册其他账号时不能换绑.
/// - 换绑后其他设备要重新登录, 本机不受影响.
/// - 服务端拒绝的原因按步骤就地显示: 当前号码的验证码错误或校验过期时回到第一步.
class PhonePage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<PhonePage> createState() => _PhonePageState();
}

class _PhonePageState extends ConsumerState<PhonePage> {
  final _oldCode = TextEditingController();
  final _mobile = TextEditingController();
  final _newCode = TextEditingController();
  String? _oldError;
  String? _mobileError;
  String? _newCodeError;
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_oldCode, _mobile, _newCode]) {
      c.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _oldCode.dispose();
    _mobile.dispose();
    _newCode.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  PhoneChange get _change => ref.read(phoneChangeProvider.notifier);

  Future<CaptchaOutcome> _presentCaptcha(Future<CaptchaParams?> params) async {
    if (!mounted) return const CaptchaCancelled();
    return ref.read(humanVerifierProvider).verify(context, params);
  }

  /// 发送验证码. 失败时就地提示并返回 false.
  Future<bool> _send(Future<bool> Function() send) async {
    setState(() {
      _oldError = null;
      _mobileError = null;
      _newCodeError = null;
    });
    try {
      return await send();
    } on AppFailure catch (e) {
      if (mounted) _fail(e, sendingNew: true);
      return false;
    }
  }

  /// 第一步填好验证码后进入第二步.
  void _next() {
    FocusScope.of(context).unfocus();
    setState(() => _oldError = null);
    _change.enterOldCode(_oldCode.text);
  }

  Future<void> _submit({required bool binding}) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _mobileError = null;
      _newCodeError = null;
    });
    try {
      if (binding) {
        await _change.bind(_mobile.text, _newCode.text);
      } else {
        await _change.commit(_mobile.text, _newCode.text);
      }
      if (!mounted) return;
      showToast(context, binding ? '手机号已绑定' : '手机号已换绑');
      // 登录态变化后路由会重新匹配当前地址. 在本轮重建结束后返回, 否则本页会被重新放回路由栈.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) BackFallback.back(context);
      });
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _fail(e, sendingNew: false);
    }
  }

  /// 把失败显示在对应的输入框下. [sendingNew] 表示失败来自给新号码发码.
  ///
  /// 给新号码发码时的验证码错误指当前号码的验证码, 此时进度已回到第一步.
  void _fail(AppFailure e, {required bool sendingNew}) => setState(() {
    switch (e.code) {
      case BizCodes.wrongCode when sendingNew:
        _oldCode.clear();
        _oldError = '验证码错误，请重新输入';
      case BizCodes.wrongCode:
        _newCodeError = '验证码错误，请重新输入';
      case BizCodes.paramMissing || BizCodes.stateNotAllowed
          when !ref.read(phoneChangeProvider).verifyingNew:
        _oldCode.clear();
        _oldError = '请重新验证当前手机号';
      case BizCodes.opFailed:
        _mobileError = '这个号码已注册其他账号';
      case BizCodes.paramInvalid:
        _mobileError = '这就是现在绑定的号码';
      default:
        if (e.kind != FailureKind.cancelled) showToast(context, e.message);
    }
  });

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final current = switch (ref.watch(sessionProvider)) {
      SignedIn(:final user) => user?.phone,
      SignedOut() || Guest() => null,
    };
    final binding = current == null;
    final progress = ref.watch(phoneChangeProvider);
    final note = eat.text.caption.copyWith(color: c.inkMuted);
    final List<Widget> fields;
    if (!binding && !progress.verifyingNew) {
      fields = [
        Text('先验证现在绑定的手机', style: eat.text.subhead.copyWith(color: c.ink)),
        const SizedBox(height: EatSpace.s14),
        CodeField(
          label: '验证码',
          controller: _oldCode,
          errorText: _oldError,
          note: '验证码发到 ${AccountRules.maskMobile(current)}',
          onSend: () => _send(() => _change.sendOldCode(_presentCaptcha)),
        ),
        const SizedBox(height: 40),
        EatButton.solid(
          '下一步',
          onPressed: AccountRules.isSmsCode(_oldCode.text) ? _next : null,
        ),
      ];
    } else {
      final mobile = _mobile.text;
      final validMobile = AccountRules.isMobile(mobile) && mobile != current;
      final ready =
          !_submitting && validMobile && AccountRules.isSmsCode(_newCode.text);
      fields = [
        EatFormField(
          label: binding ? '手机号' : '新手机号',
          controller: _mobile,
          hintText: '11 位手机号',
          numeric: true,
          prefix: '+86',
          keyboardType: TextInputType.phone,
          autofocus: true,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          errorText: _mobileError,
          onSubmitted: (_) => setState(
            () => _mobileError = mobile == current
                ? '这就是现在绑定的号码'
                : AccountRules.isMobile(mobile)
                ? null
                : '请输入正确的手机号',
          ),
        ),
        const SizedBox(height: 26),
        CodeField(
          label: binding ? '验证码' : '新手机验证码',
          controller: _newCode,
          enabled: validMobile,
          errorText: _newCodeError,
          note: '已经注册过别的账号的号码不能${binding ? '绑定' : '换'}',
          onSend: () => _send(
            () => binding
                ? _change.sendBindCode(_presentCaptcha, mobile)
                : _change.sendNewCode(_presentCaptcha, mobile),
          ),
        ),
        const SizedBox(height: 40),
        if (!binding) ...[
          Text('换绑后用新号码登录，其他设备要重新登录。', style: note),
          const SizedBox(height: EatSpace.s14),
        ],
        EatButton.solid(
          binding ? '绑定' : '换绑',
          loading: _submitting,
          onPressed: ready ? () => _submit(binding: binding) : null,
        ),
      ];
    }
    return PlainScaffold(
      title: binding ? '绑定手机' : '换绑手机',
      subtitle: binding
          ? '绑定后可以用手机号登录'
          : '现在绑定的是 ${AccountRules.maskMobile(current)}',
      slivers: [
        SliverToBoxAdapter(
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: EatSpace.s14),
                ...fields,
                const SizedBox(height: EatSpace.s24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
