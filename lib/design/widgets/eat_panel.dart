import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_layout.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:eat/design/widgets/eat_sheet.dart';
import 'package:material_ui/material_ui.dart';

/// 从底部弹出一个面板，背后盖一层 `scrim`，点遮罩或下拉都会关掉。不改地址，不跳新页面。
///
/// 面板高度跟着内容走，最高到屏幕的 85%；出现和收起 240ms，减少动态效果时直接显示。
/// [builder] 一般返回 [EatPanel]。面板里不再开面板。
Future<T?> showPanel<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final eat = context.eat;
  return showModalBottomSheet<T>(
    context: context,
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

/// 底部面板的内容：把手、标题、可选的一行说明、内容和底部按钮。
///
/// 两种头部：普通面板是标题加右边的关闭按钮；提示类面板（拦截、功能暂时关了、操作受限）传 [icon]，
/// 左边一个 52px 的 `mist` 圆底图标、右边一句说清现在怎样的标题，不放关闭按钮，靠底部按钮给下一步。
/// 内容超出时只有中间这段滚动，标题和按钮不动。
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

  /// 一个主按钮，或「次按钮 + 主按钮」的一行。主按钮的文字带上结果，如「看 12 家」；
  /// 破坏性的确认写动作本身（「退出」「先不退」），不写「确定」「取消」。
  final Widget? actions;

  /// 不传时关闭按钮收起面板。
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final media = MediaQuery.of(context);
    final titleText = Semantics(
      header: true,
      child: Text(title, style: eat.text.sectionTitle.copyWith(color: c.ink)),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        EatSpace.s20,
        10,
        EatSpace.s20,
        32 + media.padding.bottom + media.viewInsets.bottom,
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
    );
  }
}

/// 提示类面板里「原因」「恢复」这样左右对齐的几行。
class PanelFacts extends StatelessWidget {
  const new(this.facts, {super.key});

  /// 每行的标签、内容，以及内容要不要加粗（恢复时间一般加粗）。
  final List<({String label, String value, bool strong})> facts;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final style = eat.text.body.copyWith(
      height: 22 / 15,
      color: eat.colors.ink,
    );
    return Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      children: [
        for (final (i, fact) in facts.indexed)
          TableRow(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  right: EatSpace.s14,
                  top: i > 0 ? 8 : 0,
                ),
                child: Text(
                  fact.label,
                  style: style.copyWith(color: eat.colors.inkMuted),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: i > 0 ? 8 : 0),
                child: Text(
                  fact.value,
                  style: fact.strong
                      ? style.copyWith(fontWeight: FontWeight.w600)
                      : style,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
