import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show StringCharacters;

/// 返回文字的 Unicode code point 数. 接口的字数上限按 code point 计, 因此计数显示也使用本函数.
///
/// `String.length` 计的是 UTF-16 码元 (一个 emoji 计 2), `characters.length` 计的是字形簇 (一个带肤色的 emoji 计 1),
/// 两者都与接口的计法不同.
int codePointLength(String text) => text.runes.length;

/// 按 Unicode code point 限制输入长度的格式化器, 用于替代按字形簇计数的 `LengthLimitingTextInputFormatter`.
///
/// 超出上限时在字形簇边界截断, 保留不超过 [max] 个 code point 的最长前缀, 从而避免留下半个代理对
/// 或拆开的组合字符与 emoji 序列.
///
/// 输入法组字期间是否截断与 `LengthLimitingTextInputFormatter` 的平台默认行为一致:
/// iOS, macOS 和 Web 在组字结束后截断, 避免拼音输入过程中的字母被误截.
class CodePointLengthLimitingFormatter extends TextInputFormatter {
  const new(this.max) : assert(max > 0);

  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (codePointLength(newValue.text) <= max) return newValue;
    final oldFull = codePointLength(oldValue.text) == max;
    switch (LengthLimitingTextInputFormatter.getDefaultMaxLengthEnforcement()) {
      case MaxLengthEnforcement.none:
        return newValue;
      case MaxLengthEnforcement.enforced:
        if (oldFull && oldValue.selection.isCollapsed) return oldValue;
        return _truncate(newValue);
      case MaxLengthEnforcement.truncateAfterCompositionEnds:
        if (oldFull && !oldValue.composing.isValid) return oldValue;
        if (newValue.composing.isValid) return newValue;
        return _truncate(newValue);
    }
  }

  TextEditingValue _truncate(TextEditingValue value) {
    final buffer = StringBuffer();
    var count = 0;
    for (final grapheme in value.text.characters) {
      count += codePointLength(grapheme);
      if (count > max) break;
      buffer.write(grapheme);
    }
    final text = buffer.toString();
    final composing = value.composing;
    return TextEditingValue(
      text: text,
      selection: value.selection.copyWith(
        baseOffset: math.min(value.selection.start, text.length),
        extentOffset: math.min(value.selection.end, text.length),
      ),
      composing: !composing.isCollapsed && text.length > composing.start
          ? TextRange(
              start: composing.start,
              end: math.min(composing.end, text.length),
            )
          : TextRange.empty,
    );
  }
}
