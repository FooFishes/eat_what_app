import 'dart:async';
import 'dart:js_interop';

import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/platform/captcha/human_verifier.dart';
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

HumanVerifier createHumanVerifier(AppConfig config) => _JsHumanVerifier();

/// Web 中的人机验证. 在页面中加载腾讯的 JS, 每次验证新建一个实例.
///
/// `TJNCaptcha-global.js` 的构造函数第一个参数必须是 DOM 容器.
/// Flutter 的画布占满整页, 因此在画布上方添加带遮罩的浮层, 容器居中放在浮层内.
/// 点击遮罩空白处视为用户关闭.
///
/// 有风险时腾讯另外弹出滑块拼图, 挂在 `body` 下, 遮罩层级为 2000000000, 弹窗层级为 2000000002.
/// 浮层层级必须低于二者, 否则拼图会被本站的遮罩压暗, 勾选框也会盖住拼图.
class _JsHumanVerifier implements HumanVerifier {
  final _loaded = <String, Future<bool>>{};

  @override
  Future<CaptchaOutcome> verify(
    BuildContext context,
    CaptchaParams params,
  ) async {
    if (!await _load(params.scriptUrl)) return const CaptchaFailed();
    final completer = Completer<CaptchaOutcome>();
    final overlay = web.HTMLDivElement();
    overlay.style
      ..position = 'fixed'
      ..inset = '0'
      ..zIndex = '1000'
      ..display = 'flex'
      ..alignItems = 'center'
      ..justifyContent = 'center'
      ..background = 'rgba(35, 28, 24, 0.45)';
    final container = web.HTMLDivElement();
    overlay.append(container);

    void finish(CaptchaOutcome outcome) {
      if (completer.isCompleted) return;
      overlay.remove();
      completer.complete(outcome);
    }

    overlay.onclick = (web.MouseEvent e) {
      if (e.target == overlay) finish(const CaptchaCancelled());
    }.toJS;
    void onResult(_TencentResult res) => finish(
      captchaOutcomeOf(
        ret: res.ret?.toDartInt,
        ticket: res.ticket?.toDart,
        randstr: res.randstr?.toDart,
      ),
    );

    web.document.body!.append(overlay);
    try {
      final options = _TencentOptions(
        aidEncrypted: params.aidEncrypted.toJS,
        aidEncryptedType: params.aidEncryptedType.toJS,
        userLanguage: 'zh-cn'.toJS,
      );
      _TencentCaptcha(
        container,
        params.appId.toJS,
        onResult.toJS,
        options,
      ).show();
    } on Object {
      finish(const CaptchaFailed());
    }
    return completer.future;
  }

  /// 同一地址的脚本只加载一次. 加载失败时移除记录, 下次重新加载.
  Future<bool> _load(String src) {
    final pending = _loaded[src] ??= () {
      final done = Completer<bool>();
      final script = web.HTMLScriptElement()..src = src;
      script.onload = (web.Event _) {
        done.complete(true);
      }.toJS;
      script.onerror = (web.Event _) {
        done.complete(false);
      }.toJS;
      web.document.head!.append(script);
      return done.future;
    }();
    return pending.then((ok) {
      if (!ok) _loaded.remove(src);
      return ok;
    });
  }
}

@JS('TencentCaptcha')
extension type _TencentCaptcha._(JSObject _) implements JSObject {
  external factory _TencentCaptcha(
    web.HTMLElement container,
    JSString appId,
    JSFunction callback,
    _TencentOptions options,
  );

  external void show();
}

extension type _TencentOptions._(JSObject _) implements JSObject {
  external factory _TencentOptions({
    JSString aidEncrypted,
    JSString aidEncryptedType,
    JSString userLanguage,
  });
}

extension type _TencentResult._(JSObject _) implements JSObject {
  external JSNumber? get ret;
  external JSString? get ticket;
  external JSString? get randstr;
}
