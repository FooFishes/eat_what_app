import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// 大字输入框. 上方为小号标签, 下方为只有下划线的大号输入框, 输入内容以标题字号显示.
///
/// - 下划线默认为 `handle`, 获得焦点时为 `ink`, 出错时为 `warn`.
/// - 出错说明显示在下方, 写明错误原因和修改方法.
/// - 必须提供标签, 不能只用占位文字代替.
///
/// 参数:
/// - [numeric]: 手机号, 验证码等数字输入, 使用数字字体.
/// - [prefix]: 输入框前的固定文字, 如 "+86".
/// - [trailing]: 输入框右侧的组件, 如获取验证码按钮和显示密码按钮.
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
  }) : price = false,
       multiline = false;

  /// 多行输入, 如反馈内容. 使用正文字号, 至少显示 4 行, 超过 8 行时在框内滚动.
  const new multiline({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hintText,
    this.errorText,
    this.onChanged,
    this.autofocus = false,
    this.trailing,
    this.inputFormatters,
  }) : price = false,
       multiline = true,
       numeric = false,
       prefix = null,
       onSubmitted = null,
       textInputAction = TextInputAction.newline,
       keyboardType = TextInputType.multiline,
       obscureText = false,
       autofillHints = null;

  /// 价格输入. 使用数字字体, 带前缀 "¥", 只接受数字和小数点.
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
       autofillHints = null,
       multiline = false;

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;

  /// 出错说明. 不为 null 时显示出错样式.
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final bool price;
  final bool multiline;
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
    final inputStyle = widget.multiline
        ? eat.text.body.copyWith(fontSize: 16, height: 24 / 16)
        : widget.numeric
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
        minLines: widget.multiline ? 4 : null,
        maxLines: widget.multiline ? 8 : 1,
        inputFormatters: widget.price
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
            : widget.inputFormatters,
        style: inputStyle.copyWith(color: c.ink),
        cursorColor: c.ink,
        // 文字行高低于最小点击高度, 由上下留白补足到 44px.
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
                // 价格的 "¥" 紧贴数字. 区号 (如 "+86") 与号码之间用竖线分隔.
                if (widget.price)
                  const SizedBox(width: 2)
                else ...[
                  const SizedBox(width: EatSpace.s10),
                  Container(width: 1, height: 20, color: c.hairline),
                  const SizedBox(width: EatSpace.s10),
                ],
              ],
              // 标签与输入框合并为一个读屏节点. 右侧按钮不合并, 保持独立可点.
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
