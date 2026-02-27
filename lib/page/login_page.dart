import 'package:eat_what_app/core/error/app_error_presenter.dart';
import 'package:eat_what_app/provider/auth_provider.dart';
import 'package:eat_what_app/widget/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, required this.initialIsLoginMode});

  final bool initialIsLoginMode;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  static const Color _inputBackgroundColor = Color(0xFFF2F2F4);
  static const Color _inputBorderColor = Color(0xFFFF9A3D);
  static const Color _hintTextColor = Color(0xFF9A9A9A);
  static const Color _loginButtonColor = _inputBorderColor;
  static const Color _privacyHighlightColor = Color(0xFFFF8C2A);

  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool get _isLoginMode => widget.initialIsLoginMode;
  bool _agreePrivacyPolicy = false;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<String?> authState = ref.watch(authProvider);
    final bool isSubmitting = authState.isLoading;

    ref.listen<AsyncValue<String?>>(authProvider, (
      AsyncValue<String?>? previous,
      AsyncValue<String?> next,
    ) {
      next.whenOrNull(
        error: (Object error, StackTrace stackTrace) {
          AppErrorPresenter.showErrorToast(context, error);
        },
      );
    });

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double maxHeight = constraints.maxHeight;
            return Stack(
              children: <Widget>[
                _buildHeader(constraints),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(minHeight: maxHeight * 0.66),
                    padding: const EdgeInsets.fromLTRB(36, 36, 28, 36),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(70),
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Color(0x44000000),
                          blurRadius: 18,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(height: 12),
                          Text(
                            '😋 欢迎使用 ~',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildAuthTextField(
                            controller: _accountController,
                            hintText: '请输入账号',
                            enabled: !isSubmitting,
                          ),
                          const SizedBox(height: 18),
                          _buildAuthTextField(
                            controller: _passwordController,
                            hintText: '请输入密码',
                            enabled: !isSubmitting,
                            obscureText: true,
                          ),
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Checkbox(
                                value: _agreePrivacyPolicy,
                                shape: const CircleBorder(),
                                side: const BorderSide(
                                  color: Color(0xFF2A2A2A),
                                ),
                                onChanged: isSubmitting
                                    ? null
                                    : (bool? value) {
                                        setState(() {
                                          _agreePrivacyPolicy = value ?? false;
                                        });
                                      },
                              ),
                              RichText(
                                text: TextSpan(
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 16,
                                    color: const Color(0xFF111111),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  children: const <InlineSpan>[
                                    TextSpan(text: '我已阅读并同意'),
                                    TextSpan(
                                      text: '隐私政策',
                                      style: TextStyle(
                                        color: _privacyHighlightColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isSubmitting ? null : _onSubmit,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                minimumSize: const Size.fromHeight(60),
                                backgroundColor: _loginButtonColor,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: _loginButtonColor
                                    .withValues(alpha: 0.72),
                                disabledForegroundColor: Colors.white70,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40),
                                ),
                              ),
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isLoginMode ? '登录' : '注册',
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: <Widget>[
                              TextButton(
                                onPressed: isSubmitting
                                    ? null
                                    : _toggleAuthMode,
                                child: Text(_isLoginMode ? '去注册' : '去登录'),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: isSubmitting
                                    ? null
                                    : _goForgotPassword,
                                child: const Text('忘记密码？'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAuthTextField({
    required TextEditingController controller,
    required String hintText,
    required bool enabled,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
      decoration: _buildAuthInputDecoration(hintText),
    );
  }

  InputDecoration _buildAuthInputDecoration(String hintText) {
    const OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(38)),
      borderSide: BorderSide(color: _inputBorderColor, width: 2),
    );
    return InputDecoration(
      filled: true,
      fillColor: _inputBackgroundColor,
      hintText: hintText,
      hintStyle: const TextStyle(
        color: _hintTextColor,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
      enabledBorder: border,
      focusedBorder: border,
      disabledBorder: border,
    );
  }

  void _toggleAuthMode() {
    context.go(_isLoginMode ? '/register' : '/login');
  }

  Future<void> _onSubmit() async {
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
      await ref.read(authProvider.notifier).login(account, password);
      return;
    }

    await ref.read(authProvider.notifier).register(account, password);
  }

  void _goForgotPassword() {
    context.go('/forgot-password');
  }

  Widget _buildHeader(BoxConstraints constraints) {
    final double maxHeight = constraints.maxHeight;
    final double headerHeight = maxHeight * 0.38;
    return SizedBox(
      width: double.infinity,
      height: headerHeight,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0xAAFFD100), Color(0xFFFFFFFF)],
                stops: <double>[0.0, 0.7],
              ),
            ),
          ),
          Image.asset('assets/images/login_header.png', fit: BoxFit.cover),
        ],
      ),
    );
  }
}
