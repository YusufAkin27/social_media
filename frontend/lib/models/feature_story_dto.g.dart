// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feature_story_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeatureStoryDTO _$FeatureStoryDTOFromJson(Map<String, dynamic> json) =>
    FeatureStoryDTO(
      featureStoryId: json['featureStoryId'] as String,
      coverPhoto: json['coverPhoto'] as String,
      title: json['title'] as String,
      storyDTOS: (json['storyDTOS'] as List<dynamic>)
          .map((e) => StoryDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FeatureStoryDTOToJson(FeatureStoryDTO instance) =>
    <String, dynamic>{
      'featureStoryId': instance.featureStoryId,
      'coverPhoto': instance.coverPhoto,
      'title': instance.title,
      'storyDTOS': instance.storyDTOS,
    };
