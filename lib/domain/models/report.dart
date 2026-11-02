/// 举报对象的类型. [api] 是接口中的取值, [noun] 用于面板标题, 如 "举报这道菜".
enum ReportKind {
  dish('FOOD', '这道菜'),
  comment('COMMENT', '这条评论'),
  user('USER', '这个用户');

  const new(this.api, this.noun);

  final String api;
  final String noun;
}

/// 举报原因. [api] 是接口中的取值.
enum ReportReason {
  notRealPhoto('NOT_REAL_PHOTO', '不是这道菜的实拍'),
  advertising('ADVERTISING', '广告'),
  illegal('ILLEGAL_OR_UNFRIENDLY', '违法或不友善'),
  other('OTHER', '其他');

  const new(this.api, this.label);

  final String api;
  final String label;
}

/// 被举报的一道菜, 一条评论或回复, 或一个用户.
class const ReportTarget({
  required final ReportKind kind,
  required final int id,
}) {
  const ReportTarget.dish(int id) : this(kind: ReportKind.dish, id: id);

  /// 评论和回复共用评论 id.
  const ReportTarget.comment(int id) : this(kind: ReportKind.comment, id: id);

  const ReportTarget.user(int id) : this(kind: ReportKind.user, id: id);

  /// 可选的原因. 服务端拒绝用 "不是这道菜的实拍" 举报用户.
  List<ReportReason> get reasons => switch (kind) {
    ReportKind.dish || ReportKind.comment => ReportReason.values,
    ReportKind.user => [
      for (final r in ReportReason.values)
        if (r != ReportReason.notRealPhoto) r,
    ],
  };
}

/// 店铺 "信息有误" 的错误类型. [api] 是接口中的取值.
enum ShopErrorType {
  wrongName('WRONG_NAME', '店名不对'),
  wrongLocation('WRONG_LOCATION', '位置不对'),
  closed('CLOSED', '已关门'),
  duplicate('DUPLICATE', '和别的店重复'),
  other('OTHER', '其他');

  const new(this.api, this.label);

  final String api;
  final String label;
}
