import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'published.g.dart';

/// 这次打开 App 以来发布了几道菜、建了几家店。「我的」的统计和上传、餐厅详情的菜单都监听它，
/// 发布成功后重新拉（技术架构 13.3）。功能之间不互相导入，靠它通知。
@Riverpod(keepAlive: true)
class PublishedCount extends _$PublishedCount {
  @override
  int build() => 0;

  void published() => state++;
}
