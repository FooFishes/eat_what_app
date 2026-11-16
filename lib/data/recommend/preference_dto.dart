import 'package:json_annotation/json_annotation.dart';

part 'preference_dto.g.dart';

/// 推荐偏好 (`RecommendDtos.Preferences`). 从未设置时各列表为空, 其余字段为 null.
///
/// [maxDistance] 单位为米, 只影响堂食; [updatedAt] 为毫秒时间戳.
@JsonSerializable(createToJson: false)
class const PreferencesDto({
  final List<String>? likedCategories,
  final List<String>? likedTags,
  final List<String>? dislikedTags,
  final String? priceBand,
  final int? maxDistance,
  final int? updatedAt,
}) {
  factory PreferencesDto.fromJson(Map<String, dynamic> json) =>
      _$PreferencesDtoFromJson(json);
}

/// 修改推荐偏好的请求体 (`RecommendDtos.PreferencesRequest`).
///
/// 服务端整体覆盖, 省略的字段视为清除, 因此价位和最远距离为 null 时不发送.
/// 忌口只能取 `/recommend/tags` 的 `dislikableTags`, 同一个口味不能既喜欢又忌口.
@JsonSerializable(createFactory: false, includeIfNull: false)
class const PreferencesRequestDto({
  required final List<String> likedCategories,
  required final List<String> likedTags,
  required final List<String> dislikedTags,
  final String? priceBand,
  final int? maxDistance,
}) {
  Map<String, dynamic> toJson() => _$PreferencesRequestDtoToJson(this);
}

/// 推荐偏好的可选值 (`RecommendDtos.Options`), [dislikableTags] 是能设为忌口的口味.
@JsonSerializable(createToJson: false)
class const RecommendOptionsDto({
  final List<String>? categories,
  final List<String>? tags,
  final List<String>? dislikableTags,
}) {
  factory RecommendOptionsDto.fromJson(Map<String, dynamic> json) =>
      _$RecommendOptionsDtoFromJson(json);
}

/// 隐式口味 (`RecommendDtos.Taste`).
///
/// [tags] 和 [categories] 是各口味, 品类的倾向分 (从高到低, 只含有信号的项, 负数表示常给 "不推荐");
/// [inferredTags] 和 [inferredCategories] 是据此推断出的喜欢, 各最多 2 个.
@JsonSerializable(createToJson: false)
class const TasteDto({
  final List<TasteScoreDto>? tags,
  final List<TasteScoreDto>? categories,
  final List<String>? inferredTags,
  final List<String>? inferredCategories,
}) {
  factory TasteDto.fromJson(Map<String, dynamic> json) =>
      _$TasteDtoFromJson(json);
}

/// 某个口味或品类的倾向分 (`RecommendDtos.TasteScore`).
@JsonSerializable(createToJson: false)
class const TasteScoreDto({final String? name, final double? score}) {
  factory TasteScoreDto.fromJson(Map<String, dynamic> json) =>
      _$TasteScoreDtoFromJson(json);
}
