// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommentAuthorDto _$CommentAuthorDtoFromJson(Map<String, dynamic> json) =>
    CommentAuthorDto(
      id: (json['id'] as num?)?.toInt(),
      displayName: json['displayName'] as String?,
      avatar: json['avatar'] as String?,
      title: json['title'] as String?,
    );

CommentDto _$CommentDtoFromJson(Map<String, dynamic> json) => CommentDto(
  id: (json['id'] as num?)?.toInt(),
  foodId: (json['foodId'] as num?)?.toInt(),
  rootId: (json['rootId'] as num?)?.toInt(),
  author: json['author'] == null
      ? null
      : CommentAuthorDto.fromJson(json['author'] as Map<String, dynamic>),
  replyTo: json['replyTo'] == null
      ? null
      : CommentAuthorDto.fromJson(json['replyTo'] as Map<String, dynamic>),
  text: json['text'] as String?,
  pictureUrls: (json['pictureUrls'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  likeCount: (json['likeCount'] as num?)?.toInt(),
  replyCount: (json['replyCount'] as num?)?.toInt(),
  isLiked: json['isLiked'] as bool?,
  createdAt: (json['createdAt'] as num?)?.toInt(),
);

GalleryImageDto _$GalleryImageDtoFromJson(Map<String, dynamic> json) =>
    GalleryImageDto(
      commentId: (json['commentId'] as num?)?.toInt(),
      slot: (json['slot'] as num?)?.toInt(),
      url: json['url'] as String?,
      author: json['author'] == null
          ? null
          : CommentAuthorDto.fromJson(json['author'] as Map<String, dynamic>),
      createdAt: (json['createdAt'] as num?)?.toInt(),
    );
