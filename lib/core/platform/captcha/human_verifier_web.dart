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
/// 浮层在启动时即插入 DOM, 初始全透明且仅拦截点击; 待容器获得非零尺寸后再淡入遮罩, 时长与对话框进出一致.
/// 无风险时腾讯不渲染任何内容 (容器保持 0×0), 但 `ready` 回调仍会触发, 因此不能以 `ready` 为准,
/// 从而在加载期间与无感通过时保持原页面与按钮加载态.
///
/// 有风险时腾讯另外弹出滑块拼图, 挂在 `body` 下, 遮罩层级为 2000000000, 弹窗层级为 2000000002.
/// 浮层层级必须低于二者, 否则拼图会被本站的遮罩压暗, 勾选框也会盖住拼图.
class _JsHumanVerifier implements HumanVerifier {
  final _loaded = <String, Future<bool>>{};

  @override
  Future<CaptchaOutcome> verify(
    BuildContext context,
    Future<CaptchaParams?> pendingParams,
  ) async {
    final completer = Completer<CaptchaOutcome>();
    final overlay = web.HTMLDivElement();
    final reduceMotion = web.window
        .matchMedia('(prefers-reduced-motion: reduce)')
        .matches;
    overlay.style
      ..position = 'fixed'
      ..inset = '0'
      ..zIndex = '1000'
      ..display = 'flex'
      ..alignItems = 'center'
      ..justifyContent = 'center'
      ..background = 'rgba(35, 28, 24, 0)'
      ..transition = reduceMotion ? 'none' : 'background-color 200ms ease-out';
    final container = web.HTMLDivElement();
    overlay.append(container);

    final observer = web.ResizeObserver(
      (JSArray<web.ResizeObserverEntry> entries, web.ResizeObserver _) {
        final box = entries.toDart.first.contentRect;
        if (box.width > 0 && box.height > 0) {
          overlay.style.background = 'rgba(35, 28, 24, 0.45)';
        }
      }.toJS,
    )..observe(container);

    void finish(CaptchaOutcome outcome) {
      if (completer.isCompleted) return;
      observer.disconnect();
      overlay.remove();
      completer.complete(outcome);
    }

    web.document.body!.append(overlay);
    final CaptchaParams? params;
    try {
      params = await pendingParams;
    } on Object {
      observer.disconnect();
      overlay.remove();
      rethrow;
    }
    if (params == null) {
      finish(const CaptchaSkipped());
      return completer.future;
    }
    if (!await _load(params.scriptUrl)) {
      finish(const CaptchaFailed());
      return completer.future;
    }
    if (completer.isCompleted) return completer.future;

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

  /// 同一地址的脚本仅加载一次; 若加载失败则移除缓存记录以便下次重试.
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
