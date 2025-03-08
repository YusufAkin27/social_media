// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_post_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomePostDTO _$HomePostDTOFromJson(Map<String, dynamic> json) => HomePostDTO(
      postId: (json['postId'] as num).toInt(),
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
      isFollow: json['isFollow'] as bool,
      like: (json['like'] as num).toInt(),
      comment: (json['comment'] as num).toInt(),
      popularityScore: (json['popularityScore'] as num).toInt(),
    );

Map<String, dynamic> _$HomePostDTOToJson(HomePostDTO instance) =>
    <String, dynamic>{
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
      'isFollow': instance.isFollow,
      'like': instance.like,
      'comment': instance.comment,
      'popularityScore': instance.popularityScore,
    };
