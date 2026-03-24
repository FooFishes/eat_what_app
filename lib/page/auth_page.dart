import 'package:eat_what_app/core/constant/urls.dart';
import 'package:eat_what_app/core/error/app_error_presenter.dart';
import 'package:eat_what_app/provider/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eat_what_app/widget/app_toast.dart';

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
      appBar: AppBar(title: Text('认证页面'), centerTitle: false),
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
    final result = await context.push('/webview-auth');

    if (result == true) {
      await checkVerifyStatus();
    } else if (result == false) {
      if (!mounted) return;

      setState(() {
        isLoading = true;
      });

      bool success = false;
      for (int i = 0; i < 3; i++) {
        await Future.delayed(const Duration(seconds: 1));
        final status = await ref
            .read(authProvider.notifier)
            .checkVerifyStatus();
        if (status) {
          success = true;
          break;
        }
      }

      if (mounted) {
        setState(() {
          isVerified = success;
          isLoading = false;
        });

        if (!success) {
          AppErrorPresenter.showErrorToast(context, '认证超时或失败，请重试');
        }
      }
    }
  }

  void _showEmailDialog() {
    showDialog(
      context: context,
      builder: (context) => const EmailInputDialog(),
    );
  }
}

class EmailInputDialog extends ConsumerStatefulWidget {
  const EmailInputDialog({super.key});

  @override
  ConsumerState<EmailInputDialog> createState() => _EmailInputDialogState();
}

class _EmailInputDialogState extends ConsumerState<EmailInputDialog> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty ||
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      AppErrorPresenter.showErrorToast(context, '请输入有效的邮箱地址');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).sendVerifyEmail(email);
      if (mounted) {
        Navigator.of(context).pop();
        AppErrorPresenter.showMessageToast(
          context,
          '验证邮件已发送，请查收邮箱',
          type: AppToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppErrorPresenter.showErrorToast(context, '发送失败，请检查网络或重试');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color:
              Theme.of(context).dialogTheme.backgroundColor ??
              Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "山大邮箱验证",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "请输入您的山大邮箱地址进行身份认证，我们将向该邮箱发送一封验证邮件。",
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "example@mail.sdu.edu.cn",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: Colors.grey.shade500,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "取消",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendEmail,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("发送验证邮件", style: TextStyle(fontSize: 15)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
