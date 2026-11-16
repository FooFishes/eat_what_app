/// 口味标签, 菜品, 店铺与推荐偏好共用这五个枚举值.
///
/// [api] 为接口字段值且与界面文字相同. 因后端按位存储且仅在末尾追加新值,
/// [fromApi] 遇到未知值时返回 null 并由调用方忽略.
enum Taste {
  spicy('辣'),
  numbing('麻'),
  sweet('甜'),
  sour('酸'),
  light('清淡');

  const new(this.api);

  final String api;

  String get label => api;

  /// 推荐偏好中允许设为忌口的口味集合. 对其余口味进行硬过滤会误伤大量店铺, 因此后端仅接受这两个值.
  static const dislikable = {spicy, numbing};

  static Taste? fromApi(String? value) {
    for (final taste in values) {
      if (taste.api == value) return taste;
    }
    return null;
  }
}
