import 'package:eat_what_app/core/constant/urls.dart';
import 'package:eat_what_app/core/error/api_exception.dart';
import 'package:eat_what_app/core/error/app_error_presenter.dart';
import 'package:eat_what_app/provider/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  bool isLoading = true;
  bool isVerified = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('认证页面')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text('正在检查认证状态...', style: TextStyle(color: Colors.grey)),
              ] else ...[
                Icon(
                  isVerified ? Icons.verified_user : Icons.gpp_maybe,
                  size: 80,
                  color: isVerified ? Colors.green : Colors.orange,
                ),
                const SizedBox(height: 24),
                Text(
                  isVerified ? '已完成认证' : '未完成认证',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isVerified ? '您可以正常使用所有功能了' : '请先完成认证以解锁全部功能',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                if (!isVerified)
                  Text(
                    '可选择统一认证或山大邮箱验证',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
              ],

              const SizedBox(height: 48),
              if (!isVerified && !isLoading) ...[
                SizedBox(
                  width: 240,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: kIsWeb ? _openWebAuthPage : _openMobileAuthPage,
                    icon: const Icon(Icons.security),
                    label: Text(
                      '统一认证登录验证',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: 240,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _showEmailDialog,
                    icon: const Icon(Icons.security),
                    label: Text('山大邮箱验证', style: const TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                SizedBox(height: 15),
                SizedBox(
                  width: 240,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _refreshVerifyStatus,
                    icon: const Icon(Icons.refresh),
                    label: Text('刷新认证状态', style: const TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    Future.microtask(() => checkVerifyStatus());
    super.initState();
  }

  Future<void> checkVerifyStatus() async {
    final status = await ref.read(authProvider.notifier).checkVerifyStatus();
    setState(() {
      isVerified = status;
      isLoading = false;
    });
  }

  Future<void> _refreshVerifyStatus() async {
    setState(() {
      isLoading = true;
    });
    await checkVerifyStatus();
  }

  Future<void> _openWebAuthPage() async {
    final url = Uri.parse(Urls.baseUrl + Urls.sduAuth);
    if (!await launchUrl(url, mode: LaunchMode.platformDefault)) {
      if (mounted) AppErrorPresenter.showErrorToast(context, '无法打开链接');
    }
  }

  Future<void> _openMobileAuthPage() async {
    context.push('/webview-auth');
  }

  void _showEmailDialog() {
    showDialog(
      context: context,
      builder: (context) => const _EmailInputDialog(),
    );
  }
}

class _EmailInputDialog extends StatefulWidget {
  const _EmailInputDialog();

  @override
  State<_EmailInputDialog> createState() => _EmailInputDialogState();
}

class _EmailInputDialogState extends State<_EmailInputDialog> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      // TODO: 调用发送邮件的 API
      // await ref.read(authProvider.notifier).sendVerificationEmail(_emailController.text.trim());

      await Future.delayed(const Duration(seconds: 1)); // 模拟网络请求

      if (mounted) {
        setState(() {
          _isLoading = false;
          _message = '邮件已发送，请查收';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _message = '发送失败，请重试';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.mail_outline, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    '邮箱验证',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '请输入您的山大邮箱地址，我们将发送验证码到您的邮箱。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: '邮箱地址',
                  hintText: 'example@mail.sdu.edu.cn',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入邮箱地址';
                  }
                  if (!value.endsWith('@mail.sdu.edu.cn')) {
                    return '请输入山大邮箱地址';
                  }
                  return null;
                },
              ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _message!.contains('失败')
                        ? Colors.red[50]
                        : Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _message!.contains('失败')
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        color: _message!.contains('失败')
                            ? Colors.red
                            : Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _message!,
                          style: TextStyle(
                            color: _message!.contains('失败')
                                ? Colors.red[700]
                                : Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _isLoading ? null : _sendEmail,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('发送邮件'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
