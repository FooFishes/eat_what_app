import 'package:eat_what_app/core/error/app_error_presenter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<String?> authState = ref.watch(authProvider);
    ref.listen<AsyncValue<String?>>(authProvider, (
      AsyncValue<String?>? previous,
      AsyncValue<String?> next,
    ) {
      final shouldShow =
          previous is AsyncLoading<String?> || previous is AsyncData<String?>;
      if (!shouldShow) {
        return;
      }
      next.whenOrNull(
        error: (Object error, StackTrace stackTrace) {
          AppErrorPresenter.showErrorToast(context, error);
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('首页')),
      body: Center(
        child: Column(
          children: [
            Text('${authState.value}'),
            TextButton(
              onPressed: () {
                ref.read(authProvider.notifier).logout();
              },
              child: const Text('退出登录'),
            ),
          ],
        ),
      ),
      // TODO: Replace with your custom navigation bar.
      bottomNavigationBar: const _NavBarPlaceholder(),
    );
  }
}

class _NavBarPlaceholder extends StatelessWidget {
  const _NavBarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE6E8EB))),
      ),
      child: const Text('自定义导航栏占位'),
    );
  }
}
