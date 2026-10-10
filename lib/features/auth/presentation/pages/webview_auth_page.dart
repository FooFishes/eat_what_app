import 'package:eat_what_app/core/constant/urls.dart';
import 'package:eat_what_app/features/auth/presentation/view_models/auth_session_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WebviewAuthPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<WebviewAuthPage> createState() => _WebviewAuthPageState();
}

class _WebviewAuthPageState extends ConsumerState<WebviewAuthPage> {
  bool _hasPopped = false;

  void _checkAndPop(WebUri? url) {
    if (url == null || _hasPopped) return;
    final urlStr = url.toString();
    if (urlStr.contains('/callback')) {
      _hasPopped = true;
      final hasToken = url.queryParameters.containsKey('token');
      if (mounted) {
        context.pop(hasToken);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = ref.watch(authSessionViewModelProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('统一认证界面'), centerTitle: false),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(Urls.baseUrl + Urls.sduAuth),
          headers: token != null ? {'satoken': 'Bearer $token'} : null,
        ),
        initialSettings: InAppWebViewSettings(javaScriptEnabled: true),
        onLoadStart: (controller, url) async {
          _checkAndPop(url);
        },
        onUpdateVisitedHistory: (controller, url, isReload) async {
          _checkAndPop(url);
        },
        onLoadStop: (controller, url) async {
          _checkAndPop(url);
        },
      ),
    );
  }
}
