import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:material_ui/material_ui.dart';

/// 胶囊搜索框，没有描边：白底页面上 `mist` 底，浮在地图上时 [floating] 用 `paper` 底加 `shadow-float`。
///
/// [hintText] 说清楚能搜什么（「搜店名」「搜店名或菜名」），读屏也读这一句。
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

  /// 传了就在胶囊右端放一个 42px 的圆形筛选按钮。
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
