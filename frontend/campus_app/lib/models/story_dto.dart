import 'package:json_annotation/json_annotation.dart';

part 'story_dto.g.dart';

@JsonSerializable()
class StoryDTO {
  final String storyId; // UUID'ler String olarak temsil edilir
  final String profilePhoto; // Profil fotoğrafı
  final String username; // Kullanıcı adı
  final int userId; // Kullanıcı ID'si
  final String photo; // Hikaye fotoğrafı
  final int score; // Hikaye skoru

  StoryDTO({
    required this.storyId,
    required this.profilePhoto,
    required this.username,
    required this.userId,
    required this.photo,
    required this.score,
  });

  factory StoryDTO.fromJson(Map<String, dynamic> json) => _$StoryDTOFromJson(json);
  Map<String, dynamic> toJson() => _$StoryDTOToJson(this);
} 