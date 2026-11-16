import 'package:eat/domain/models/dish.dart';

/// 运营为单个校区精选的菜品专题, 包含名称, 介绍与起止时间.
///
/// - 专题时间区间为左闭右开, 在 [endsAt] 前一刻结束.
/// - [dishCount] 为当前仍处于可见状态的菜品数量.
class const Topic({
  required final int id,
  required final String name,
  final String introduction = '',
  required final DateTime startsAt,
  required final DateTime endsAt,
  final int dishCount = 0,
});

/// 专题详情及其包含的菜品列表, 菜品按运营设定的顺序排列.
class const TopicDetail({
  required final Topic topic,
  final List<Dish> dishes = const [],
});
