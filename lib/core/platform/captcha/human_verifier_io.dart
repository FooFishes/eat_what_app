import 'dart:async';
import 'dart:convert';

import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/platform/captcha/human_verifier.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

HumanVerifier createHumanVerifier(AppConfig config) =>
    _WebViewHumanVerifier(config.webBaseUrl);

/// App 中的人机验证. 推入一个全屏透明页面, 其中的 WebView 加载腾讯的 JS, 结果经 JS 通道返回.
///
/// 页面内容为 [_page], 通过 `loadHtmlString` 加载, `baseUrl` 设为 Web 版地址.
/// 腾讯按页面来源校验域名, 因此校验到的是本站域名, 且无需在 Web 版单独部署验证页.
class _WebViewHumanVerifier implements HumanVerifier {
  _WebViewHumanVerifier(this._baseUrl);

  final String _baseUrl;

  @override
  Future<CaptchaOutcome> verify(BuildContext context, CaptchaParams params) =>
      Navigator.of(context, rootNavigator: true)
          .push<CaptchaOutcome>(
            PageRouteBuilder(
              opaque: false,
              barrierDismissible: false,
              pageBuilder: (_, _, _) =>
                  _CaptchaView(params: params, baseUrl: _baseUrl),
            ),
          )
          .then((outcome) => outcome ?? const CaptchaCancelled());
}

class _CaptchaView extends StatefulWidget {
  const new({required this.params, required this.baseUrl});

  final CaptchaParams params;
  final String baseUrl;

  @override
  State<_CaptchaView> createState() => _CaptchaViewState();
}

class _CaptchaViewState extends State<_CaptchaView> {
  late final WebViewController _controller;
  Timer? _timeout;
  var _done = false;

  @override
  void initState() {
    super.initState();
    final params = widget.params;
    final options = jsonEncode({
      'appId': params.appId,
      'scriptUrl': params.scriptUrl,
      'aidEncrypted': params.aidEncrypted,
      'aidEncryptedType': params.aidEncryptedType,
    });
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel('EatCaptcha', onMessageReceived: _onMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) =>
              _controller.runJavaScript('window.eatStart($options);'),
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) _finish(const CaptchaFailed());
          },
        ),
      )
      ..loadHtmlString(_page, baseUrl: widget.baseUrl);
    // 脚本加载超时按失败处理.
    // 脚本加载完成 (收到 `ready`) 后停止计时, 因为用户可能正在手动验证.
    _timeout = Timer(
      const Duration(seconds: 20),
      () => _finish(const CaptchaFailed()),
    );
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  void _onMessage(JavaScriptMessage message) {
    final Object? data;
    try {
      data = jsonDecode(message.message);
    } on FormatException {
      return _finish(const CaptchaFailed());
    }
    if (data is! Map) return _finish(const CaptchaFailed());
    if (data['ready'] == true) return _timeout?.cancel();
    _finish(
      captchaOutcomeOf(
        ret: (data['ret'] as num?)?.toInt(),
        ticket: data['ticket'] as String?,
        randstr: data['randstr'] as String?,
      ),
    );
  }

  void _finish(CaptchaOutcome outcome) {
    if (_done || !mounted) return;
    _done = true;
    _timeout?.cancel();
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _finish(const CaptchaCancelled());
    },
    child: WebViewWidget(controller: _controller),
  );
}

/// 验证页的 HTML.
///
/// 按接口给出的地址加载腾讯的 JS, 新建验证实例并渲染到居中的容器中. 回调结果原样传回 Flutter.
///
/// - `TJNCaptcha-global.js` 的构造函数第一个参数必须是 DOM 容器, 只传 appId 会直接抛出异常.
/// - 控制台配置的 "我是人类" 勾选框渲染在容器内且没有关闭按钮, 因此点击遮罩空白处视为用户关闭.
/// - 接口要求每次验证使用新页面和新实例, 不复用上一次的实例.
const _page = '''
<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<style>
html,body{margin:0;height:100%}
body{display:flex;align-items:center;justify-content:center;background:rgba(35,28,24,0.45)}
</style>
</head>
<body>
<div id="eat-captcha"></div>
<script>
function eatPost(result) { EatCaptcha.postMessage(JSON.stringify(result)); }
document.body.addEventListener('click', function (e) {
  if (e.target === document.body) eatPost({ ret: 2 });
});
window.eatStart = function (o) {
  var script = document.createElement('script');
  script.src = o.scriptUrl;
  script.onerror = function () { eatPost({ ret: -1 }); };
  script.onload = function () {
    try {
      var container = document.getElementById('eat-captcha');
      var captcha = new TencentCaptcha(container, o.appId, function (res) {
        eatPost({ ret: res.ret, ticket: res.ticket, randstr: res.randstr });
      }, { aidEncrypted: o.aidEncrypted, aidEncryptedType: o.aidEncryptedType, userLanguage: 'zh-cn' });
      captcha.show();
      eatPost({ ready: true });
    } catch (e) {
      eatPost({ ret: -1 });
    }
  };
  document.head.appendChild(script);
};
</script>
</body>
</html>
''';
