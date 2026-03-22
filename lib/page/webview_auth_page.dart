import 'package:eat_what_app/core/constant/urls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../provider/auth_provider.dart';

class WebviewAuthPage extends ConsumerWidget {
  const WebviewAuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(authProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('统一认证界面')),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(Urls.baseUrl + Urls.sduAuth),
          headers: token != null ? {'satoken': 'Bearer $token'} : null,
        ),
        initialSettings: InAppWebViewSettings(javaScriptEnabled: true),
        onLoadStop: (controller, url) async {
          if (url == null) return;
          final urlStr = url.toString();
          if (urlStr.contains('/callback')) {
            context.pop();
          }
        },
      ),
    );
  }
}
