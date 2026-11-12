import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:eat/features/verify/verify_providers.dart';
import 'package:eat/router/paths.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deep_links.g.dart';

// TODO: 白名单为空, 分享链接无法打开对应页面. 实现分享后在 [locationOf] 中加入 https://eat.v50to.you 的分享链接,
// 并加回安卓清单的 intent-filter、iOS 的 Associated Domains 和域名校验文件.
/// 外部链接的统一入口: 按白名单把外部链接转为站内地址.
///
/// Flutter 自带的深链已在 Android 和 iOS 上关闭, App 收到的链接全部经过本类.
/// App 的统一认证回跳由 `core/platform/browser.dart` 的认证会话直接收下, 不经过本类.
abstract final class DeepLinks {
  /// 外部链接对应的站内地址. 不在白名单中的链接返回 null, 调用方忽略该链接.
  static String? locationOf(Uri link) => null;

  /// Web 的统一认证回跳地址 ([Paths.ssoCallback]) 的查询参数对应的认证页地址.
  ///
  /// 成功时带上 `ticket`, 由认证页提交. 失败时带上 `code`.
  /// `result` 既不是 success 也不是 failure 时只打开认证页, 认证页仍会刷新认证状态.
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

  /// 认证页地址中的统一认证结果. 没有结果时返回 null.
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

/// App 收到的外部链接, 包括冷启动时的链接.
abstract interface class LinkSource {
  Stream<Uri> get links;
}

class AppLinksSource implements LinkSource {
  /// Web 的地址直接由路由表解析, 不经过 app_links.
  @override
  Stream<Uri> get links =>
      kIsWeb ? const Stream.empty() : AppLinks().uriLinkStream;
}

@Riverpod(keepAlive: true)
LinkSource linkSource(Ref ref) => AppLinksSource();

/// 把 [LinkSource] 收到的链接转为站内跳转.
///
/// - 当前页面是认证页时替换该页, 保留 `onboarding` 和 `from`.
/// - 其余情况在当前页面上方打开目标, 返回时回到原页面. 冷启动时原页面是发现页.
/// - 未登录时由守卫转到登录页, 登录后回到目标.
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
