import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/eat_palette.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/dish_plate.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:flutter/widgets.dart';

/// 「调整照片」底部的舞台色选择（规范 `StageColorPicker`）：从照片推荐的三个舞台色，下面实时预览
/// 这道菜在首页的样子。放在 `crop-panel` 底上，文字 `paper`。
///
/// 只能从给的 [candidates] 里选，不给任意取色的调色盘。
class StageColorPicker extends StatelessWidget {
  const new({
    super.key,
    required this.candidates,
    required this.selected,
    required this.onSelected,
    required this.dishName,
    this.image,
    this.centerX = 0.5,
    this.centerY = 0.5,
    this.diameter = 1,
  });

  final List<StageColor> candidates;
  final StageColor selected;
  final ValueChanged<StageColor> onSelected;

  /// 预览卡上的菜名，还没填时写「这道菜」。
  final String dishName;

  /// 预览卡右上角盘子里的封面，按裁切参数显示。
  final ImageProvider? image;
  final double centerX;
  final double centerY;
  final double diameter;

  static const _swatch = 36.0;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final paper = eat.colors.paper;
    final duration = context.motion(EatMotion.stageColor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '舞台颜色',
              style: eat.text.body.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: paper,
              ),
            ),
            const SizedBox(width: EatSpace.s8),
            Text(
              '从照片里推荐',
              style: eat.text.caption.copyWith(
                color: paper.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: EatSpace.s14),
        Semantics(
          container: true,
          label: '舞台颜色',
          child: Row(
            spacing: EatSpace.s16,
            children: [
              for (final color in candidates)
                EatTappable(
                  onTap: () => onSelected(color),
                  button: false,
                  checked: color == selected,
                  inMutuallyExclusiveGroup: true,
                  label: color.label,
                  focusShape: const CircleBorder(),
                  builder: (context, _) => SizedBox(
                    width: EatSize.touch + 8,
                    child: Column(
                      spacing: 6,
                      children: [
                        AnimatedContainer(
                          duration: context.motion(EatMotion.select),
                          width: _swatch,
                          height: _swatch,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.color,
                            boxShadow: [
                              if (color == selected) ...[
                                const BoxShadow(
                                  spreadRadius: 5,
                                  color: EatPalette.paper,
                                ),
                                const BoxShadow(
                                  spreadRadius: 3,
                                  color: EatPalette.cropPanel,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          color.label,
                          style: eat.text.caption.copyWith(
                            fontSize: 11,
                            fontWeight: color == selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: paper,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: EatSpace.s16),
        Text(
          '首页会是这样',
          style: eat.text.caption.copyWith(color: paper.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: EatSpace.s8),
        ExcludeSemantics(
          child: AnimatedContainer(
            duration: duration,
            curve: EatMotion.stageColor.curve,
            height: 84,
            decoration: BoxDecoration(
              color: selected.color,
              borderRadius: const BorderRadius.all(EatRadius.tile),
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                Positioned(
                  left: EatSpace.s16,
                  right: 110,
                  bottom: EatSpace.s14,
                  child: Text(
                    dishName.isEmpty ? '这道菜' : dishName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: eat.text.stageDish.copyWith(
                      fontSize: 22,
                      height: 1.2,
                      color: selected.foreground,
                    ),
                  ),
                ),
                if (image case final image?)
                  Positioned(
                    right: -12,
                    top: 12,
                    child: DishPlate(
                      image: image,
                      size: 100,
                      centerX: centerX,
                      centerY: centerY,
                      diameter: diameter,
                      shadow: false,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
