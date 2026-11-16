import 'package:eat/data/feedback/feedback_repository.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/models/report.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/features/system/report_panel.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 打开店铺详情的 "信息有误" 反馈面板, 选择错误类型并填写可选说明, 提交成功后弹出轻提示.
Future<void> showShopErrorPanel(
  BuildContext context,
  WidgetRef ref,
  Shop shop,
) async {
  if (!await guardAction(context, ref, Capability.reportShopError) ||
      !context.mounted) {
    return;
  }
  final repository = ref.read(feedbackRepositoryProvider);
  final sent = await showPanel<bool>(
    context,
    builder: (panel) => ReasonPanel<ShopErrorType>(
      title: '信息有误',
      subtitle: [shop.name, ?shop.address].join('  '),
      options: ShopErrorType.values,
      label: (type) => type.label,
      capability: Capability.reportShopError,
      submit: (type, note) =>
          repository.reportShopError(shopId: shop.id, type: type, note: note),
    ),
  );
  if (sent == true && context.mounted) {
    showToast(context, '已提交，核实后会通过消息通知你');
  }
}
