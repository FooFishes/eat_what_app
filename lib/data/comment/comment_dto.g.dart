// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommentDto _$CommentDtoFromJson(Map<String, dynamic> json) => CommentDto(
  id: (json['id'] as num?)?.toInt(),
  gid: json['gid'] as String?,
  revisionId: json['revisionId'] as String?,
  kind: json['kind'] as String?,
  foodId: (json['foodId'] as num?)?.toInt(),
  rootCommentGid: json['rootCommentGid'] as String?,
  replyToGid: json['replyToGid'] as String?,
  authorName: json['authorName'] as String?,
  text: json['text'] as String?,
  likesCount: (json['likesCount'] as num?)?.toInt(),
  createdAt: (json['createdAt'] as num?)?.toInt(),
  images: (json['images'] as List<dynamic>?)
      ?.map((e) => CommentImageDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

CommentImageDto _$CommentImageDtoFromJson(Map<String, dynamic> json) =>
    CommentImageDto(
      slot: (json['slot'] as num?)?.toInt(),
      url: json['url'] as String?,
      expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt(),
    );

GalleryImageDto _$GalleryImageDtoFromJson(Map<String, dynamic> json) =>
    GalleryImageDto(
      commentId: (json['commentId'] as num?)?.toInt(),
      commentGid: json['commentGid'] as String?,
      createdAt: (json['createdAt'] as num?)?.toInt(),
      image: json['image'] == null
          ? null
          : CommentImageDto.fromJson(json['image'] as Map<String, dynamic>),
    );

CommentAcceptedDto _$CommentAcceptedDtoFromJson(Map<String, dynamic> json) =>
    CommentAcceptedDto(
      id: (json['id'] as num?)?.toInt(),
      commentGid: json['commentGid'] as String?,
      revisionId: json['revisionId'] as String?,
      moderationStatus: json['moderationStatus'] as String?,
    );

CommentSubmissionDto _$CommentSubmissionDtoFromJson(
  Map<String, dynamic> json,
) => CommentSubmissionDto(
  id: (json['id'] as num?)?.toInt(),
  gid: json['gid'] as String?,
  revisionId: json['revisionId'] as String?,
  kind: json['kind'] as String?,
  foodId: (json['foodId'] as num?)?.toInt(),
  moderationStatus: json['moderationStatus'] as String?,
  reasonCode: json['reasonCode'] as String?,
  reasonMessage: json['reasonMessage'] as String?,
  text: json['text'] as String?,
  imageCount: (json['imageCount'] as num?)?.toInt(),
  createdAt: (json['createdAt'] as num?)?.toInt(),
);

CommentLikeDto _$CommentLikeDtoFromJson(Map<String, dynamic> json) =>
    CommentLikeDto(
      commentId: (json['commentId'] as num?)?.toInt(),
      liked: json['liked'] as bool?,
      likesCount: (json['likesCount'] as num?)?.toInt(),
      authorLikesCount: (json['authorLikesCount'] as num?)?.toInt(),
    );
