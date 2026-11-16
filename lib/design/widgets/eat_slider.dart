import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:material_ui/material_ui.dart';

/// 白底页面上的滑条: `ink` 实心的圆形滑块, 已选部分 `ink`, 其余 `handle`.
///
/// 轨道两端与所在内容的左右边缘对齐, 滑块拖到头时外缘正好贴边.
/// 不画 Material 的按下光晕, 可点击的高度保持 44.
class EatSlider extends StatelessWidget {
  const new({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.onChangeEnd,
    this.semanticFormatterCallback,
  });

  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  /// 松手时调用. 拖动中只更新显示, 保存等较重的操作放在这里.
  final ValueChanged<double>? onChangeEnd;

  /// 读屏念出的当前值, 如 "透明度 70%".
  final SemanticFormatterCallback? semanticFormatterCallback;

  static const _thumbRadius = 11.0;
  static const _trackHeight = 4.0;

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    // Material 的 Slider 要求有 Material 祖先, 白底页面没有, 在这里补一层透明的.
    return Material(
      type: MaterialType.transparency,
      child: SliderTheme(
        data: SliderThemeData(
          trackHeight: _trackHeight,
          activeTrackColor: c.ink,
          inactiveTrackColor: c.handle,
          thumbColor: c.ink,
          overlayColor: Colors.transparent,
          thumbShape: const RoundSliderThumbShape(
            enabledThumbRadius: _thumbRadius,
            elevation: 0,
            pressedElevation: 0,
          ),
          overlayShape: const RoundSliderOverlayShape(
            overlayRadius: EatSize.touch / 2,
          ),
          trackShape: const RoundedRectSliderTrackShape(),
          padding: const EdgeInsets.symmetric(horizontal: _thumbRadius),
        ),
        child: SizedBox(
          height: EatSize.touch,
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
            semanticFormatterCallback: semanticFormatterCallback,
          ),
        ),
      ),
    );
  }
}
