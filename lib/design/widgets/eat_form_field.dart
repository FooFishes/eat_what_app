import 'package:eat/design/theme/eat_theme.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// 大字输入：上面 13px 的标签，下面没有边框、只有一条下划线的大号输入框，填进去的内容就像标题。
///
/// 下划线平时 `handle`，获得焦点变 `ink`，出错变 `warn`；出错的说明写在下面，说清楚哪里不对、怎么改。
/// 不要只用占位文字代替标签。
class EatFormField extends StatefulWidget {
  const new({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hintText,
    this.errorText,
    this.onChanged,
    this.textInputAction,
    this.autofocus = false,
  }) : price = false;

  /// 价格：数字字体，前面带「¥」，只能输数字和小数点。
  const new price({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hintText,
    this.errorText,
    this.onChanged,
    this.textInputAction,
    this.autofocus = false,
  }) : price = true;

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;

  /// 不为 null 时显示成出错的样子。
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final bool price;

  @override
  State<EatFormField> createState() => _EatFormFieldState();
}

class _EatFormFieldState extends State<EatFormField> {
  FocusNode? _ownFocusNode;
  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(EatFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_onFocusChange);
      _focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final error = widget.errorText;
    final inputStyle = widget.price
        ? eat.text.priceInline.copyWith(fontSize: 22, height: 30 / 22)
        : eat.text.sectionTitle.copyWith(fontSize: 22, height: 30 / 22);
    final lineColor = error != null
        ? c.warn
        : _focusNode.hasFocus
        ? c.ink
        : c.handle;
    return MergeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Text(widget.label, style: eat.text.meta.copyWith(color: c.inkMuted)),
          Container(
            height: 40,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: lineColor, width: 1.5)),
            ),
            child: Row(
              spacing: 2,
              children: [
                if (widget.price)
                  ExcludeSemantics(
                    child: Text('¥', style: inputStyle.copyWith(color: c.ink)),
                  ),
                Expanded(
                  child: Material(
                    type: MaterialType.transparency,
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      autofocus: widget.autofocus,
                      onChanged: widget.onChanged,
                      textInputAction: widget.textInputAction,
                      keyboardType: widget.price
                          ? const TextInputType.numberWithOptions(decimal: true)
                          : null,
                      inputFormatters: widget.price
                          ? [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ]
                          : null,
                      style: inputStyle.copyWith(color: c.ink),
                      cursorColor: c.ink,
                      decoration: InputDecoration.collapsed(
                        hintText: widget.hintText,
                        hintStyle: inputStyle.copyWith(color: c.inkMuted),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (error != null)
            Text(error, style: eat.text.caption.copyWith(color: c.warn)),
        ],
      ),
    );
  }
}
