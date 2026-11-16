import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/features/verify/verify_providers.dart';
import 'package:eat/router/paths.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 邮箱认证落地页, 由认证邮件中的链接唤起, 负责提交链接携带的 [token] 并展示认证结果.
///
/// 仅限已登录用户访问, 未登录时由路由守卫先引导至登录页再返回本页.
/// [token] 须由发起认证的原账号提交, 若在其他账号下打开则提示切换回原账号处理.
class VerifyEmailPage extends ConsumerStatefulWidget {
  const new({super.key, required this.token});

  /// 链接地址中的 `token` 参数, 链接不完整时为 null.
  final String? token;

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  @override
  void initState() {
    super.initState();
    final token = widget.token;
    if (token == null || token.isEmpty) return;
    // 构建过程中不能修改 Provider, 因此在首帧结束后提交.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(emailVerificationProvider.notifier).submit(token);
    });
  }

  void _toVerify() => context.go(Paths.verify);

  @override
  Widget build(BuildContext context) {
    final token = widget.token;
    final progress = ref.watch(emailVerificationProvider);
    final Widget body;
    if (token == null || token.isEmpty) {
      body = _failed('链接不完整，请从邮件中重新打开');
    } else {
      body = switch (progress) {
        null || AsyncLoading() => const LoadingArea(
          child: EmptyState(icon: EatIcons.mail, title: '正在认证'),
        ),
        AsyncData() => EmptyState(
          icon: EatIcons.verify,
          title: '邮箱认证成功',
          message: '认证长期有效，现在可以发布和互动。',
          action: EatButton.solid('完成', onPressed: _toVerify),
        ),
        AsyncError(:final error) => switch (error) {
          AppFailure(code: BizCodes.alreadyVerified) => EmptyState(
            icon: EatIcons.verify,
            title: '账号已经认证过了',
            action: EatButton.solid('完成', onPressed: _toVerify),
          ),
          final AppFailure failure => _failed(failure.message),
          _ => _failed('操作失败，请重试'),
        },
      };
    }
    return PlainScaffold(
      title: '邮箱认证',
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: EatSpace.s24),
            child: body,
          ),
        ),
      ],
    );
  }

  Widget _failed(String message) => EmptyState(
    icon: EatIcons.warning,
    title: '认证没有完成',
    message: message,
    action: EatButton.outline('去认证页', onPressed: _toVerify),
  );
}
