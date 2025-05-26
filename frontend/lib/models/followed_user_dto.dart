import 'package:json_annotation/json_annotation.dart';

part 'followed_user_dto.g.dart';

@JsonSerializable()
class FollowedUserDTO {
  final int id; // long türü Dart'ta int olarak temsil edilir
  final String username; // Kullanıcı adı
  final String fullName; // Tam ad
  final String? profilePhotoUrl; // Profil fotoğrafı URL'si

  @JsonKey(name: 'followedDate')
  final DateTime followedDate; // Takip edildiği tarih

  @JsonKey(defaultValue: false)
  final bool isActive; // Takip ilişkisi aktif mi?
  
  @JsonKey(defaultValue: false)
  final bool isPrivate; // Kullanıcı özel mi?
  
  final String? bio; // Kullanıcının biyografisi
  final int popularityScore; // Kullanıcının popülerlik skoru
  
  @JsonKey(name: 'isFollowing', defaultValue: false)
  final bool isFollowing; // Kullanıcı takip ediliyor mu?

  FollowedUserDTO({
    required this.id,
    required this.username,
    required this.fullName,
    this.profilePhotoUrl,
    required this.followedDate,
    required this.isActive,
    required this.isPrivate,
    this.bio,
    required this.popularityScore,
    required this.isFollowing,
  });

  factory FollowedUserDTO.fromJson(Map<String, dynamic> json) => _$FollowedUserDTOFromJson(json);
  Map<String, dynamic> toJson() => _$FollowedUserDTOToJson(this);
} 