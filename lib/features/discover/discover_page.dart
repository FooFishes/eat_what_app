import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/stage_scaffold.dart';
import 'package:flutter/widgets.dart';

/// 发现页。转盘、推荐流和地点饭点在阶段三接上，现在是舞台加抽屉的骨架和加载占位。
class DiscoverPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return StageScaffold(
      stage: StageColor.broth,
      stageContent: const StagePlaceholder(),
      sheetSlivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
          sliver: SliverToBoxAdapter(
            child: Semantics(
              header: true,
              child: Text('今日推荐', style: eat.text.sectionTitle),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: EatSpace.s14)),
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: EatSpace.s20),
          sliver: SliverToBoxAdapter(child: TileGridPlaceholder(count: 6)),
        ),
      ],
    );
  }
}
