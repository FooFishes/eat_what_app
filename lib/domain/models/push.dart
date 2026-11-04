/// 推送的栏目. 和消息页的分栏对应, 每个栏目单独开关, 默认开启.
enum PushCategory {
  comments('COMMENTS', '评论和回复', '有人评论或回复你时推送'),
  likes('LIKES_AND_FAVORITES', '赞和收藏', '同一道菜 1 小时内的合成一条'),
  follows('FOLLOWS', '关注', '有人关注了你'),
  system('SYSTEM', '系统消息', '认证结果、反馈和举报的处理结果');

  const new(this.api, this.label, this.description);

  final String api;
  final String label;
  final String description;

  static PushCategory? fromApi(String? value) {
    for (final category in values) {
      if (category.api == value) return category;
    }
    return null;
  }
}
