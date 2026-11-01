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
                decoration: InputDecoration.collapsed(
                  hintText: hintText,
                  hintStyle: textStyle.copyWith(color: c.inkMuted),
                ),
              ),
            ),
          ),
          if (onFilter case final onFilter?)
            EatTappable(
              onTap: onFilter,
              label: '筛选',
              focusShape: const CircleBorder(),
              builder: (context, _) => Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: c.mist,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: EatIcon(EatIcons.filter, size: 18, color: c.ink),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
