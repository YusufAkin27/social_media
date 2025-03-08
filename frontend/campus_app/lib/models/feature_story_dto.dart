import 'package:json_annotation/json_annotation.dart';
import 'story_dto.dart';
part 'feature_story_dto.g.dart';

@JsonSerializable()
class FeatureStoryDTO {
  final String featureStoryId; // UUID'ler String olarak temsil edilir
  final String coverPhoto; // Kapak fotoğrafı URL'si
  final String title; // Başlık
  final List<StoryDTO> storyDTOS; // Hikaye DTO'ları

  FeatureStoryDTO({
    required this.featureStoryId,
    required this.coverPhoto,
    required this.title,
    required this.storyDTOS,
  });

  factory FeatureStoryDTO.fromJson(Map<String, dynamic> json) => _$FeatureStoryDTOFromJson(json);
  Map<String, dynamic> toJson() => _$FeatureStoryDTOToJson(this);
} 