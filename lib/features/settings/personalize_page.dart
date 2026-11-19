import 'package:eat/design/icons/illustrations.dart';

import 'dart:async';

import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_nav_bar.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/widgets/eat_haptics.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/eat_slider.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/design/widgets/theme_cross_fade.dart';
import 'package:eat/features/settings/widgets/settings_group.dart';
import 'package:eat/state/appearance.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 个性化设置页面: 切换界面深浅色, 调节底部导航栏液态玻璃透明度并实时预览效果.
class PersonalizePage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final c = eat.colors;
    final transparency = ref.watch(navGlassTransparencyProvider);
    final notifier = ref.read(navGlassTransparencyProvider.notifier);
    final percent = '${(transparency * 100).round()}%';
    final appearance = ref.watch(appearancePreferenceProvider);
    return PlainScaffold(
      title: '个性化',
      slivers: [
        SliverList.list(
          children: [
            _AppearanceOptions(current: appearance),
            const SizedBox(height: EatSpace.s24),
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: ListGroupTitle('底部导航'),
            ),
            const SizedBox(height: EatSpace.s8),
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
/// 只露出导航栏和四周一圈舞台色, 插画的碗沿正好压在导航栏下面, 拖动透明度滑条时能看出透过玻璃的清晰度变化.
class _Preview extends StatelessWidget {
  const new({required this.transparency});

  final double transparency;

  static const _inset = EatSpace.s16;
  static const _height = EatSize.nav + _inset * 2;
  static const _bowl = 240.0;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: ClipRRect(
        borderRadius: const BorderRadius.all(EatRadius.thumbLg),
        child: ColoredBox(
          color: StageColor.chili.colorIn(dark: context.eat.colors.isDark),
          child: SizedBox(
            height: _height,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                const Positioned(
                  top: -_bowl * 0.12,
                  child: IllustrationImage(Illustration.yuntun, size: _bowl),
                ),
                Positioned(
                  left: _inset,
                  right: _inset,
                  bottom: _inset,
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

/// 外观的三个选项.
///
/// 点了先在本页把勾打上, 等勾的动画播完再换整个 App 的深浅色 (由 [ThemeCrossFade] 过渡). 换主题要重建整棵树, 和勾的动画挤在同一段时间里会掉帧.
class _AppearanceOptions extends ConsumerStatefulWidget {
  const new({required this.current});

  final Appearance current;

  @override
  ConsumerState<_AppearanceOptions> createState() => _AppearanceOptionsState();
}

class _AppearanceOptionsState extends ConsumerState<_AppearanceOptions> {
  Appearance? _picked;
  Timer? _apply;

  /// 点了马上离开本页时, 等不到动画播完, 直接换.
  VoidCallback? _applyNow;

  @override
  void dispose() {
    if (_apply?.isActive ?? false) {
      _apply!.cancel();
      _applyNow?.call();
    }
    super.dispose();
  }

  void _pick(Appearance option) {
    setState(() => _picked = option);
    final notifier = ref.read(appearancePreferenceProvider.notifier);
    _applyNow = () => unawaited(notifier.select(option));
    _apply?.cancel();
    _apply = Timer(EatMotion.select.duration, () {
      ThemeCrossFade.capture(context);
      _applyNow?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final shown = _picked ?? widget.current;
    return SettingsGroup(
      title: '外观',
      dividerIndent: 0,
      children: [
        for (final (option, label) in const [
          (Appearance.system, '跟随系统'),
          (Appearance.light, '浅色'),
          (Appearance.dark, '深色'),
        ])
          _AppearanceRow(
            label: label,
            selected: option == shown,
            onTap: () => _pick(option),
          ),
      ],
    );
  }
}

/// 外观卡片里的一行: 名称, 选中时右侧打勾并加粗.
class _AppearanceRow extends StatelessWidget {
  const new({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final duration = context.motion(EatMotion.select);
    return EatTappable(
      onTap: () {
        if (!selected) EatHaptics.selection();
        onTap();
      },
      button: false,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      focusShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(EatRadius.thumb),
      ),
      builder: (context, _) => SizedBox(
        height: 52,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: eat.text.subhead.copyWith(
                  color: c.ink,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: duration,
              curve: EatMotion.select.curve,
              child: EatIcon(EatIcons.check, size: 20, color: c.ink),
            ),
          ],
        ),
      ),
    );
  }
}
