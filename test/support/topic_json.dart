/// 专题和消息卡片接口的响应样例.
library;

/// 专题摘要 (`TopicModels.Summary`) 的响应样例. 时间是带时区的 ISO 8601.
Map<String, Object?> topicJson({
  int id = 7,
  String name = '期末续命餐',
  String introduction = '复习到半夜，来点热的。',
  DateTime? startsAt,
  DateTime? endsAt,
  int count = 2,
}) {
  final start = startsAt ?? DateTime.now().subtract(const Duration(days: 1));
  final end = endsAt ?? DateTime.now().add(const Duration(days: 6));
  return {
    'id': id,
    'gid': '0b8c6f3e-1111-4c5b-9d6e-000000000007',
    'revision': 3,
    'campusId': 1,
    'name': name,
    'introduction': introduction,
    'startsAt': start.toUtc().toIso8601String(),
    'endsAt': end.toUtc().toIso8601String(),
    'coverFoodId': 1,
    'visibleFoodCount': count,
  };
}

/// 专题里的一道菜 (`TopicModels.Food`) 的响应样例.
Map<String, Object?> topicFoodJson({
  int id = 1,
  String name = '柳州螺蛳粉',
  String shop = '螺蛳粉研究所',
  int position = 0,
}) => {
  'id': id,
  'gid': '0b8c6f3e-2222-4c5b-9d6e-00000000000$id',
  'name': name,
  'description': '酸笋很足',
  'restaurantId': 10 + id,
  'restaurantName': shop,
  'uploaderName': '小林',
  'price': 16.5,
  'category': 'staple',
  'categoryLabel': '主食',
  'pictureUrl': ['https://img.test/foods/$id.jpg'],
  'likesCount': 8,
  'mealTimes': ['lunch'],
  'stageColor': 'chili',
  'stageAlternates': ['broth'],
  'coverCenterX': 0.4,
  'coverCenterY': 0.6,
  'coverDiameter': 0.8,
  'position': position,
};

/// 专题详情 (`TopicModels.Detail`) 的响应样例.
Map<String, Object?> topicDetailJson({
  Map<String, Object?>? topic,
  List<Map<String, Object?>>? foods,
}) => {
  'topic': topic ?? topicJson(),
  'foods':
      foods ??
      [
        topicFoodJson(),
        topicFoodJson(id: 2, name: '铁锅炖大鹅', shop: '东北饭庄', position: 1),
      ],
};

/// 消息卡片 (`NotificationCardModels.Card`) 的响应样例.
Map<String, Object?> noticeCardJson({
  String id = '6f1c1c9e-0000-4000-8000-000000000001',
  String column = 'LIKES_AND_FAVORITES',
  String kind = 'like',
  String domain = 'foods',
  int targetId = 1,
  bool unavailable = false,
  int members = 1,
  int unread = 1,
  DateTime? latestAt,
  List<Map<String, Object?>> actors = const [
    {
      'id': 5,
      'gid': '6f1c1c9e-0000-4000-8000-000000000005',
      'name': '小林',
      'avatar': null,
    },
  ],
  Map<String, Object?>? detail,
}) {
  final target = {
    'domain': domain,
    'gid': '6f1c1c9e-0000-4000-8000-0000000000aa',
    'id': targetId,
    'unavailable': unavailable,
  };
  final day = (latestAt ?? DateTime.now()).toIso8601String().substring(0, 10);
  return {
    'id': id,
    'column': column,
    'kind': kind,
    'target': target,
    'day': day,
    'memberCount': members,
    'unreadMemberCount': unread,
    'latestAt': (latestAt ?? DateTime.now()).millisecondsSinceEpoch,
    'actors': actors,
    'data': {
      'schema': 1,
      'kind': kind,
      'target': target,
      'day': day,
      'memberCount': members,
      'detail': detail,
    },
  };
}

/// 一位互动者.
Map<String, Object?> actorJson(int id, String name) => {
  'id': id,
  'gid': '6f1c1c9e-0000-4000-8000-0000000000${id.toString().padLeft(2, '0')}',
  'name': name,
  'avatar': null,
};
