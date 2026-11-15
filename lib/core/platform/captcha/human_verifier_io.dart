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
///
/// 推入页面后同时加载验证页和等待参数, 两者都完成后再开始验证.
/// 页面在验证组件渲染前完全透明, 只拦截点击.
class _WebViewHumanVerifier implements HumanVerifier {
  _WebViewHumanVerifier(this._baseUrl);

  final String _baseUrl;

  @override
  Future<CaptchaOutcome> verify(
    BuildContext context,
    Future<CaptchaParams?> params,
  ) async {
    final result = await Navigator.of(context, rootNavigator: true)
        .push<Object>(
          PageRouteBuilder(
            opaque: false,
            barrierDismissible: false,
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            pageBuilder: (_, _, _) =>
                _CaptchaView(params: params, baseUrl: _baseUrl),
          ),
        );
    return switch (result) {
      final CaptchaOutcome outcome => outcome,
      _ParamsError(:final error, :final stackTrace) =>
        Error.throwWithStackTrace(error, stackTrace),
      _ => const CaptchaCancelled(),
    };
  }
}

/// 获取参数失败. 先关闭验证页, 再由 [_WebViewHumanVerifier.verify] 抛出.
class const _ParamsError(final Object error, final StackTrace stackTrace);

class _CaptchaView extends StatefulWidget {
  const new({required this.params, required this.baseUrl});

  final Future<CaptchaParams?> params;
  final String baseUrl;

  @override
  State<_CaptchaView> createState() => _CaptchaViewState();
}

class _CaptchaViewState extends State<_CaptchaView> {
  late final WebViewController _controller;
  final _pageLoaded = Completer<void>();
  Timer? _timeout;
  var _done = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel('EatCaptcha', onMessageReceived: _onMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!_pageLoaded.isCompleted) _pageLoaded.complete();
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) _finish(const CaptchaFailed());
          },
        ),
      )
      ..loadHtmlString(_page, baseUrl: widget.baseUrl);
    _start();
  }

  /// 验证页已在 [initState] 中开始加载, 这里先等参数再等页面, 两者仍是同时进行的.
  Future<void> _start() async {
    final CaptchaParams? params;
    try {
      params = await widget.params;
    } on Object catch (error, stackTrace) {
      return _finish(_ParamsError(error, stackTrace));
    }
    if (params == null) return _finish(const CaptchaSkipped());
    await _pageLoaded.future;
    if (_done) return;
    final options = jsonEncode({
      'appId': params.appId,
      'scriptUrl': params.scriptUrl,
      'aidEncrypted': params.aidEncrypted,
      'aidEncryptedType': params.aidEncryptedType,
    });
    await _controller.runJavaScript('window.eatStart($options);');
    // 脚本加载超时按失败处理.
    // 脚本加载完成 (收到 `ready`) 后停止计时, 因为用户可能正在手动验证.
    if (!_done) {
      _timeout = Timer(
        const Duration(seconds: 20),
        () => _finish(const CaptchaFailed()),
      );
    }
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

  void _finish(Object result) {
    if (_done || !mounted) return;
    _done = true;
    _timeout?.cancel();
    Navigator.of(context).pop(result);
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
/// - 容器有了实际尺寸 (组件渲染出来) 后遮罩才淡入, 时长与对话框进出一致.
///   无风险时腾讯不渲染任何内容, 容器始终为 0×0, `ready` 回调也照常触发, 因此不能以 `ready` 为准.
///   加载期间和无感通过时页面一直透明, 用户看到的是原页面和按钮的加载状态.
const _page = '''
<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<style>
html,body{margin:0;height:100%}
body{display:flex;align-items:center;justify-content:center;background:rgba(35,28,24,0);transition:background-color 200ms ease-out}
body.shown{background:rgba(35,28,24,0.45)}
@media (prefers-reduced-motion:reduce){body{transition:none}}
</style>
</head>
<body>
<div id="eat-captcha"></div>
<script>
function eatPost(result) { EatCaptcha.postMessage(JSON.stringify(result)); }
document.body.addEventListener('click', function (e) {
  if (e.target === document.body) eatPost({ ret: 2 });
});
new ResizeObserver(function (entries) {
  var box = entries[0].contentRect;
  if (box.width > 0 && box.height > 0) document.body.classList.add('shown');
}).observe(document.getElementById('eat-captcha'));
window.eatStart = function (o) {
  var script = document.createElement('script');
  script.src = o.scriptUrl;
  script.onerror = function () { eatPost({ ret: -1 }); };
  script.onload = function () {
    try {
      var container = document.getElementById('eat-captcha');
      var captcha = new TencentCaptcha(container, o.appId, function (res) {
        eatPost({ ret: res.ret, ticket: res.ticket, randstr: res.randstr });
      }, {
        aidEncrypted: o.aidEncrypted, aidEncryptedType: o.aidEncryptedType, userLanguage: 'zh-cn'
      });
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
