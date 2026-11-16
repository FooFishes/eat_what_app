import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:eat/features/verify/verify_providers.dart';
import 'package:eat/router/paths.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deep_links.g.dart';

// TODO: 当前外部链接白名单为空, 分享链接无法打开对应页面. 实现分享功能后在 [locationOf] 中加入 https://eat.v50to.you 的匹配规则,
// 并恢复 Android 清单的 intent-filter, iOS 的 Associated Domains 及域名校验文件.
/// 外部链接解析入口, 按白名单将外部链接转换为站内地址.
///
/// Android 与 iOS 端已关闭 Flutter 自带的深链处理, 客户端收到的链接均经由此类分发.
/// 原生端的统一认证回调由 `core/platform/browser.dart` 中的认证会话直接接收, 不经过此类.
abstract final class DeepLinks {
  /// 返回外部链接对应的站内地址. 若链接不在白名单中则返回 null, 由调用方忽略.
  static String? locationOf(Uri link) => null;

  /// 将 Web 统一认证回调地址 ([Paths.ssoCallback]) 的查询参数转换为认证页地址.
  ///
  /// 认证成功时携带一次性 `ticket` 交由认证页提交, 失败时携带业务码 `code`.
  /// 若 `result` 既非 success 也非 failure, 则仅跳转至认证页并由页面自行刷新认证状态.
  static String ssoLocation(Map<String, String> query) {
    final result = query['result'];
    if (result != 'success' && result != 'failure') return Paths.verify;
    return Uri(
      path: Paths.verify,
      queryParameters: {
        'sso': result!,
        if (result == 'success') 'ticket': ?query['ticket'],
        if (result == 'failure') 'code': ?query['code'],
      },
    ).toString();
  }

  /// 解析认证页查询参数中的统一认证结果, 没有结果时返回 null.
  static SsoResult? ssoResultOf(Map<String, String> query) =>
      switch (query['sso']) {
        'success' => SsoResult(success: true, ticket: query['ticket']),
        'failure' => SsoResult(
          success: false,
          code: int.tryParse(query['code'] ?? ''),
        ),
        _ => null,
      };
}

/// 外部链接事件源接口, 提供包含冷启动在内的外部链接流.
abstract interface class LinkSource {
  Stream<Uri> get links;
}

class AppLinksSource implements LinkSource {
  /// Web 端地址直接由路由表解析, 不经过 app_links.
  @override
  Stream<Uri> get links =>
      kIsWeb ? const Stream.empty() : AppLinks().uriLinkStream;
}

@Riverpod(keepAlive: true)
LinkSource linkSource(Ref ref) => AppLinksSource();

/// 监听 [LinkSource] 并将收到的外部链接转换为站内跳转.
///
/// - 若当前页面与目标页面均为认证页则直接替换当前页, 并保留原有的 `onboarding` 和 `from` 参数.
/// - 其余情况在当前页面上方压入目标页 (冷启动时底层为发现页), 返回时回到原页面.
/// - 若目标页要求登录而当前未登录, 则由路由守卫先导向登录页, 登录后再跳转至目标页.
class DeepLinkHandler {
  DeepLinkHandler(this._router);

  final GoRouter _router;
  StreamSubscription<Uri>? _subscription;

  void listen(Stream<Uri> links) {
    _subscription = links.listen(handle);
  }

  Future<void> handle(Uri link) async {
    final target = DeepLinks.locationOf(link);
    if (target == null) return;
    // 路由尚未解析初始地址时 (首帧之前) push 没有可叠加的页面栈, 因此等待首帧结束.
    if (_router.routerDelegate.currentConfiguration.isEmpty) {
      await WidgetsBinding.instance.endOfFrame;
    }
    // currentConfiguration.uri 是页面栈底部 go 到的地址, 不含 push 打开的页面. state 对应最上方的页面.
    final current = _router.state.uri;
    final next = Uri.parse(target);
    if (current.path == Paths.verify && next.path == Paths.verify) {
      final query = {
        for (final key in const ['onboarding', 'from'])
          key: ?current.queryParameters[key],
        ...next.queryParameters,
      };
      unawaited(
        _router.pushReplacement(
          Uri(
            path: Paths.verify,
            queryParameters: query.isEmpty ? null : query,
          ).toString(),
        ),
      );
    } else {
      unawaited(_router.push(target));
    }
  }

  void dispose() => _subscription?.cancel();
}
