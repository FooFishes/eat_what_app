/// 后端 `RemoteConfigDtos.ClientConfig` 的响应样例.
Map<String, Object?> clientConfigJson({
  Map<String, Object?>? flags,
  Object? announcements,
  Object? maintenance,
  Object? versions,
}) => {
  'configVersion': 12,
  'flags':
      flags ??
      {
        'publish': {'on': true, 'reason': null},
        'newShop': {'on': true, 'reason': null},
        'comment': {'on': false, 'reason': '评论区在调整，明天恢复'},
        'push': {'on': true, 'reason': null},
        'topic': {'on': true, 'reason': null},
      },
  'params': {'batchSize': 8},
  'announcements':
      announcements ??
      [
        {
          'id': 3,
          'level': 'IMPORTANT',
          'title': '食堂调整',
          'content': '一食堂二楼周末不开',
          'linkUrl': null,
          'startsAt': null,
          'endsAt': null,
        },
        {
          'id': 2,
          'level': 'NORMAL',
          'title': null,
          'content': '西门小吃街周五晚上修路',
          'linkUrl': '/discover',
          'startsAt': 1763251200000,
          'endsAt': null,
        },
      ],
  'maintenance':
      maintenance ??
      {'mode': 'READ_ONLY', 'message': null, 'until': 1763307000000},
  'versions':
      versions ??
      {
        'android': {
          'minBuild': 20,
          'latestBuild': 30,
          'latestVersionName': '1.2.0',
          'storeUrl': 'market://details?id=you.v50to.eat',
          'releaseNotes': '修了几个问题',
        },
      },
  'update': null,
};
