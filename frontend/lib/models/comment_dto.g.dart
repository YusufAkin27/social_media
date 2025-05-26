// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommentDTO _$CommentDTOFromJson(Map<String, dynamic> json) => CommentDTO(
      id: json['id'] as String,
      username: json['username'] as String,
      profilePhoto: json['profilePhoto'] as String,
      postId: json['postId'] as String,
      content: json['content'] as String,
      storyId: json['storyId'] as String?,
      howMoneyMinutesAgo: json['howMoneyMinutesAgo'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$CommentDTOToJson(CommentDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'profilePhoto': instance.profilePhoto,
      'postId': instance.postId,
      'content': instance.content,
      'storyId': instance.storyId,
      'howMoneyMinutesAgo': instance.howMoneyMinutesAgo,
      'createdAt': instance.createdAt.toIso8601String(),
    };
