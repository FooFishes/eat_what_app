import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:flutter/widgets.dart';

/// 提示类对话框和面板中用于展示左右对齐信息的列表组件, 如 "原因" "恢复".
class FactList extends StatelessWidget {
  const new(this.facts, {super.key});

  /// 信息行数据, 包含每行的标签, 内容以及内容是否加粗 (例如恢复时间通常需要加粗).
  final List<({String label, String value, bool strong})> facts;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final style = eat.text.body.copyWith(color: eat.colors.ink);
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
