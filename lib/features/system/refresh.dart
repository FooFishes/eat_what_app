import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

/// 各页面下拉刷新的统一实现: 把 [invalidate] 中的 Provider 标记为过期, 然后等待 [wait] 返回新数据.
///
/// - 刷新期间页面保留原有内容, 不显示加载占位.
/// - 请求失败时用轻提示说明原因, 原有内容继续显示.
///
/// [wait] 通常为 `() => ref.read(provider.future)`, 取页面的主要请求.
Future<void> pullToRefresh(
  BuildContext context,
  WidgetRef ref, {
  required List<ProviderOrFamily> invalidate,
  required Future<Object?> Function() wait,
}) async {
  for (final provider in invalidate) {
    ref.invalidate(provider);
  }
  try {
    await wait();
  } on AppFailure catch (e) {
    if (context.mounted) showToast(context, e.message);
  }
}
