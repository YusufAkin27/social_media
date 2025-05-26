import 'package:json_annotation/json_annotation.dart';

part 'private_account_details.g.dart';

@JsonSerializable()
class PrivateAccountDetails {
  final int id; // long türü Dart'ta int olarak temsil edilir
  final String username; // Kullanıcı adı
  final String profilePhoto; // Profil fotoğrafı URL'si
  final String bio; // Biyografi
  final bool isFollow; // Takip ediliyor mu?
  final List<String> commonFriends; // Ortak arkadaşlar
  final int followingCount; // Takip edilen kişi sayısı
  final int followerCount; // Takipçi sayısı
  final int postCount; // Gönderi sayısı
  final bool isSentRequest; // İstek gönderildi mi?
  final bool isPrivate; // Hesap özel mi?
  final int popularityScore; // Popülerlik skoru

  PrivateAccountDetails({
    required this.id,
    required this.username,
    required this.profilePhoto,
    required this.bio,
    required this.isFollow,
    required this.commonFriends,
    required this.followingCount,
    required this.followerCount,
    required this.postCount,
    required this.isSentRequest,
    required this.isPrivate,
    required this.popularityScore,
  });

  factory PrivateAccountDetails.fromJson(Map<String, dynamic> json) => _$PrivateAccountDetailsFromJson(json);
  Map<String, dynamic> toJson() => _$PrivateAccountDetailsToJson(this);
} 