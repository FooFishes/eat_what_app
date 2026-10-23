import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:flutter/widgets.dart';

/// 发布第 1 步：选店。附近的店、搜店名和新建店在阶段四接上，现在只有页面骨架。
class PublishPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => const PlainScaffold(
    title: '在哪家吃的？',
    slivers: [
      SliverToBoxAdapter(
        child: RowListPlaceholder(count: 5, thumbSize: EatSize.thumb),
      ),
    ],
  );
}
