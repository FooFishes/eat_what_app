import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:material_ui/material_ui.dart';

/// 在屏幕中间弹出对话框并覆盖 `scrim` 遮罩, 点击遮罩或系统返回均可关闭 (返回结果为 null).
///
/// 用于只回答一个问题的场合 (如确认, 放弃编辑, 拦截, 同意); 需要从多项选择或填写内容时应使用 `showPanel`.
///
/// - 不修改路由地址, 不跳转新页面.
/// - 与面板一样放在根导航器上, 避免被主页面的导航栏遮住.
/// - 系统开启减少动态效果时不播放进出动画.
/// - [builder] 通常返回 [EatDialog].
Future<T?> showEatDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final eat = context.eat;
  final duration = context.motion(EatMotion.dialog);
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: '关闭对话框',
    barrierColor: eat.colors.scrim,
    transitionDuration: duration,
    pageBuilder: (context, _, _) => builder(context),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: EatMotion.dialog.curve,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: EatMotion.dialogScale, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// 对话框的内容容器, 包含标题, 可选的说明, 内容区和底部按钮.
///
/// 头部与 `EatPanel` 一样有两种形态:
/// - 普通对话框: 只有标题.
/// - 提示类对话框 (拦截, 同意, 授权说明): 传入 [icon], 标题上方显示 `mist` 圆底图标.
///
/// 不提供关闭按钮, 点击遮罩或系统返回即可关闭. 内容超出时仅中间部分滚动, 标题和按钮保持固定.
class EatDialog extends StatelessWidget {
  const new({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleSpan,
    this.icon,
    this.child,
    this.actions,
  });

  /// 最大宽度, 窄屏上左右各留 `space-20`.
  static const maxWidth = 320.0;

  final String title;

  /// 标题下的一两句说明.
  final String? subtitle;

  /// 带格式的说明 (如加粗的名字), 与 [subtitle] 二选一, 未指定样式的部分同 [subtitle].
  final InlineSpan? subtitleSpan;
  final EatIcons? icon;
  final Widget? child;

  /// 底部按钮区域, 可放一个主按钮或 "次按钮 + 主按钮" 一行, 文案规则同 `EatPanel.actions`.
  ///
  /// 按钮默认高度为 [EatSize.dialogButton].
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    return SafeArea(
      minimum: const EdgeInsets.all(EatSpace.s20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: Semantics(
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: title,
            child: Material(
              color: c.paper,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(EatRadius.sheet),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(EatSpace.s24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (icon case final icon?) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: c.mist,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: EatIcon(icon, size: 24, color: c.ink),
                          ),
                        ),
                      ),
                      const SizedBox(height: EatSpace.s16),
                    ],
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: eat.text.heading.copyWith(color: c.ink),
                      ),
                    ),
                    if (subtitleSpan ??
                            switch (subtitle) {
                              final text? => TextSpan(text: text),
                              null => null,
                            }
                        case final subtitle?) ...[
                      const SizedBox(height: EatSpace.s8),
                      Text.rich(
                        subtitle,
                        style: eat.text.body.copyWith(color: c.inkMuted),
                      ),
                    ],
                    if (child case final child?) ...[
                      const SizedBox(height: EatSpace.s14),
                      Flexible(child: SingleChildScrollView(child: child)),
                    ],
                    if (actions case final actions?) ...[
                      const SizedBox(height: EatSpace.s20),
                      EatButtonHeight(
                        height: EatSize.dialogButton,
                        child: actions,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
