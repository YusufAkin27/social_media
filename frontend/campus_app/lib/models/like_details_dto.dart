import 'package:json_annotation/json_annotation.dart';

part 'like_details_dto.g.dart';

@JsonSerializable()
class LikeDetailsDTO {
  final int userId; // Long türü Dart'ta int olarak temsil edilir
  final String username; // Kullanıcı adı
  final String profilePhoto; // Profil fotoğrafı URL'si

  LikeDetailsDTO({
    required this.userId,
    required this.username,
    required this.profilePhoto,
  });

  factory LikeDetailsDTO.fromJson(Map<String, dynamic> json) => _$LikeDetailsDTOFromJson(json);
  Map<String, dynamic> toJson() => _$LikeDetailsDTOToJson(this);
} 