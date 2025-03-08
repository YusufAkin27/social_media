import 'package:json_annotation/json_annotation.dart';
import 'comment_details_dto.dart';
import 'search_account_dto.dart';
import 'like_details_dto.dart';
part 'story_details.g.dart';

@JsonSerializable()
class StoryDetails {
  final String id; // UUID'ler String olarak temsil edilir
  final String username; // Hikayeyi paylaşan kullanıcının adı
  final String photoUrl; // Hikayenin fotoğraf URL'si
  @JsonKey(name: 'createdAt')
  final DateTime createdAt; // Oluşturulma tarihi
  @JsonKey(name: 'expiresAt')
  final DateTime expiresAt; // Son kullanma tarihi
  final bool isActive; // Aktif mi?
  final int likeCount; // Beğeni sayısı
  final List<CommentDetailsDTO> comments; // Yorumlar
  final List<SearchAccountDTO> viewing; // Görüntüleyenler
  final List<LikeDetailsDTO> likes; // Beğeniler

  StoryDetails({
    required this.id,
    required this.username,
    required this.photoUrl,
    required this.createdAt,
    required this.expiresAt,
    required this.isActive,
    required this.likeCount,
    required this.comments,
    required this.viewing,
    required this.likes,
  });

  factory StoryDetails.fromJson(Map<String, dynamic> json) => _$StoryDetailsFromJson(json);
  Map<String, dynamic> toJson() => _$StoryDetailsToJson(this);
} 