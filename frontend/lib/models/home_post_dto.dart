import 'package:json_annotation/json_annotation.dart';

part 'home_post_dto.g.dart';

@JsonSerializable()
class HomePostDTO {
  final int postId; // long türü Dart'ta int olarak temsil edilir
  final int userId; // long türü Dart'ta int olarak temsil edilir
  final String username; // Kullanıcı adı
  final List<String> content; // İçerik
  final String profilePhoto; // Profil fotoğrafı URL'si
  final String description; // Açıklama
  final List<String> tagAPerson; // Kişi etiketleme
  final String location; // Konum
  @JsonKey(name: 'createdAt')
  final DateTime createdAt; // Oluşturulma tarihi
  final String howMoneyMinutesAgo; // Ne kadar önce
  final bool isFollow; // Takip ediliyor mu?

  final int like; // Beğeni sayısı
  final int comment; // Yorum sayısı
  final int popularityScore; // Popülerlik skoru

  HomePostDTO({
    required this.postId,
    required this.userId,
    required this.username,
    required this.content,
    required this.profilePhoto,
    required this.description,
    required this.tagAPerson,
    required this.location,
    required this.createdAt,
    required this.howMoneyMinutesAgo,
    required this.isFollow,
    required this.like,
    required this.comment,
    required this.popularityScore,
  });

  factory HomePostDTO.fromJson(Map<String, dynamic> json) => _$HomePostDTOFromJson(json);
  Map<String, dynamic> toJson() => _$HomePostDTOToJson(this);
} 