/// 编辑资料与我的标签的输入校验规则. 校验失败时返回展示在输入框下方的提示文本, 合法时返回 null.
abstract final class ProfileRules {
  static const nicknameMin = 2;
  static const nicknameMax = 12;
  static const signatureMax = 100;
  static const myTagMax = 10;

  /// 按字数计算长度, 一个汉字算一个字.
  static int lengthOf(String value) => value.trim().runes.length;

  static String? nicknameError(String value) {
    final length = lengthOf(value);
    if (length == 0) return '请输入昵称';
    if (length < nicknameMin) return '昵称至少 $nicknameMin 个字';
    if (length > nicknameMax) return '昵称最多 $nicknameMax 个字';
    return null;
  }

  static String? signatureError(String value) =>
      lengthOf(value) > signatureMax ? '签名最多 $signatureMax 个字' : null;

  /// 校验标签名格式与唯一性, [existing] 为已存在的其他标签名列表.
  static String? myTagError(String value, Iterable<String> existing) {
    final name = value.trim();
    if (name.isEmpty) return '请输入标签名';
    if (lengthOf(name) > myTagMax) return '标签名最多 $myTagMax 个字';
    if (existing.contains(name)) return '已有同名标签';
    return null;
  }
}
