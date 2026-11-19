import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'
    show ProviderListenable, ProviderOrFamily;

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

/// 先显示缓存的页面用: [provider] 带着旧数据重新请求失败时弹出轻提示, 页面继续显示旧数据.
///
/// 没有旧数据时不提示, 页面自己显示 "加载失败". 一个页面的几项数据常常一起失败, 同一条提示还在屏幕上时不再弹.
void toastStaleFailure<T>(
  BuildContext context,
  WidgetRef ref,
  ProviderListenable<AsyncValue<T>> provider,
) => ref.listen(provider, (previous, next) {
  if (!(previous?.isLoading ?? false) || next.isLoading) return;
  if (!next.hasValue || next.error is! AppFailure) return;
  final message = (next.error! as AppFailure).message;
  if (context.mounted && !isToastShowing(message)) showToast(context, message);
});
