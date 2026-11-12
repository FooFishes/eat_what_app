/// 一条修改记录的动作.
enum RevisionAction {
  create('create', '新建'),
  edit('edit', '修改'),
  restore('restore', '恢复');

  const new(this.api, this.label);

  final String api;
  final String label;

  /// 不认识的值按 [edit] 处理. 每条记录都对应一次内容变化, 按修改显示不会误导.
  static RevisionAction fromApi(String? value) {
    for (final action in values) {
      if (action.api == value) return action;
    }
    return edit;
  }
}

/// 菜品中可以编辑, 会出现在修改记录里的字段.
enum DishField {
  name('name', '菜名'),
  category('category', '分类'),
  price('price', '价格'),
  description('description', '描述'),
  pictures('pictures', '照片'),
  tags('tags', '口味'),
  signature('signature', '招牌菜');

  const new(this.api, this.label);

  final String api;
  final String label;

  /// 不认识的字段返回 null, 由调用方忽略. 后端新增可编辑字段时客户端可能还不认识.
  static DishField? fromApi(String? value) {
    for (final field in values) {
      if (field.api == value) return field;
    }
    return null;
  }
}

/// 菜品的一条修改记录.
///
/// - [fields] 是本次改动的字段, 按后端顺序, 已去掉不认识的字段.
/// - [restoredFrom] 是 [RevisionAction.restore] 恢复到的记录 id.
/// - 编辑者账号已删除时 [editorId] 和 [editorName] 为 null.
class const DishRevision({
  required final int id,
  required final RevisionAction action,
  final int? editorId,
  final String? editorName,
  final String? editorAvatar,
  final int? restoredFrom,
  final List<DishField> fields = const [],
  final DateTime? createdAt,
});
