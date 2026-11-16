import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/router/paths.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// 路由无法匹配任何页面时的兜底页, 用于链接路径有误或页面已下线等场景.
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
