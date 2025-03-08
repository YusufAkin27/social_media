import 'package:json_annotation/json_annotation.dart';

part 'best_popularity_account.g.dart';

@JsonSerializable()
class BestPopularityAccount {
  final int userId; // long türü Dart'ta int olarak temsil edilir
  final String fullName; // Tam ad
  final String username; // Kullanıcı adı
  final String profilePhoto; // Profil fotoğrafı URL'si
  @JsonKey(defaultValue: false)
  final bool? isFollow; // Takip ediliyor mu?
  final List<String> commonFriends; // Ortak arkadaşlar
  final int followingCount; // Takip edilen kişi sayısı
  final int followerCount; // Takipçi sayısı
  final int postCount; // Gönderi sayısı
  @JsonKey(defaultValue: false)
  final bool? isPrivate; // Kullanıcı özel mi?
  final int popularityScore; // Kullanıcının popülerlik skoru

  BestPopularityAccount({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.profilePhoto,
    this.isFollow,
    required this.commonFriends,
    required this.followingCount,
    required this.followerCount,
    required this.postCount,
    this.isPrivate,
    required this.popularityScore,
  });

  factory BestPopularityAccount.fromJson(Map<String, dynamic> json) => _$BestPopularityAccountFromJson(json);
  Map<String, dynamic> toJson() => _$BestPopularityAccountToJson(this);
} 