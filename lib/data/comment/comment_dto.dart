import 'package:json_annotation/json_annotation.dart';

part 'comment_dto.g.dart';

/// 评论的作者, 或被回复的人 (`CommentDtos.Author`).
@JsonSerializable(createToJson: false)
class const CommentAuthorDto({
  final int? id,
  final String? displayName,
  final String? avatar,

  /// 等级称号, 目前只有满级有 ("老吃家"), 其余为 null.
  final String? title,
}) {
  factory CommentAuthorDto.fromJson(Map<String, dynamic> json) =>
      _$CommentAuthorDtoFromJson(json);
}

/// 公开的评论或回复 (`CommentDtos.Comment`). 时间是 Unix 毫秒.
@JsonSerializable(createToJson: false)
class const CommentDto({
  final int? id,
  final int? foodId,

  /// 所属根评论 id; 若当前条目本身为根评论则为 null.
  final int? rootId,
  final CommentAuthorDto? author,

  /// 被回复的人. 直接回复根评论时为 null.
  final CommentAuthorDto? replyTo,
  final String? text,

  /// 按 slot 顺序排列的照片地址, 回复不含照片.
  final List<String>? pictureUrls,
  final int? likeCount,

  /// 回复数, 仅对根评论有意义.
  final int? replyCount,

  /// 当前用户是否已点赞, 游客为 null.
  final bool? isLiked,
  final int? createdAt,

  /// 有人选过的表情回应, 没人回应时为空列表.
  final List<CommentReactionDto>? reactions,
}) {
  factory CommentDto.fromJson(Map<String, dynamic> json) =>
      _$CommentDtoFromJson(json);
}

/// 一种表情回应的人数 (`CommentDtos.Reaction`). [selected] 表示当前用户选的是这一种.
@JsonSerializable(createToJson: false)
class const CommentReactionDto({
  final String? reaction,
  final int? count,
  final bool? selected,
}) {
  factory CommentReactionDto.fromJson(Map<String, dynamic> json) =>
      _$CommentReactionDtoFromJson(json);
}

/// 菜品图库中来自评论的照片 (`CommentDtos.Picture`), 仅包含根评论的照片.
@JsonSerializable(createToJson: false)
class const GalleryImageDto({
  final int? commentId,
  final int? slot,
  final String? url,
  final CommentAuthorDto? author,
  final int? createdAt,
}) {
  factory GalleryImageDto.fromJson(Map<String, dynamic> json) =>
      _$GalleryImageDtoFromJson(json);
}
