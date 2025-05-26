import 'package:json_annotation/json_annotation.dart';
import 'post_dto.dart'; // PostDTO modelini içe aktarın
import 'story_dto.dart'; // StoryDTO modelini içe aktarın
import 'feature_story_dto.dart'; // FeatureStoryDTO modelini içe aktarın

part 'public_account_details.g.dart';

@JsonSerializable()
class PublicAccountDetails {
  final int userId; // long türü Dart'ta int olarak temsil edilir
  final String fullName; // Tam ad
  final String username; // Kullanıcı adı
  final String profilePhoto; // Profil fotoğrafı URL'si
  final String bio; // Biyografi
  final bool isFollow; // Takip ediliyor mu?
  final List<String> commonFriends; // Ortak arkadaşlar
  final int followingCount; // Takip edilen kişi sayısı
  final int followerCount; // Takipçi sayısı
  final int postCount; // Gönderi sayısı
  final bool isPrivate; // Hesap özel mi?
  final int popularityScore; // Popülerlik skoru
  final List<PostDTO> posts; // Gönderi başlıkları veya içerikleri
  final List<StoryDTO> stories; // Hikayeler (Başlıklar veya içerik)
  final List<FeatureStoryDTO> featuredStories; // Öne çıkan hikayeler

  PublicAccountDetails({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.profilePhoto,
    required this.bio,
    required this.isFollow,
    required this.commonFriends,
    required this.followingCount,
    required this.followerCount,
    required this.postCount,
    required this.isPrivate,
    required this.popularityScore,
    required this.posts,
    required this.stories,
    required this.featuredStories,
  });

  factory PublicAccountDetails.fromJson(Map<String, dynamic> json) => _$PublicAccountDetailsFromJson(json);
  Map<String, dynamic> toJson() => _$PublicAccountDetailsToJson(this);
} 