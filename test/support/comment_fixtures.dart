/// 评论接口的响应样例.
library;

/// 2026-11-01 12:00 (UTC+8) 的 Unix 毫秒. 测试中的评论时间由该时刻减去 ageMinutes 得出.
const commentEpoch = 1793505600000;

/// 一条公开评论或回复 (`CommentPublicReads.Comment`).
Map<String, Object?> commentJson({
  int id = 11,
  String? gid,
  String kind = 'COMMENT',
  int foodId = 1,
  String? root,
  String? replyTo,
  String author = '安安',
  String text = '酸笋给得很大方',
  int likes = 3,
  int ageMinutes = 60,
  List<String> images = const [],
}) {
  final self = gid ?? 'g-$id';
  return {
    'id': id,
    'gid': self,
    'revisionId': 'r-$id',
    'kind': kind,
    'foodId': foodId,
    'rootCommentGid': root ?? self,
    'replyToGid': replyTo,
    'authorName': author,
    'text': text,
    'likesCount': likes,
    'createdAt': commentEpoch - ageMinutes * 60000,
    'images': [
      for (final (i, url) in images.indexed)
        {'slot': i, 'url': url, 'expiresInSeconds': 30},
    ],
  };
}

/// 一条回复. [root] 是所属评论的 gid.
Map<String, Object?> replyJson({
  required int id,
  String root = 'g-11',
  String? replyTo,
  String author = '阿哲',
  String text = '同意，加辣更好',
  int likes = 0,
  int ageMinutes = 30,
}) => commentJson(
  id: id,
  kind: 'REPLY',
  root: root,
  replyTo: replyTo,
  author: author,
  text: text,
  likes: likes,
  ageMinutes: ageMinutes,
);

/// `PageResult` 外壳. [total] 缺省时为 [items] 的条数.
Map<String, Object?> commentPageJson(
  List<Object?> items, {
  int page = 1,
  int? total,
  bool hasNext = false,
}) => {
  'items': items,
  'currentPage': page,
  'pageSize': 20,
  'totalItems': total ?? items.length,
  'totalPages': 1,
  'hasNext': hasNext,
};

/// 发表评论或回复的结果.
Map<String, Object?> acceptedJson({int id = 99, String status = 'PENDING'}) => {
  'id': id,
  'commentGid': 'g-$id',
  'revisionId': 'r-$id',
  'moderationStatus': status,
};

/// 我写过的一条评论 (`CommentQueries.Submission`).
Map<String, Object?> submissionJson({
  int id = 11,
  int foodId = 1,
  String kind = 'COMMENT',
  String status = 'APPROVED',
  String? reason,
  String? text = '汤很鲜，虾仁很多',
  int imageCount = 0,
}) => {
  'id': id,
  'gid': 'g-$id',
  'revisionId': 'r-$id',
  'kind': kind,
  'foodId': foodId,
  'moderationStatus': status,
  'reasonCode': reason == null ? null : 'NOT_REAL_PHOTO',
  'reasonMessage': reason,
  'text': text,
  'imageCount': imageCount,
  'createdAt': commentEpoch - 3600000,
};
