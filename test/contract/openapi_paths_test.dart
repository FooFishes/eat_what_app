/// 客户端调用的每个「方法 + 路径」都要在 `docs/api.openapi.yml` 里（技术架构 7.6）。
///
/// 后端更新接口文件后先跑这个测试，就知道哪些调用对不上了。新增接口类时把它的 `endpoints` 加进
/// [_clients]。
library;

import 'dart:io';

import 'package:eat/data/auth/auth_api.dart';
import 'package:eat/data/consent/consent_api.dart';
import 'package:eat/data/user/user_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

const _clients = {
  'AuthApi': AuthApi.endpoints,
  'ConsentApi': ConsentApi.endpoints,
  'UserApi': UserApi.endpoints,
};

void main() {
  final spec = loadYaml(File('docs/api.openapi.yml').readAsStringSync()) as Map;
  final paths = spec['paths'] as Map;

  for (final MapEntry(key: client, value: endpoints) in _clients.entries) {
    test('$client 调用的接口都在接口文档里', () {
      for (final endpoint in endpoints) {
        final [method, path] = endpoint.split(' ');
        final operations = paths[path] as Map?;
        expect(operations, isNotNull, reason: '$client：文档里没有 $path');
        expect(
          operations!.containsKey(method.toLowerCase()),
          isTrue,
          reason: '$client：$path 没有 $method',
        );
      }
    });
  }
}
