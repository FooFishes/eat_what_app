/// 发布菜品和新建店铺时的字段规则.
abstract final class PublishRules {
  static const dishNameMax = 12;
  static const shopNameMax = 20;
  static const addressMax = 30;
  static const noteMax = 200;
  static const photosMax = 6;

  /// 一道菜的口味数量上限.
  static const tagsMax = 3;

  static const priceMax = 999.0;

  /// 去除名称中的所有空白字符.
  static String compactName(String name) => name.replaceAll(RegExp(r'\s'), '');

  /// 生成用于查重的菜名键 (去除所有空白字符并转为小写), 判重逻辑与后端保持一致.
  ///
  /// 同一家店铺内该键值相同即视为重名.
  static String dishNameKey(String name) => compactName(name).toLowerCase();

  /// 解析价格. 合法范围为 0–999 元, 最多一位小数. 不合法或为空时返回 null.
  static double? parsePrice(String text) {
    final value = text.trim();
    if (!RegExp(r'^\d{1,3}(\.\d)?$').hasMatch(value)) return null;
    final price = double.parse(value);
    return price <= priceMax ? price : null;
  }

  /// 价格已填写但不合法时的提示文字. 未填写或合法时返回 null.
  static String? priceError(String text) =>
      text.trim().isEmpty || parsePrice(text) != null
      ? null
      : '请输入 0 到 999 的价格，最多一位小数';

  /// 发布按钮上方的必填项提示, 如 "请填写价格和分类". 必填项都已填写时返回 null.
  static String? missingText({
    required bool photo,
    required bool name,
    required bool price,
    required bool category,
  }) {
    final fields = [if (!name) '菜名', if (!price) '价格', if (!category) '分类'];
    final fill = fields.isEmpty ? null : '填写${_join(fields)}';
    return switch ((photo, fill)) {
      (true, null) => null,
      (false, null) => '请添加照片',
      (true, final fill?) => '请$fill',
      (false, final fill?) => '请添加照片并$fill',
    };
  }

  static String _join(List<String> items) => items.length == 1
      ? items.single
      : '${items.sublist(0, items.length - 1).join('、')}和${items.last}';
}
