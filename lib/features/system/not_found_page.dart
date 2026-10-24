import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/router/paths.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// 地址对不上任何页面时显示，比如分享链接里的路径打错了或已经下线。
class NotFoundPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => PlainScaffold(
    title: '页面不存在',
    slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: EmptyState(
            icon: EatIcons.question,
            title: '链接可能已失效',
            message: '回到发现页，看看今天吃什么。',
            action: EatButton.outline(
              '回到发现',
              icon: EatIcons.discover,
              height: 48,
              onPressed: () => context.go(Paths.discover),
            ),
          ),
        ),
      ),
    ],
  );
}
