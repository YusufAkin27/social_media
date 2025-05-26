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

  // Custom factory method to handle type conversion issues
  factory StoryDTO.fromJson(Map<String, dynamic> json) {
    // Safely convert numeric types
    int safeIntParse(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          print('Int parsing error for $value: $e');
          return defaultValue;
        }
      }
      return defaultValue;
    }

    return StoryDTO(
      storyId: json['storyId'] as String? ?? '',
      profilePhoto: json['profilePhoto'] as String? ?? '',
      username: json['username'] as String? ?? '',
      userId: safeIntParse(json['userId']),
      photo: json['photo'] as String? ?? '',
      score: safeIntParse(json['score']),
    );
  }

  Map<String, dynamic> toJson() => _$StoryDTOToJson(this);
} 