/// 契约测试: 客户端调用的每个 "方法 + 路径" 都必须出现在 `docs/api.openapi.yml` 中.
///
/// 同步新版接口文件后运行此测试, 可列出与新接口不一致的调用.
/// 新增接口类时, 把该类的 `endpoints` 加入 [_clients].
library;

import 'dart:io';

import 'package:eat/data/auth/auth_api.dart';
import 'package:eat/data/consent/consent_api.dart';
import 'package:eat/data/food/food_api.dart';
import 'package:eat/data/notification/notification_api.dart';
import 'package:eat/data/place/place_api.dart';
import 'package:eat/data/upload/upload_api.dart';
import 'package:eat/data/user/user_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

const _clients = {
  'AuthApi': AuthApi.endpoints,
  'ConsentApi': ConsentApi.endpoints,
  'FoodApi': FoodApi.endpoints,
  'NotificationApi': NotificationApi.endpoints,
  'PlaceApi': PlaceApi.endpoints,
  'UploadApi': UploadApi.endpoints,
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
