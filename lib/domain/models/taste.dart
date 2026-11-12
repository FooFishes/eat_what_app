/// 口味. 菜品、店铺和推荐偏好共用这五个值.
///
/// [api] 是接口中的取值, 与界面文字相同. 后端按位存储, 只在末尾追加新值,
/// 所以 [fromApi] 遇到不认识的值返回 null, 由调用方忽略.
enum Taste {
  spicy('辣'),
  numbing('麻'),
  sweet('甜'),
  sour('酸'),
  light('清淡');

  const new(this.api);

  final String api;

  String get label => api;

  /// 推荐偏好里可以设为忌口的口味. 其余口味硬过滤会误伤大量店铺, 后端只接受这两个.
  static const dislikable = {spicy, numbing};

  static Taste? fromApi(String? value) {
    for (final taste in values) {
      if (taste.api == value) return taste;
    }
    return null;
  }
}
