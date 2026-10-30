import 'package:eat/features/auth/widgets/auth_form.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

String _format(String pasted, {String before = ''}) =>
    const MobileInputFormatter()
        .formatEditUpdate(
          TextEditingValue(text: before),
          TextEditingValue(
            text: pasted,
            selection: TextSelection.collapsed(offset: pasted.length),
          ),
        )
        .text;

void main() {
  test('粘贴带区号、空格、横线的号码，只留 11 位号码', () {
    expect(_format('+86 138 1234 5678'), '13812345678');
    expect(_format('0086-138-1234-5678'), '13812345678');
    expect(_format('138 1234 5678'), '13812345678');
  });

  test('一位一位输入照常，超过 11 位截掉', () {
    expect(_format('1381'), '1381');
    expect(_format('138123456789', before: '13812345678'), '13812345678');
  });
}
