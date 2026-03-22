import 'package:eat_what_app/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的页面')),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                context.push('/auth');
              },
              child: Text('认证'),
            ),
            ElevatedButton(
              onPressed: () async {
                ref.read(authProvider.notifier).logout();
              },
              child: Text('登出'),
            ),
          ],
        ),
      ),
    );
  }
}
