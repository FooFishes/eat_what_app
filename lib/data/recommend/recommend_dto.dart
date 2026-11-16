import 'package:json_annotation/json_annotation.dart';

part 'recommend_dto.g.dart';

/// 推荐列表响应 (`RecommendDtos.Feed`), 分页结构与常规列表一致, 并额外返回本次实际生效的饭点 [mealTime].
///
/// 推荐卡片 (`RecommendDtos.Card`) 为店铺字段子集并附加招牌菜与距离; 此处保留原始 JSON, 以便仓库复用 `PlaceRepository.shopFromJson` 解析并将原文缓存为 "上一批".
///
/// 对登录用户而言, [currentPage] 仅回显请求页码, [totalItems] 表示当日尚未推荐过的候选店铺数.
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
