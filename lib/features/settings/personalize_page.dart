import 'package:eat/design/icons/illustrations.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_nav_bar.dart';
import 'package:eat/design/widgets/eat_slider.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/state/appearance.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 个性化设置页面, 用于调节底部导航栏液态玻璃透明度并实时预览效果.
class PersonalizePage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final c = eat.colors;
    final transparency = ref.watch(navGlassTransparencyProvider);
    final notifier = ref.read(navGlassTransparencyProvider.notifier);
    final percent = '${(transparency * 100).round()}%';
    return PlainScaffold(
      title: '个性化',
      slivers: [
        SliverList.list(
          children: [
            const ListGroupTitle('底部导航'),
            const SizedBox(height: EatSpace.s10),
            _Preview(transparency: transparency),
            const SizedBox(height: EatSpace.s20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    '透明度',
                    style: eat.text.body.copyWith(color: c.ink),
                  ),
                ),
                Text(percent, style: eat.text.count.copyWith(color: c.ink)),
              ],
            ),
            EatSlider(
              value: transparency,
              min: NavGlassTransparency.min,
              max: NavGlassTransparency.max,
              semanticFormatterCallback: (_) => '透明度 $percent',
              onChanged: notifier.set,
              onChangeEnd: (_) => notifier.save(),
            ),
            const SizedBox(height: EatSpace.s24),
          ],
        ),
      ],
    );
  }
}

/// 底部导航栏叠加在舞台色与菜品插画上的静态预览组件, 屏蔽交互点击与无障碍读屏.
///
/// 将插画碗部下半截置于导航栏下方, 以便拖动透明度滑条时直观观察透过毛玻璃的清晰度变化.
class _Preview extends StatelessWidget {
  const new({required this.transparency});

  final double transparency;

  static const _height = 200.0;
  static const _bowl = 240.0;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: ClipRRect(
        borderRadius: const BorderRadius.all(EatRadius.thumbLg),
        child: ColoredBox(
          color: StageColor.chili.color,
          child: SizedBox(
            height: _height,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                const Positioned(
                  bottom: -_bowl / 4,
                  child: IllustrationImage(Illustration.yuntun, size: _bowl),
                ),
                Positioned(
                  left: EatSpace.s16,
                  right: EatSpace.s16,
                  bottom: EatSpace.s16,
                  child: EatNavBar(
                    currentIndex: 0,
                    onSelected: (_) {},
                    onPublish: () {},
                    transparency: transparency,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
