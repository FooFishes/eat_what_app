import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:eat/design/widgets/eat_tabs.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/stage_scaffold.dart';
import 'package:eat/router/paths.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// 「我的」主页面。资料、统计和两个网格在阶段三接上，评论还没有接口，带「待接入」。
/// 右上角是设置。
class MePage extends StatefulWidget {
  const new({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => StageScaffold(
    stage: StageColor.mango,
    stageContent: const StagePlaceholder(),
    topBar: Align(
      alignment: Alignment.centerRight,
      child: EatIconButton(
        EatIcons.settings,
        label: '设置',
        onPressed: () => context.push(Paths.settings),
      ),
    ),
    sheetSlivers: [
      SliverToBoxAdapter(
        child: EatTabs(
          tabs: const [
            EatTabItem('上传'),
            EatTabItem('收藏'),
            EatTabItem('评论', pending: true),
          ],
          selected: _tab,
          onSelected: (tab) => setState(() => _tab = tab),
          padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
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
