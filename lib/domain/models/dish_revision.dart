/// 一条修改记录的动作.
enum RevisionAction {
  create('create', '新建'),
  edit('edit', '修改'),
  restore('restore', '恢复');

  const new(this.api, this.label);

  final String api;
  final String label;

  /// 未知值按 [edit] 处理. 因每条记录均对应一次内容变更, 展示为修改不会产生误导.
  static RevisionAction fromApi(String? value) {
    for (final action in values) {
      if (action.api == value) return action;
    }
    return edit;
  }
}

/// 菜品中支持编辑且会记录在修改历史中的字段.
enum DishField {
  name('name', '菜名'),
  category('category', '分类'),
  price('price', '价格'),
  description('description', '描述'),
  pictures('pictures', '照片'),
  tags('tags', '口味'),
  signature('signature', '招牌菜'),
  mealTimes('mealTimes', '饭点'),
  deliveryEnabled('deliveryEnabled', '外卖');

  const new(this.api, this.label);

  final String api;
  final String label;

  /// 未知字段返回 null 并由调用方忽略, 以兼容后端后续新增的可编辑字段.
  static DishField? fromApi(String? value) {
    for (final field in values) {
      if (field.api == value) return field;
    }
    return null;
  }
}

/// 菜品的一条修改记录.
///
/// - [fields] 为本次变动的字段列表, 保持后端返回顺序并已过滤未知字段.
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
