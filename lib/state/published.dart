import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'published.g.dart';

/// 本次启动以来的发布次数, 包括发布菜品和新建店铺.
///
/// "我的" 的统计与上传列表, 以及餐厅详情的菜单监听该值, 变化后重新请求.
/// 功能之间不能互相导入, 因此通过该 Provider 通知.
@Riverpod(keepAlive: true)
class PublishedCount extends _$PublishedCount {
  @override
  int build() => 0;

  void published() => state++;
}
