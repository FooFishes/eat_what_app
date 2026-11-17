import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_sheet.dart';
import 'package:eat/design/widgets/keyboard_inset.dart';
import 'package:material_ui/material_ui.dart';

/// 从底部弹出面板, 背后覆盖 `scrim`, 点击遮罩或下拉均可关闭.
///
/// - 不修改路由地址, 不跳转新页面.
/// - 面板高度随内容自适应, 但不超过最大高度限制.
/// - 系统开启减少动态效果时禁用进出动画.
/// - [builder] 通常返回 [EatPanel], 且面板内不再嵌套打开新面板.
///
/// 面板挂载在根导航器上: 由于主页面的导航栏悬浮在分支导航器之上, 若挂载在分支导航器上会导致底部按钮被导航栏遮挡.
Future<T?> showPanel<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final eat = context.eat;
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    builder: builder,
    isScrollControlled: true,
    backgroundColor: eat.colors.paper,
    barrierColor: eat.colors.scrim,
    barrierLabel: '关闭面板',
    elevation: 0,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: EatRadius.sheet),
    ),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    ),
    sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: Duration(milliseconds: 240),
            reverseDuration: Duration(milliseconds: 240),
          ),
  );
}

/// 底部面板的内部布局, 依次包含把手, 标题, 可选的说明行, 主体内容和底部按钮.
///
/// 头部有两种样式:
/// - 普通面板: 标题和右侧关闭按钮.
/// - 提示类面板 (拦截, 功能关闭, 操作受限): 传入 [icon] 后左侧显示 `mist` 圆底图标, 右侧标题说明当前状况,
///   不显示关闭按钮而由底部按钮提供下一步操作.
///
/// 内容超出高度时仅中间主体区域滚动, 头部标题与底部按钮保持固定.
class EatPanel extends StatelessWidget {
  const new({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.child,
    this.actions,
    this.onClose,
  });

  final String title;
  final String? subtitle;
  final EatIcons? icon;
  final Widget? child;

  /// 底部按钮区域, 通常放置单个主按钮或 "次按钮 + 主按钮" 一行.
  ///
  /// 主按钮文案需包含操作结果 (如 "看 12 家");
  /// 破坏性确认需写明动作本身 (如 "退出" "先不退"), 不使用 "确定" "取消".
  final Widget? actions;

  /// 点击关闭按钮的回调, 未传入时默认关闭当前面板.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final safe = MediaQuery.paddingOf(context);
    final titleText = Semantics(
      header: true,
      child: Text(title, style: eat.text.heading.copyWith(color: c.ink)),
    );
    final header = switch (icon) {
      final icon? => Row(
        spacing: EatSpace.s14,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: c.mist, shape: BoxShape.circle),
            child: Center(child: EatIcon(icon, size: 26, color: c.ink)),
          ),
          Expanded(child: titleText),
        ],
      ),
      null => Row(
        children: [
          Expanded(child: titleText),
          Transform.translate(
            offset: const Offset(10, 0),
            child: EatIconButton(
              EatIcons.close,
              label: '关闭',
              color: c.ink,
              onPressed: onClose ?? () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    };
    // 面板自己是白底, 键盘后面那块也是面板的白色, 不用另外铺底色.
    return KeyboardInset(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          EatSpace.s20,
          10,
          EatSpace.s20,
          32 + safe.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            SizedBox(height: icon == null ? 10 : 18),
            header,
            if (subtitle case final subtitle?)
              Text(subtitle, style: eat.text.meta.copyWith(color: c.inkMuted)),
            if (child case final child?) ...[
              const SizedBox(height: EatSpace.s14),
              Flexible(child: SingleChildScrollView(child: child)),
            ],
            if (actions case final actions?) ...[
              SizedBox(height: icon == null ? EatSpace.s14 : 20),
              actions,
            ],
          ],
        ),
      ),
    );
  }
}

/// 面板中的单行操作项, 由 `mist` 圆底图标与文字组成且整行可点击, 用于分享, 选择地图和 "更多" 等列表.
///
/// 各面板的操作列表统一使用该组件以保持行高与图标样式一致, 相邻两项间距为 `space-8`.
class EatPanelAction extends StatelessWidget {
  const new({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final EatIcons icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    return EatListRow(
      leading: Container(
        width: EatSize.touch,
        height: EatSize.touch,
        decoration: BoxDecoration(color: c.mist, shape: BoxShape.circle),
        child: Center(child: EatIcon(icon, size: 20, color: c.ink)),
      ),
      title: Text(label),
      onTap: onTap,
    );
  }
}
