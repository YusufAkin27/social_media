// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostDTO _$PostDTOFromJson(Map<String, dynamic> json) => PostDTO(
      postId: json['postId'] as String,
      userId: (json['userId'] as num).toInt(),
      username: json['username'] as String,
      content:
          (json['content'] as List<dynamic>).map((e) => e as String).toList(),
      profilePhoto: json['profilePhoto'] as String,
      description: json['description'] as String,
      tagAPerson: (json['tagAPerson'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      location: json['location'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      howMoneyMinutesAgo: json['howMoneyMinutesAgo'] as String,
      like: (json['like'] as num).toInt(),
      comment: (json['comment'] as num).toInt(),
      popularityScore: (json['popularityScore'] as num).toInt(),
    );

Map<String, dynamic> _$PostDTOToJson(PostDTO instance) => <String, dynamic>{
      'postId': instance.postId,
      'userId': instance.userId,
      'username': instance.username,
      'content': instance.content,
      'profilePhoto': instance.profilePhoto,
      'description': instance.description,
      'tagAPerson': instance.tagAPerson,
      'location': instance.location,
      'createdAt': instance.createdAt.toIso8601String(),
      'howMoneyMinutesAgo': instance.howMoneyMinutesAgo,
      'like': instance.like,
      'comment': instance.comment,
      'popularityScore': instance.popularityScore,
    };
