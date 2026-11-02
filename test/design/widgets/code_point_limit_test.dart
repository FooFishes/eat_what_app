import 'package:eat/design/widgets/code_point_limit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:flutter_test/flutter_test.dart';

TextEditingValue _value(String text, {TextRange composing = TextRange.empty}) =>
    TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: composing,
    );

String _format(int max, String oldText, String newText) =>
    CodePointLengthLimitingFormatter(max)
        .formatEditUpdate(_value(oldText), _value(newText))
        .text;

void main() {
  test('codePointLength 按 code point 计数', () {
    expect(codePointLength('云吞'), 2);
    expect(codePointLength('🍜'), 1, reason: 'UTF-16 长度为 2');
    expect(codePointLength('👍🏽'), 2, reason: '一个字形簇, 两个 code point');
    expect(codePointLength('👨‍👩‍👧'), 5, reason: '三个人和两个连接符');
    expect(codePointLength('e\u0301'), 2, reason: '字母加组合重音');
    expect(codePointLength(''), 0);
  });

  test('不超过上限时原样返回', () {
    expect(_format(3, '', '云吞🍜'), '云吞🍜');
  });

  test('emoji 按一个 code point 计，超出时整个去掉，不留半个代理对', () {
    expect(_format(3, '', 'ab😀c'), 'ab😀');
    expect(_format(1, '', 'a😀'), 'a');
  });

  test('组合字符和 emoji 序列不拆开', () {
    expect(_format(2, '', 'ae\u0301'), 'a');
    expect(_format(6, '', 'a👨‍👩‍👧'), 'a👨‍👩‍👧');
    expect(_format(5, '', 'a👨‍👩‍👧'), 'a');
    expect(_format(2, '', '👍🏽x'), '👍🏽');
  });

  test('字形簇计数未超但 code point 超出时截断', () {
    const name = '鲜虾蟹籽云吞好吃不贵👨‍👩‍👧';
    expect(name.characters.length, 11);
    expect(_format(12, '', name), '鲜虾蟹籽云吞好吃不贵');
  });

  test('已到上限再输入时保留原值', () {
    expect(_format(2, 'ab', 'abc'), 'ab');
  });

  test('iOS 上组字期间不截断，组字结束后截断', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    const formatter = CodePointLengthLimitingFormatter(2);

    final composing = formatter.formatEditUpdate(
      _value('云'),
      _value('云tun', composing: const TextRange(start: 1, end: 4)),
    );
    expect(composing.text, '云tun');

    final committed = formatter.formatEditUpdate(composing, _value('云吞好'));
    expect(committed.text, '云吞');
  });
}
