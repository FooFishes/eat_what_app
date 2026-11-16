import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

part 'share.g.dart';

/// 分享的结果: 已弹出系统分享, 已退回复制链接, 或失败.
enum ShareOutcome { shared, copied, failed }

/// 链接分享能力封装.
///
/// 在 Android, iOS 及支持 Web Share 的浏览器中拉起系统分享.
/// 不支持时 (如微信内置浏览器) 则退回复制链接并由页面提示用户.
abstract interface class LinkSharer {
  Future<ShareOutcome> share(Uri link, {required String title});

  Future<ShareOutcome> copy(Uri link);
}

class PlatformLinkSharer implements LinkSharer {
  @override
  Future<ShareOutcome> share(Uri link, {required String title}) async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(uri: link, title: title, subject: title),
      );
      if (result.status != ShareResultStatus.unavailable) {
        return ShareOutcome.shared;
      }
    } on Object {
      // 浏览器不支持 Web Share, 退回复制链接.
    }
    return copy(link);
  }

  @override
  Future<ShareOutcome> copy(Uri link) async {
    try {
      await Clipboard.setData(ClipboardData(text: link.toString()));
      return ShareOutcome.copied;
    } on Object {
      return ShareOutcome.failed;
    }
  }
}

@Riverpod(keepAlive: true)
LinkSharer linkSharer(Ref ref) => PlatformLinkSharer();
