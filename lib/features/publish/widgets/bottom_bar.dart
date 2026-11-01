import 'package:eat/design/layout/eat_layout.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:flutter/widgets.dart';

/// 发布流程页面底部固定的一条：主按钮和它上面的说明。
///
/// 键盘弹起时收起来，让输入框和键盘之间不被它隔开；收起键盘再点。
class PublishBottomBar extends StatelessWidget {
  const new({super.key, required this.child, this.note});

  final Widget child;

  /// 按钮上方的一行，如「请填写价格和分类」，用 `warn`。
  final String? note;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.viewInsets.bottom > 0) return const SizedBox.shrink();
    final eat = context.eat;
    final padding = EatLayout.of(context).plainHorizontalPadding;
    return ColoredBox(
      color: eat.colors.paper,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          padding,
          EatSpace.s10,
          padding,
          media.padding.bottom + EatSpace.s16,
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
