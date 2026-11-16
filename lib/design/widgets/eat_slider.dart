import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:material_ui/material_ui.dart';

/// 白底页面上的滑条组件, 采用 `ink` 实心圆形滑块, 已选轨道为 `ink` 而未选部分为 `handle`.
///
/// 轨道两端与所在内容左右边缘对齐 (滑块拖到端点时外缘正好贴边), 禁用 Material 按下光晕并将可点击高度保持为 44.
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

  /// 松手时触发的回调, 用于承接保存等较重操作 (拖动过程中仅通过 [onChanged] 更新显示).
  final ValueChanged<double>? onChangeEnd;

  /// 读屏朗读当前值的格式化回调, 如 "透明度 70%".
  final SemanticFormatterCallback? semanticFormatterCallback;

  static const _thumbRadius = 11.0;
  static const _trackHeight = 4.0;

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    // Material 的 Slider 要求祖先节点中存在 Material, 白底页面不提供该节点, 因此在此补充一层透明容器.
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
