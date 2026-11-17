import 'package:eat/design/layout/eat_layout.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:flutter/widgets.dart';

/// 发布流程页面底部的固定操作栏, 包含主操作按钮及其上方的状态说明.
///
/// 软键盘弹出时自动隐藏, 避免操作栏被挤压在输入框与键盘之间; 收起键盘后恢复展示并允许点击主按钮.
class PublishBottomBar extends StatelessWidget {
  const new({super.key, required this.child, this.note});

  final Widget child;

  /// 显示在按钮上方的警示说明文案 (使用 `warn` 色), 例如 "请填写价格和分类".
  final String? note;

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.paddingOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context);
    if (keyboard.bottom > 0) return const SizedBox.shrink();
    final eat = context.eat;
    final padding = EatLayout.of(context).plainHorizontalPadding;
    return ColoredBox(
      color: eat.colors.paper,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          padding,
          EatSpace.s10,
          padding,
          safe.bottom + EatSpace.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: EatSpace.s8,
          children: [
            if (note case final note?)
              Text(
                note,
                textAlign: TextAlign.center,
                style: eat.text.meta.copyWith(color: eat.colors.warn),
              ),
            child,
          ],
        ),
      ),
    );
  }
}
