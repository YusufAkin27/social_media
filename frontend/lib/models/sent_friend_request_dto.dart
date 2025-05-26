import 'package:json_annotation/json_annotation.dart';

part 'sent_friend_request_dto.g.dart';

@JsonSerializable()
class SentFriendRequestDTO {
  final String requestId; // UUID'ler String olarak temsil edilir
  final String receiverPhotoUrl; // Alıcının profil fotoğrafının URL'si
  final String receiverUsername; // Alıcının kullanıcı adı
  final String receiverFullName; // Alıcının tam adı
  @JsonKey(name: 'sentAt')
  final String sentAt; // İsteğin gönderildiği tarih/saat (formatlanmış)
  final String status; // İsteğin durumu (örn: PENDING, ACCEPTED, REJECTED)
  final int popularityScore; // Gönderenin popülerlik skoru

  SentFriendRequestDTO({
    required this.requestId,
    required this.receiverPhotoUrl,
    required this.receiverUsername,
    required this.receiverFullName,
    required this.sentAt,
    required this.status,
    required this.popularityScore,
  });

  factory SentFriendRequestDTO.fromJson(Map<String, dynamic> json) => _$SentFriendRequestDTOFromJson(json);
  Map<String, dynamic> toJson() => _$SentFriendRequestDTOToJson(this);
} 