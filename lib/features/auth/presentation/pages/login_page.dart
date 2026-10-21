import 'package:eat_what_app/core/error/app_error_presenter.dart';
import 'package:eat_what_app/core/theme/app_colors.dart';
import 'package:eat_what_app/features/auth/presentation/view_models/auth_session_view_model.dart';
import 'package:eat_what_app/shared/presentation/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  const new({super.key, required this.initialIsLoginMode});

  final bool initialIsLoginMode;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  static const Duration _switchDuration = Duration(milliseconds: 260);

  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late bool _isLoginMode = widget.initialIsLoginMode;
  bool _agreePrivacyPolicy = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<String?> authState = ref.watch(
      authSessionViewModelProvider,
    );
    final bool isSubmitting = authState.isLoading;

    ref.listen<AsyncValue<String?>>(authSessionViewModelProvider, (
      AsyncValue<String?>? previous,
      AsyncValue<String?> next,
    ) {
      next.whenOrNull(
        error: (Object error, StackTrace stackTrace) {
          AppErrorPresenter.showErrorToast(context, error);
        },
      );
    });

    final EdgeInsets viewPadding = MediaQuery.paddingOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: GestureDetector(
          behavior: .translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: <Widget>[
              const Positioned.fill(child: _LoginBackdrop()),
              CustomScrollView(
                slivers: <Widget>[
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      children: <Widget>[
                        SizedBox(height: viewPadding.top),
                        const Expanded(child: Center(child: _BrandHeader())),
                        _EntranceTransition(
                          child: _buildFormCard(
                            isSubmitting: isSubmitting,
                            bottomPadding: viewPadding.bottom,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard({
    required bool isSubmitting,
    required double bottomPadding,
  }) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: .fromLTRB(24, 24, 24, 20 + bottomPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: const .vertical(top: Radius.circular(32)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.accentBrown.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: AutofillGroup(
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: <Widget>[
            _ModeSwitcher(
              isLoginMode: _isLoginMode,
              enabled: !isSubmitting,
              duration: _switchDuration,
              onChanged: _setLoginMode,
            ),
            const SizedBox(height: 28),
            AnimatedSwitcher(
              duration: _switchDuration,
              layoutBuilder: (Widget? current, List<Widget> previous) {
                return Stack(
                  alignment: .topLeft,
                  children: <Widget>[...previous, ?current],
                );
              },
              child: Column(
                key: ValueKey<bool>(_isLoginMode),
                crossAxisAlignment: .start,
                children: <Widget>[
                  Text(
                    _isLoginMode ? '欢迎回来 👋' : '创建新账号 ✨',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: .w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isLoginMode ? '登录后看看今天大家都在吃什么' : '注册一个账号，开始记录你的美食足迹',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _AuthTextField(
              controller: _accountController,
              hintText: '请输入账号',
              icon: Icons.person_outline_rounded,
              enabled: !isSubmitting,
              textInputAction: .next,
              autofillHints: const <String>[AutofillHints.username],
            ),
            const SizedBox(height: 14),
            _AuthTextField(
              controller: _passwordController,
              hintText: '请输入密码',
              icon: Icons.lock_outline_rounded,
              enabled: !isSubmitting,
              obscureText: _obscurePassword,
              textInputAction: .done,
              autofillHints: <String>[
                _isLoginMode
                    ? AutofillHints.password
                    : AutofillHints.newPassword,
              ],
              onSubmitted: (_) {
                if (!isSubmitting) _onSubmit();
              },
              suffix: IconButton(
                tooltip: _obscurePassword ? '显示密码' : '隐藏密码',
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: AppColors.textHint,
                ),
              ),
            ),
            AnimatedSize(
              duration: _switchDuration,
              curve: Curves.easeOutCubic,
              alignment: .topCenter,
              child: _isLoginMode
                  ? Align(
                      alignment: .centerRight,
                      child: TextButton(
                        onPressed: isSubmitting ? null : _goForgotPassword,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textTertiary,
                          textStyle: theme.textTheme.bodyMedium,
                          padding: const .symmetric(horizontal: 4),
                        ),
                        child: const Text('忘记密码？'),
                      ),
                    )
                  : const SizedBox(width: double.infinity, height: 24),
            ),
            const SizedBox(height: 12),
            _GradientButton(
              label: _isLoginMode ? '登录' : '注册',
              isLoading: isSubmitting,
              onPressed: isSubmitting ? null : _onSubmit,
            ),
            const SizedBox(height: 16),
            _AgreementRow(
              agreed: _agreePrivacyPolicy,
              enabled: !isSubmitting,
              onChanged: (bool value) {
                setState(() => _agreePrivacyPolicy = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _setLoginMode(bool isLoginMode) {
    if (_isLoginMode == isLoginMode) return;
    setState(() => _isLoginMode = isLoginMode);
  }

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();

    if (!_agreePrivacyPolicy) {
      AppErrorPresenter.showMessageToast(
        context,
        '请先同意隐私政策',
        type: AppToastType.warning,
      );
      return;
    }

    final String account = _accountController.text.trim();
    final String password = _passwordController.text;
    if (account.isEmpty || password.isEmpty) {
      AppErrorPresenter.showMessageToast(
        context,
        '请输入账号和密码',
        type: AppToastType.warning,
      );
      return;
    }

    if (_isLoginMode) {
      await ref
          .read(authSessionViewModelProvider.notifier)
          .login(account, password);
      return;
    }

    await ref
        .read(authSessionViewModelProvider.notifier)
        .register(account, password);
  }

  void _goForgotPassword() {
    context.push('/forgot-password');
  }
}

/// 暖黄渐变底色 + 淡棕色美食涂鸦，作为整个页面的背景。
class _LoginBackdrop extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: .topCenter,
          end: .bottomCenter,
          colors: <Color>[Color(0xFFFFDD7A), AppColors.background],
          stops: <double>[0.0, 0.6],
        ),
      ),
      child: Align(
        alignment: .topCenter,
        child: Image.asset(
          'assets/images/login_header.png',
          width: double.infinity,
          fit: .cover,
          color: AppColors.accentBrown.withValues(alpha: 0.22),
          colorBlendMode: .srcIn,
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const .fromLTRB(24, 40, 24, 36),
      child: Column(
        mainAxisSize: .min,
        children: <Widget>[
          Container(
            width: 80,
            height: 80,
            alignment: .center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: .circular(26),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.primaryStrong.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Text('😋', style: TextStyle(fontSize: 42)),
          ),
          const SizedBox(height: 18),
          Text(
            '沙软今天吃什么',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: .w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '不知道吃什么？让大家帮你决定',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 表单卡片首次出现时自下而上淡入。
class _EntranceTransition extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (BuildContext context, double t, Widget? child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 48 * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}

/// 登录 / 注册切换，选中态是一个滑动的白色胶囊。
class _ModeSwitcher extends StatelessWidget {
  const new({
    required this.isLoginMode,
    required this.enabled,
    required this.duration,
    required this.onChanged,
  });

  final bool isLoginMode;
  final bool enabled;
  final Duration duration;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const .all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: .circular(24),
      ),
      child: Stack(
        fit: .expand,
        children: <Widget>[
          AnimatedAlign(
            alignment: isLoginMode ? .centerLeft : .centerRight,
            duration: duration,
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: .circular(20),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.accentBrown.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: <Widget>[
              _buildTab(context, label: '登录', value: true),
              _buildTab(context, label: '注册', value: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    BuildContext context, {
    required String label,
    required bool value,
  }) {
    final bool selected = isLoginMode == value;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          behavior: .opaque,
          onTap: enabled ? () => onChanged(value) : null,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: duration,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: selected
                    ? AppColors.primaryStrong
                    : AppColors.textTertiary,
                fontWeight: selected ? .w700 : .w500,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const new({
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.enabled,
    this.obscureText = false,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.suffix,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool enabled;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    const OutlineInputBorder border = OutlineInputBorder(
      borderRadius: .all(Radius.circular(16)),
      borderSide: BorderSide(color: AppColors.card),
    );
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onSubmitted: onSubmitted,
      cursorColor: AppColors.primaryStrong,
      style: textTheme.bodyLarge?.copyWith(fontWeight: .w500),
      decoration: InputDecoration(
        filled: true,
        fillColor: WidgetStateColor.resolveWith(
          (Set<WidgetState> states) => states.contains(WidgetState.focused)
              ? Colors.white
              : AppColors.background,
        ),
        hoverColor: Colors.transparent,
        hintText: hintText,
        hintStyle: textTheme.bodyLarge?.copyWith(color: AppColors.textHint),
        prefixIcon: Icon(icon, size: 22),
        prefixIconColor: WidgetStateColor.resolveWith(
          (Set<WidgetState> states) => states.contains(WidgetState.focused)
              ? AppColors.primaryStrong
              : AppColors.textHint,
        ),
        suffixIcon: suffix,
        contentPadding: const .symmetric(horizontal: 16, vertical: 16),
        enabledBorder: border,
        disabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const new({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = .circular(16);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: .centerLeft,
          end: .centerRight,
          colors: <Color>[AppColors.primary, AppColors.primaryStrong],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primaryStrong.withValues(alpha: 0.32),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        type: .transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onPressed,
          child: SizedBox(
            height: 54,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        label,
                        key: ValueKey<String>(label),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: .w700,
                              letterSpacing: 4,
                            ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AgreementRow extends StatelessWidget {
  const new({
    required this.agreed,
    required this.enabled,
    required this.onChanged,
  });

  final bool agreed;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        checked: agreed,
        child: GestureDetector(
          behavior: .opaque,
          onTap: enabled ? () => onChanged(!agreed) : null,
          child: Padding(
            padding: const .symmetric(vertical: 6, horizontal: 8),
            child: Row(
              mainAxisSize: .min,
              children: <Widget>[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: .circle,
                    color: agreed ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: agreed ? AppColors.primary : AppColors.textHint,
                      width: 1.5,
                    ),
                  ),
                  child: agreed
                      ? const Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Text.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(fontSize: 13, color: AppColors.textTertiary),
                    children: const <InlineSpan>[
                      TextSpan(text: '我已阅读并同意'),
                      TextSpan(
                        text: '《隐私政策》',
                        style: TextStyle(
                          color: AppColors.primaryStrong,
                          fontWeight: .w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
