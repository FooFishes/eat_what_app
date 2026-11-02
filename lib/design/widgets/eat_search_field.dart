import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:material_ui/material_ui.dart';

/// 无描边的胶囊搜索框.
///
/// 白底页面上为 `mist` 底. [floating] 为 true 时浮于地图之上, 使用 `paper` 底加 `shadow-float`.
///
/// [hintText] 写明可搜索的内容, 如 "搜店名" "搜店名或菜名". 读屏同样朗读这段文字.
class EatSearchField extends StatelessWidget {
  const new({
    super.key,
    required this.hintText,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.floating = false,
    this.onFilter,
    this.filterCount = 0,
  });

  final String hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool floating;

  /// 筛选按钮的回调. 不为 null 时在胶囊右端显示圆形筛选按钮.
  final VoidCallback? onFilter;

  /// 已选的筛选项数. 大于 0 时在筛选按钮右上角显示该数字.
  final int filterCount;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final textStyle = eat.text.body.copyWith(height: 22 / 15, color: c.ink);
    return Container(
      height: 48,
      padding: EdgeInsets.only(left: 16, right: onFilter == null ? 16 : 4),
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: floating ? c.paper : c.mist,
        shadows: floating ? eat.shadows.float.outer : null,
      ),
      child: Row(
        children: [
          EatIcon(EatIcons.search, size: 20, color: c.ink),
          const SizedBox(width: EatSpace.s10),
          Expanded(
            child: Material(
              type: MaterialType.transparency,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: autofocus,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                textInputAction: TextInputAction.search,
                style: textStyle,
                cursorColor: c.ink,

                /// 文字行高 22px, 低于最小点击高度. 上下留白把输入区补足到胶囊的 48px.
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  hintText: hintText,
                  hintStyle: textStyle.copyWith(color: c.inkMuted),
                ),
              ),
            ),
          ),
          if (onFilter case final onFilter?)
            EatTappable(
              onTap: onFilter,
              label: filterCount > 0 ? '筛选，已选 $filterCount 项' : '筛选',
              focusShape: const CircleBorder(),
              builder: (context, _) => Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: EatSize.touch,
                    height: EatSize.touch,
                    decoration: BoxDecoration(
                      color: c.mist,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: EatIcon(EatIcons.filter, size: 18, color: c.ink),
                    ),
                  ),
                  if (filterCount > 0)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: ExcludeSemantics(
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 18),
                          height: 18,
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: c.ink,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: [
                              BoxShadow(spreadRadius: 2, color: c.paper),
                            ],
                          ),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              '$filterCount',
                              style: eat.text.count.copyWith(
                                fontSize: 11,
                                height: 1,
                                color: c.paper,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
