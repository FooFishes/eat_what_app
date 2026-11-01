/// 发布一道菜、新建一家店时的字段规则（产品 9.1、9.2、6.9）。
abstract final class PublishRules {
  static const dishNameMax = 12;
  static const shopNameMax = 20;
  static const addressMax = 30;
  static const noteMax = 300;
  static const photosMax = 9;
  static const myTagMax = 10;

  /// 口味标签和我的标签一次各最多 20 个。
  static const tagsMax = 20;

  static const priceMax = 999.0;

  /// 查重用的名字：去掉所有空白。同一家店里这样比相同就算重名。
  static String compactName(String name) => name.replaceAll(RegExp(r'\s'), '');

  /// 价格：0–999 元，最多一位小数。不合规返回 null，空串也是 null。
  static double? parsePrice(String text) {
    final value = text.trim();
    if (!RegExp(r'^\d{1,3}(\.\d)?$').hasMatch(value)) return null;
    final price = double.parse(value);
    return price <= priceMax ? price : null;
  }

  /// 填了但不合规时的说明；没填或合规返回 null。
  static String? priceError(String text) =>
      text.trim().isEmpty || parsePrice(text) != null
      ? null
      : '价格填 0 到 999，最多一位小数';

  /// 发布按钮上方写缺哪些必填项，如「请填写价格和分类」（产品 6.9）。都齐了返回 null。
  static String? missingText({
    required bool photo,
    required bool name,
    required bool price,
    required bool category,
    required bool meal,
  }) {
    final fields = [
      if (!name) '菜名',
      if (!price) '价格',
      if (!category) '分类',
      if (!meal) '适合哪顿',
    ];
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
