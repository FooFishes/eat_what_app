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
  'category': '主食',
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

/// 消息卡片 (`NotificationDtos.Card`) 的响应样例. [data] 只有系统消息有.
Map<String, Object?> noticeCardJson({
  int id = 1,
  String column = 'LIKES_AND_FAVORITES',
  String kind = 'like',
  String domain = 'foods',
  int targetId = 1,
  int members = 1,
  int unread = 1,
  DateTime? latestAt,
  List<Map<String, Object?>> actors = const [
    {'id': 5, 'displayName': '小林', 'avatar': null},
  ],
  Map<String, Object?>? data,
}) => {
  'id': id,
  'column': column,
  'kind': kind,
  'target': {'domain': domain, 'id': targetId},
  'day': (latestAt ?? DateTime.now()).toIso8601String().substring(0, 10),
  'memberCount': members,
  'unreadMemberCount': unread,
  'latestAt': (latestAt ?? DateTime.now()).millisecondsSinceEpoch,
  'actors': actors,
  'data': data,
};

/// 一位互动者 (`NotificationDtos.Actor`).
Map<String, Object?> actorJson(int id, String name) => {
  'id': id,
  'displayName': name,
  'avatar': null,
};
