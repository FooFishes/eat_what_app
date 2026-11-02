import 'package:eat/domain/models/dish.dart';

/// 专题: 运营为一个校区挑选的一组菜, 有名字, 介绍和起止时间.
///
/// - [endsAt] 不属于专题的时间段. 专题在 [endsAt] 前一刻结束.
/// - [dishCount] 是当前仍可见的菜数.
class const Topic({
  required final int id,
  required final String name,
  final String introduction = '',
  required final DateTime startsAt,
  required final DateTime endsAt,
  final int dishCount = 0,
});

/// 专题和其中的菜, 菜按运营排定的顺序排列.
class const TopicDetail({
  required final Topic topic,
  final List<Dish> dishes = const [],
});
