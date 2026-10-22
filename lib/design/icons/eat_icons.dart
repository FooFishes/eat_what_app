/// 界面里用到的全部图标，按用途命名，和 `assets/icons/` 的文件名一一对应
/// （`chevronRight` 对应 `chevron-right.svg`）。
///
/// 取自 MingCute Line，用途和原名的对照在 `prototype/design-system/assets/Icons/README.md`。
/// 缺图标时先在那里补上，再跑 `tool/icons.dart` 并在这里加一项。
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

  /// 用 2px 描边画的图标有 14、16、18 的加粗变体；用填充画的（实心或填充轮廓）没有。
  final bool stroked;

  /// 文件名，不带扩展名。
  String get file => name.replaceAllMapped(
    RegExp('[A-Z]'),
    (match) => '-${match[0]!.toLowerCase()}',
  );

  /// 按显示尺寸选资源：20px 以下换成描边加粗的变体，让实际线宽保持在 1.5–1.6px。
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
