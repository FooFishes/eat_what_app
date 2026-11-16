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

/// 个性化页面: 底部导航液态玻璃的透明度. 滑条上方的预览随拖动实时变化.
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

/// 导航压在舞台色和菜品插画上的样子, 只用于预览, 不响应点击, 不参与读屏.
///
/// 碗的下半截压在导航下面, 拖动滑条时能直接看到碗里的东西变清楚或变模糊.
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
