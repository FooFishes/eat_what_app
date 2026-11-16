/// 评论接口的响应样例.
library;

/// 2026-11-01 12:00 (UTC+8). 测试中的评论时间由该时刻减去 ageMinutes 得出.
final commentEpoch = DateTime.utc(2026, 11, 1, 4);

/// 比 [commentEpoch] 早 [minutes] 分钟的接口时间, 格式同服务端 (Unix 毫秒).
int commentTime([int minutes = 0]) =>
    commentEpoch.subtract(Duration(minutes: minutes)).millisecondsSinceEpoch;

/// 评论的作者或被回复的人 (`CommentDtos.Author`). 作者 id 由昵称确定, 同一昵称 id 相同.
Map<String, Object?> authorJson(
  String name, {
  int? id,
  String? avatar,
  String? title,
}) => {
  'id': id ?? authorIdOf(name),
  'displayName': name,
  'avatar': avatar,
  'title': title,
};

/// [authorJson] 为昵称 [name] 分配的用户 id.
int authorIdOf(String name) => 500 + name.runes.fold(0, (a, b) => a + b) % 400;

/// 一条公开评论或回复 (`CommentDtos.Comment`). [root] 不为 null 时是回复.
Map<String, Object?> commentJson({
  int id = 11,
  int foodId = 1,
  int? root,
  String? replyTo,
  String author = '安安',
  int? authorId,
  String text = '酸笋给得很大方',
  int likes = 3,
  bool? liked = false,
  int replies = 0,
  int ageMinutes = 60,
  List<String> images = const [],
}) => {
  'id': id,
  'foodId': foodId,
  'rootId': root,
  'author': authorJson(author, id: authorId),
  'replyTo': replyTo == null ? null : authorJson(replyTo),
  'text': text,
  'pictureUrls': images,
  'likeCount': likes,
  'replyCount': replies,
  'isLiked': liked,
  'createdAt': commentTime(ageMinutes),
};

/// 一条回复. [root] 是所属评论的 id, [replyTo] 是被回复的人.
Map<String, Object?> replyJson({
  required int id,
  int root = 11,
  String? replyTo,
  String author = '阿哲',
  int? authorId,
  String text = '同意，加辣更好',
  int likes = 0,
  bool? liked = false,
  int ageMinutes = 30,
}) => commentJson(
  id: id,
  root: root,
  replyTo: replyTo,
  author: author,
  authorId: authorId,
  text: text,
  likes: likes,
  liked: liked,
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

/// 发表评论或回复的结果 (`CommentDtos.Created`).
Map<String, Object?> createdJson({int id = 99}) => {'id': id};
