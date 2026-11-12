import 'package:json_annotation/json_annotation.dart';

part 'recommend_dto.g.dart';

/// 推荐列表 (`RecommendDtos.Feed`): 分页字段与其他列表相同, 另带本次实际使用的饭点 [mealTime].
///
/// 卡片 (`RecommendDtos.Card`) 是店铺的子集加上招牌菜和距离, 保留原始 JSON:
/// 仓库用店铺的转换 `PlaceRepository.shopFromJson` 解析, 并把原文缓存为 "上一批".
///
/// 登录用户的 [currentPage] 只是回显请求的页码, [totalItems] 是当天还没推荐过的候选数.
@JsonSerializable(createToJson: false)
class const RecommendFeedDto({
  final String? mealTime,
  final int? currentPage,
  final List<Map<String, dynamic>>? items,
  final bool? hasNext,
  final int? totalItems,
}) {
  factory RecommendFeedDto.fromJson(Map<String, dynamic> json) =>
      _$RecommendFeedDtoFromJson(json);
}
