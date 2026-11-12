import 'package:json_annotation/json_annotation.dart';

part 'comment_dto.g.dart';

/// 评论的作者, 或被回复的人 (`CommentDtos.Author`).
@JsonSerializable(createToJson: false)
class const CommentAuthorDto({
  final int? id,
  final String? displayName,
  final String? avatar,
}) {
  factory CommentAuthorDto.fromJson(Map<String, dynamic> json) =>
      _$CommentAuthorDtoFromJson(json);
}

/// 公开的评论或回复 (`CommentDtos.Comment`). 时间是 Unix 毫秒.
@JsonSerializable(createToJson: false)
class const CommentDto({
  final int? id,
  final int? foodId,

  /// 所属的根评论. 根评论为 null.
  final int? rootId,
  final CommentAuthorDto? author,

  /// 被回复的人. 直接回复根评论时为 null.
  final CommentAuthorDto? replyTo,
  final String? text,

  /// 按 slot 排好的照片地址. 回复没有照片.
  final List<String>? pictureUrls,
  final int? likeCount,

  /// 只对根评论有意义.
  final int? replyCount,

  /// 游客为 null.
  final bool? isLiked,
  final int? createdAt,
}) {
  factory CommentDto.fromJson(Map<String, dynamic> json) =>
      _$CommentDtoFromJson(json);
}

/// 菜的图库中来自评论的一张照片 (`CommentDtos.Picture`). 只含根评论的照片.
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
