// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_story_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeStoryDTO _$HomeStoryDTOFromJson(Map<String, dynamic> json) => HomeStoryDTO(
      storyId:
          (json['storyId'] as List<dynamic>).map((e) => e as String).toList(),
      studentId: (json['studentId'] as num).toInt(),
      username: json['username'] as String,
      photos:
          (json['photos'] as List<dynamic>).map((e) => e as String).toList(),
      profilePhoto: json['profilePhoto'] as String,
      isVisited: json['visited'] as bool,
    );

Map<String, dynamic> _$HomeStoryDTOToJson(HomeStoryDTO instance) =>
    <String, dynamic>{
      'storyId': instance.storyId,
      'studentId': instance.studentId,
      'username': instance.username,
      'photos': instance.photos,
      'profilePhoto': instance.profilePhoto,
      'visited': instance.isVisited,
    };
