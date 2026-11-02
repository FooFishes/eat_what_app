/// 契约测试: 客户端调用的每个 "方法 + 路径" 都必须出现在 `docs/api.openapi.yml` 中.
///
/// `docs/api.openapi.yml` 是后端完整源码契约的副本. 同步新版接口文件后运行此测试, 可列出与新接口不一致的调用.
/// 新增接口类时, 把该类的 `endpoints` 加入 [_clients].
library;

import 'dart:io';

import 'package:eat/data/auth/auth_api.dart';
import 'package:eat/data/comment/comment_api.dart';
import 'package:eat/data/consent/consent_api.dart';
import 'package:eat/data/feedback/feedback_api.dart';
import 'package:eat/data/food/food_api.dart';
import 'package:eat/data/history/history_api.dart';
import 'package:eat/data/notification/notification_api.dart';
import 'package:eat/data/place/place_api.dart';
import 'package:eat/data/push/push_api.dart';
import 'package:eat/data/sessions/sessions_api.dart';
import 'package:eat/data/topic/topic_api.dart';
import 'package:eat/data/upload/upload_api.dart';
import 'package:eat/data/user/user_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

const _clients = {
  'AuthApi': AuthApi.endpoints,
  'CommentApi': CommentApi.endpoints,
  'ConsentApi': ConsentApi.endpoints,
  'FeedbackApi': FeedbackApi.endpoints,
  'FoodApi': FoodApi.endpoints,
  'HistoryApi': HistoryApi.endpoints,
  'NotificationApi': NotificationApi.endpoints,
  'PlaceApi': PlaceApi.endpoints,
  'PushApi': PushApi.endpoints,
  'SessionsApi': SessionsApi.endpoints,
  'TopicApi': TopicApi.endpoints,
  'UploadApi': UploadApi.endpoints,
  'UserApi': UserApi.endpoints,
};

// TODO: 评论接口按配置条件注册, 后端生成完整源码契约时没有收录. 后端补齐契约后删除 [_missingFromSpec].
/// 后端源码中存在, 但完整源码契约缺失的接口.
const _missingFromSpec = {
  'GET /foods/{foodId}/comments',
  'POST /foods/{foodId}/comments',
  'POST /foods/{foodId}/comments/{commentId}/replies',
  'GET /comments/{commentId}/replies',
  'DELETE /comments/{commentId}',
  'PUT /comments/{id}/like',
  'DELETE /comments/{id}/like',
  'GET /comments/{id}/like',
  'GET /comments/submissions/my',
  'GET /foods/{foodId}/gallery',
};

void main() {
  final spec = loadYaml(File('docs/api.openapi.yml').readAsStringSync()) as Map;
  final paths = spec['paths'] as Map;

  for (final MapEntry(key: client, value: endpoints) in _clients.entries) {
    test('$client 调用的接口都在接口文档里', () {
      for (final endpoint in endpoints) {
        if (_missingFromSpec.contains(endpoint)) continue;
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
