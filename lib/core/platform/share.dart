import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

part 'share.g.dart';

/// 分享的结果：弹了系统分享，还是退回复制链接。
enum ShareOutcome { shared, copied, failed }

/// 分享一个链接：安卓、iOS 弹系统分享；Web 在支持 Web Share 的浏览器上弹系统分享，
/// 不支持时（微信内置浏览器）复制链接，由页面提示一句（技术架构 6.4、依赖选型）。
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
      // 浏览器不支持 Web Share，退回复制链接。
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
