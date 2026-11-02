import 'dart:math';

import 'package:eat/core/storage/secure_store.dart';

/// 安装 ID: 首次读取时随机生成, 保存在 [SecureStore] 中.
///
/// 推荐接口按安装 ID 对游客做当天去重. 退出登录时不删除安装 ID, 否则当天的去重记录失效.
/// 标识只由安全随机数生成, 不读取硬件或系统标识, 因此不受隐私同意的限制.
class DeviceId {
  DeviceId(this._store);

  final SecureStore _store;
  Future<String>? _value;

  static const key = 'installId';

  /// 接口接受的格式: 8–64 位字母, 数字, `_` 和 `-`.
  static final _format = RegExp(r'^[A-Za-z0-9_-]{8,64}$');

  /// 读取设备标识, 没有或格式不符时生成并保存.
  ///
  /// 同一实例只读取一次存储. 存储读写失败时返回新生成的标识, 该标识只在本次运行内有效.
  Future<String> read() => _value ??= _load();

  Future<String> _load() async {
    try {
      final saved = await _store.read(key);
      if (saved != null && _format.hasMatch(saved)) return saved;
    } on Object {
      // 读取失败按没有标识处理.
    }
    final id = generate();
    try {
      await _store.write(key, id);
    } on Object {
      // 写入失败不影响本次使用.
    }
    return id;
  }

  /// 生成 32 位十六进制的随机标识 (128 位熵).
  static String generate([Random? random]) {
    final r = random ?? Random.secure();
    return [
      for (var i = 0; i < 16; i++)
        r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
  }
}
