/// 界面使用的全部图标, 按用途命名.
///
/// 枚举名与 `assets/icons/` 的文件名一一对应, 如 `chevronRight` 对应 `chevron-right.svg`.
/// 图标取自 MingCute Line, 用途名与原名的对照见 `prototype/design-system/assets/Icons/README.md`.
///
/// 新增图标时先在对照表中登记, 再运行 `tool/icons.dart`, 最后在本枚举中添加对应值.
enum EatIcons {
  add,
  addCircle,
  announce,
  back,
  bell,
  block,
  bookmark,
  bookmarkOn(stroked: false),
  bowl,
  calendar(stroked: false),
  camera,
  check,
  checkCircle(stroked: false),
  chevronDown,
  chevronRight,
  close,
  closeCircle,
  comment,
  computer,
  copy,
  delete,
  discover,
  district,
  document,
  download,
  earth,
  edit,
  external,
  eye,
  eyeOff,
  feedback,
  filter,
  follow,
  followed(stroked: false),
  heart,
  heartOn(stroked: false),
  history,
  hot,
  idcard,
  image(stroked: false),
  info,
  key,
  link,
  locate,
  lock,
  logout,
  mail,
  mailSend,
  map,
  me,
  moon(stroked: false),
  more,
  navigate,
  nearby,
  notifyOff,
  pause,
  phone,
  pin,
  question,
  report,
  school,
  search,
  send,
  settings,
  share,
  shield,
  shuffle,
  sort,
  store,
  tag,
  time,
  tool,
  topic,
  unfollow,
  utensils,
  verify,
  warning,
  wifiOff(stroked: false);

  const new({this.stroked = true});

  /// 是否以 2px 描边绘制.
  ///
  /// 只有描边图标生成了 14, 16, 18 三档加粗变体. 实心图标和填充轮廓图标没有变体.
  final bool stroked;

  /// 不含扩展名的文件名.
  String get file => name.replaceAllMapped(
    RegExp('[A-Z]'),
    (match) => '-${match[0]!.toLowerCase()}',
  );

  /// 按显示尺寸选择资源. 描边图标小于 20px 时换用加粗变体, 使实际线宽保持在 1.5–1.6px.
  String assetFor(double size) {
    final variant = switch (size) {
      _ when !stroked || size >= 20 => null,
      < 15 => 14,
      < 17 => 16,
      _ => 18,
    };
    return variant == null
        ? 'assets/icons/$file.svg'
        : 'assets/icons/$variant/$file.svg';
  }
}
