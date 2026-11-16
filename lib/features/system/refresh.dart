import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

/// 页面下拉刷新的统一封装, 先将 [invalidate] 中的 Provider 置为失效, 再等待 [wait] 完成新数据加载.
///
/// - 刷新期间保留页面现有内容而不展示加载占位.
/// - 若刷新失败则弹出轻提示说明原因, 页面继续保留原有内容.
///
/// [wait] 通常传入 `() => ref.read(provider.future)` 以等待页面主请求完成.
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
