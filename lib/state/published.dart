import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'published.g.dart';

/// 记录本次应用启动以来的内容发布次数, 包括发布菜品, 编辑或恢复菜品以及新建店铺.
///
/// 由于功能模块之间禁止互相导入, "我的" 页面统计与上传列表, 餐厅详情的菜单及菜品详情均通过监听该计数变化来重新请求.
@Riverpod(keepAlive: true)
class PublishedCount extends _$PublishedCount {
  @override
  int build() => 0;

  void published() => state++;
}
