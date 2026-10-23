import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/stage_scaffold.dart';
import 'package:flutter/widgets.dart';

/// 附近页。地图、定位和店铺抽屉在阶段三接上，现在用地图底色占住舞台，抽屉里是加载占位。
class NearbyPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return StageScaffold.map(
      map: ColoredBox(color: eat.colors.mapGround),
      sheetSlivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
          sliver: SliverToBoxAdapter(
            child: Semantics(
              header: true,
              child: Text('附近的店', style: eat.text.sectionTitle),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: EatSpace.s14)),
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: EatSpace.s20),
          sliver: SliverToBoxAdapter(
            child: RowListPlaceholder(count: 6, thumbSize: EatSize.thumbLg),
          ),
        ),
      ],
    );
  }
}
