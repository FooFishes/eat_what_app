import 'dart:convert';
import 'dart:math';

import 'package:eat/core/network/recovery_capability.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('恢复凭据是 32 字节随机值的 Base64URL, 不带填充, 共 43 个字符', () {
    final value = newRecoveryCapability(Random(1));
    expect(value, hasLength(43));
    expect(value, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
    expect(base64Url.decode('$value='), hasLength(32));
    expect(newRecoveryCapability(), isNot(newRecoveryCapability()));
  });
}
