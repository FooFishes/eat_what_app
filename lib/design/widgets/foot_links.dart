import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:flutter/widgets.dart';

/// 页面最底下居中的一行小字链接, 放不常用的入口, 如 "编辑" "修改记录".
///
/// 每个链接的点击区域不小于 [EatSize.touch].
class FootLinks extends StatelessWidget {
  const new(this.links, {super.key});

  final List<({String label, VoidCallback onTap})> links;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: EatSpace.s16,
      children: [
        for (final link in links)
          EatTappable(
            onTap: link.onTap,
            label: link.label,
            builder: (context, _) => ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: EatSize.touch,
                minHeight: EatSize.touch,
              ),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: ExcludeSemantics(
                  child: Text(
                    link.label,
                    style: eat.text.meta.copyWith(
                      color: eat.colors.inkMuted,
                      decoration: TextDecoration.underline,
                      decorationColor: eat.colors.inkMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
