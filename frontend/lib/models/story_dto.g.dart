// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoryDTO _$StoryDTOFromJson(Map<String, dynamic> json) => StoryDTO(
      storyId: json['storyId'] as String,
      profilePhoto: json['profilePhoto'] as String,
      username: json['username'] as String,
      userId: (json['userId'] as num).toInt(),
      photo: json['photo'] as String,
      score: (json['score'] as num).toInt(),
    );

Map<String, dynamic> _$StoryDTOToJson(StoryDTO instance) => <String, dynamic>{
      'storyId': instance.storyId,
      'profilePhoto': instance.profilePhoto,
      'username': instance.username,
      'userId': instance.userId,
      'photo': instance.photo,
      'score': instance.score,
    };
