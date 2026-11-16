/// 消息推送栏目, 与消息页分栏对应, 各栏目支持独立开关且默认开启.
enum PushCategory {
  comments('COMMENTS', '评论和回复', '有人评论或回复你时推送'),
  likes('LIKES_AND_FAVORITES', '赞和收藏', '同一道菜 1 小时内的合成一条'),
  follows('FOLLOWS', '关注', '有人关注了你'),
  system('SYSTEM', '系统消息', '反馈和举报的处理结果、公告');

  const new(this.api, this.label, this.description);

  final String api;
  final String label;
  final String description;
}
