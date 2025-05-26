// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_details_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommentDetailsDTO _$CommentDetailsDTOFromJson(Map<String, dynamic> json) =>
    CommentDetailsDTO(
      userId: (json['userId'] as num).toInt(),
      username: json['username'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      howMoneyMinutesAgo: json['howMoneyMinutesAgo'] as String,
    );

Map<String, dynamic> _$CommentDetailsDTOToJson(CommentDetailsDTO instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'username': instance.username,
      'content': instance.content,
      'createdAt': instance.createdAt.toIso8601String(),
      'howMoneyMinutesAgo': instance.howMoneyMinutesAgo,
    };
