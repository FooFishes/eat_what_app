/// 界面使用的全部图标, 按用途命名.
///
/// 图标全部取自 MingCute 官方的 `@mingcute/svg` (版本见 `tool/icons.dart`), 本枚举同时是用途名与官方名的对照表.
/// 枚举名与 `assets/icons/` 的文件名一一对应, 如 `chevronRight` 对应 `chevron-right.svg`.
///
/// 默认使用空心 (Regular), 仅切换状态使用实心 (Filled), 包括赞过, 收藏过及底部导航选中的标签.
///
/// 新增图标时在本枚举中添加一项并写明官方名, 再运行 `tool/icons.dart` 生成资源.
enum EatIcons {
  add('add'),
  addCircle('add-circle'),
  announce('announcement'),
  back('left'),
  bell('notification'),
  block('forbid-circle'),
  bookmark('bookmark'),
  bookmarkOn('bookmark', filled: true),
  bowl('bowl'),
  calendar('calendar'),
  camera('camera'),
  check('check'),
  checkCircle('check-circle'),
  chevronDown('down'),
  chevronRight('right'),
  close('close'),
  closeCircle('close-circle'),
  comment('chat-1'),
  computer('computer'),
  copy('copy-2'),
  delete('delete-2'),
  discover('compass'),
  discoverOn('compass', filled: true),
  dismiss('sad'),
  district('building-2'),
  document('file'),
  download('download-2'),
  earth('earth'),
  edit('edit'),
  external('external-link'),
  eye('eye'),
  eyeOff('eye-close'),
  feedback('message-4'),
  filter('settings-6'),
  follow('user-add'),
  followed('user-follow'),
  heart('heart'),
  heartOn('heart', filled: true),
  history('history'),
  hot('fire'),
  idcard('idcard'),
  image('pic'),
  info('information'),
  key('key-2'),
  link('link'),
  locate('aiming-2'),
  lock('lock'),
  logout('exit'),
  mail('mail'),
  mailSend('mail-send'),
  map('map'),
  me('user-3'),
  meOn('user-3', filled: true),
  moon('moon'),
  more('more-1'),
  navigate('navigation'),
  nearby('location'),
  nearbyOn('location', filled: true),
  notifyOff('notification-off'),
  pause('pause-circle'),
  phone('cellphone'),
  pin('map-pin'),
  price('wallet'),
  question('question'),
  report('flag-1'),
  school('school'),
  search('search'),
  send('send-plane'),
  settings('settings-3'),
  share('share-forward'),
  shield('shield'),
  shuffle('refresh-2'),
  sort('sort-descending'),
  store('store-2'),
  tag('tag'),
  time('time'),
  tool('tool'),
  topic('bookmarks'),
  unfollow('user-remove'),
  utensils('fork-spoon'),
  verify('safety-certificate'),
  warning('warning'),
  wifiOff('wifi-off');

  const new(this.mingcute, {this.filled = false});

  /// 官方名, 如 `compass`. 对应 `@mingcute/svg` 中的 `core-regular/compass.svg`, 实心对应 `core-filled/compass.svg`.
  final String mingcute;

  /// 是否使用实心图标.
  final bool filled;

  /// 不含扩展名的文件名.
  String get file => name.replaceAllMapped(
    RegExp('[A-Z]'),
    (match) => '-${match[0]!.toLowerCase()}',
  );

  String get asset => 'assets/icons/$file.svg';
}
