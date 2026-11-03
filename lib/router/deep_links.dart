import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:eat/features/verify/verify_providers.dart';
import 'package:eat/router/paths.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deep_links.g.dart';

// TODO: 白名单只有统一认证的回跳链接, 分享链接无法打开对应页面. 实现分享后在 [locationOf] 中加入分享链接.
/// 外部链接的统一入口: 按白名单把外部链接转为站内地址.
///
/// Flutter 自带的深链已在 Android 和 iOS 上关闭, App 收到的链接全部经过本类.
abstract final class DeepLinks {
  /// 回跳链接和 App Links / Universal Links 校验文件所在的域名.
  static const host = 'eat.v50to.you';

  /// 外部链接对应的站内地址. 不在白名单中的链接返回 null, 调用方忽略该链接.
  static String? locationOf(Uri link) {
    if (link.scheme != 'https' ||
        link.host != host ||
        link.userInfo.isNotEmpty ||
        link.port != 443) {
      return null;
    }
    final path = link.path.endsWith('/')
        ? link.path.substring(0, link.path.length - 1)
        : link.path;
    if (path == Paths.ssoCallback) return ssoLocation(link.queryParameters);
    return null;
  }

  /// 统一认证回跳的查询参数对应的认证页地址.
  ///
  /// `result` 既不是 success 也不是 failure 时只打开认证页, 认证页仍会刷新认证状态.
  static String ssoLocation(Map<String, String> query) {
    final result = query['result'];
    if (result != 'success' && result != 'failure') return Paths.verify;
    return Uri(
      path: Paths.verify,
      queryParameters: {
        'sso': result!,
        if (result == 'failure') 'code': ?query['code'],
      },
    ).toString();
  }

  /// 认证页地址中的统一认证结果. 没有结果时返回 null.
  static SsoResult? ssoResultOf(Map<String, String> query) =>
      switch (query['sso']) {
        'success' => const SsoResult(success: true),
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
