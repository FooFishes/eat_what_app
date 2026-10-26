import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// 大字输入：上面 13px 的标签，下面没有边框、只有一条下划线的大号输入框，填进去的内容就像标题。
///
/// 下划线平时 `handle`，获得焦点变 `ink`，出错变 `warn`；出错的说明写在下面，说清楚哪里不对、怎么改。
/// 不要只用占位文字代替标签。
///
/// 手机号、验证码这类数字输入设 [numeric]，用数字字体；[prefix] 是输入框前面的固定文字
/// （如「+86」），[trailing] 放在输入框右边（获取验证码按钮、显示密码的眼睛）。
class EatFormField extends StatefulWidget {
  const new({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hintText,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.autofocus = false,
    this.numeric = false,
    this.prefix,
    this.trailing,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.autofillHints,
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
    this.onSubmitted,
    this.textInputAction,
    this.autofocus = false,
  }) : price = true,
       numeric = true,
       prefix = '¥',
       trailing = null,
       keyboardType = const TextInputType.numberWithOptions(decimal: true),
       inputFormatters = null,
       obscureText = false,
       autofillHints = null;

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;

  /// 不为 null 时显示成出错的样子。
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final bool price;
  final bool numeric;
  final String? prefix;
  final Widget? trailing;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final Iterable<String>? autofillHints;

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
    final inputStyle = widget.numeric
        ? eat.text.priceInline.copyWith(fontSize: 22, height: 30 / 22)
        : eat.text.sectionTitle.copyWith(fontSize: 22, height: 30 / 22);
    final lineColor = error != null
        ? c.warn
        : _focusNode.hasFocus
        ? c.ink
        : c.handle;
    final field = Material(
      type: MaterialType.transparency,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        textInputAction: widget.textInputAction,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscureText,
        autofillHints: widget.autofillHints,
        inputFormatters: widget.price
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
            : widget.inputFormatters,
        style: inputStyle.copyWith(color: c.ink),
        cursorColor: c.ink,
        // 上下各留 7px，让输入框连同留白有 44px 高，点得到；文字本身 30px 高。
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 7),
          hintText: widget.hintText,
          hintStyle: inputStyle.copyWith(color: c.inkMuted),
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        ExcludeSemantics(
          child: Text(
            widget.label,
            style: eat.text.meta.copyWith(color: c.inkMuted),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minHeight: EatSize.touch),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: lineColor, width: 1.5)),
          ),
          child: Row(
            children: [
              if (widget.prefix case final prefix?) ...[
                ExcludeSemantics(
                  child: Text(prefix, style: inputStyle.copyWith(color: c.ink)),
                ),
                // 价格的「¥」紧贴数字；「+86」这类区号和号码之间隔一条竖线。
                if (widget.price)
                  const SizedBox(width: 2)
                else ...[
                  const SizedBox(width: EatSpace.s10),
                  Container(width: 1, height: 20, color: c.hairline),
                  const SizedBox(width: EatSpace.s10),
                ],
              ],
              // 标签读给读屏软件时和输入框合成一项；右边的按钮不并进来，单独可点。
              Expanded(
                child: MergeSemantics(
                  child: Semantics(label: widget.label, child: field),
                ),
              ),
              if (widget.trailing case final trailing?) ...[
                const SizedBox(width: EatSpace.s10),
                trailing,
              ],
            ],
          ),
        ),
        if (error != null)
          Text(error, style: eat.text.caption.copyWith(color: c.warn)),
      ],
    );
  }
}
