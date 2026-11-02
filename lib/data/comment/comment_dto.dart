import 'package:json_annotation/json_annotation.dart';

part 'comment_dto.g.dart';

// TODO: 公开评论缺少作者 id, 头像, 当前用户是否赞过和回复条数. 后端提供这些字段后改为读取字段, 删除逐条查询赞和用 "我的评论" 判断作者的逻辑.
/// 公开的评论或回复 (`CommentPublicReads.Comment`).
///
/// 时间是 Unix 毫秒. `gid` 一类的全局 id 是 UUID 字符串, 界面和路径用数字 [id].
@JsonSerializable(createToJson: false)
class const CommentDto({
  final int? id,
  final String? gid,
  final String? revisionId,

  /// `COMMENT` 或 `REPLY`.
  final String? kind,
  final int? foodId,
  final String? rootCommentGid,

  /// 被回复的那条回复. 直接回复评论时为 null.
  final String? replyToGid,

  /// 作者没有公开昵称时, 服务端返回 "匿名用户".
  final String? authorName,
  final String? text,
  final int? likesCount,
  final int? createdAt,
  final List<CommentImageDto>? images,
}) {
  factory CommentDto.fromJson(Map<String, dynamic> json) =>
      _$CommentDtoFromJson(json);
}

/// 评论的一张照片. [url] 是有效期 [expiresInSeconds] 秒的签名地址.
@JsonSerializable(createToJson: false)
class const CommentImageDto({
  final int? slot,
  final String? url,
  final int? expiresInSeconds,
}) {
  factory CommentImageDto.fromJson(Map<String, dynamic> json) =>
      _$CommentImageDtoFromJson(json);
}

/// 菜的图库中来自评论的一张照片.
@JsonSerializable(createToJson: false)
class const GalleryImageDto({
  final int? commentId,
  final String? commentGid,
  final int? createdAt,
  final CommentImageDto? image,
}) {
  factory GalleryImageDto.fromJson(Map<String, dynamic> json) =>
      _$GalleryImageDtoFromJson(json);
}

/// 发表评论或回复的结果. [moderationStatus] 为 `PENDING` 时进入审核, 尚未公开.
@JsonSerializable(createToJson: false)
class const CommentAcceptedDto({
  final int? id,
  final String? commentGid,
  final String? revisionId,
  final String? moderationStatus,
}) {
  factory CommentAcceptedDto.fromJson(Map<String, dynamic> json) =>
      _$CommentAcceptedDtoFromJson(json);
}

/// 我写过的一条评论或回复 (`CommentQueries.Submission`).
///
/// 已删除的评论没有 [text], [imageCount] 为 0. [reasonMessage] 只在审核未通过时有值.
@JsonSerializable(createToJson: false)
class const CommentSubmissionDto({
  final int? id,
  final String? gid,
  final String? revisionId,
  final String? kind,
  final int? foodId,
  final String? moderationStatus,
  final String? reasonCode,
  final String? reasonMessage,
  final String? text,
  final int? imageCount,
  final int? createdAt,
}) {
  factory CommentSubmissionDto.fromJson(Map<String, dynamic> json) =>
      _$CommentSubmissionDtoFromJson(json);
}

/// 赞或取消赞之后, 当前用户对该评论的赞和评论的赞数.
///
/// 评论不可见 (被删除, 被屏蔽) 时取消赞仍会成功, 此时 [liked] 为 false, 两个计数为 0.
@JsonSerializable(createToJson: false)
class const CommentLikeDto({
  final int? commentId,
  final bool? liked,
  final int? likesCount,
  final int? authorLikesCount,
}) {
  factory CommentLikeDto.fromJson(Map<String, dynamic> json) =>
      _$CommentLikeDtoFromJson(json);
}
