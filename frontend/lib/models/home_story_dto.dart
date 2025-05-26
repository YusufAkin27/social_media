import 'package:json_annotation/json_annotation.dart';

part 'home_story_dto.g.dart';

@JsonSerializable()
class HomeStoryDTO {
  final List<String> storyId; // UUID'ler String olarak temsil edilir
  final int studentId; // long türü Dart'ta int olarak temsil edilir
  final String username; // Kullanıcı adı
  final List<String> photos; // Fotoğraflar
  final String profilePhoto; // Profil fotoğrafı URL'si
  @JsonKey(name: 'visited') // Map 'visited' from API to 'isVisited' in class
  final bool isVisited; // Ziyaret edildi mi?

  HomeStoryDTO({
    required this.storyId,
    required this.studentId,
    required this.username,
    required this.photos,
    required this.profilePhoto,
    required this.isVisited,
  });

  factory HomeStoryDTO.fromJson(Map<String, dynamic> json) => _$HomeStoryDTOFromJson(json);
  Map<String, dynamic> toJson() => _$HomeStoryDTOToJson(this);
} 