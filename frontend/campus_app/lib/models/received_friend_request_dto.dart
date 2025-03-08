import 'package:json_annotation/json_annotation.dart';

part 'received_friend_request_dto.g.dart';

@JsonSerializable()
class ReceivedFriendRequestDTO {
  final String requestId; // UUID'ler String olarak temsil edilir
  final String senderPhotoUrl; // Gönderenin profil fotoğrafının URL'si
  final String senderUsername; // Gönderenin kullanıcı adı
  final String senderFullName; // Gönderenin tam adı
  @JsonKey(name: 'sentAt')
  final String sentAt; // İsteğin gönderildiği tarih/saat (formatlanmış)
  final int popularityScore; // Gönderenin popülerlik skoru

  ReceivedFriendRequestDTO({
    required this.requestId,
    required this.senderPhotoUrl,
    required this.senderUsername,
    required this.senderFullName,
    required this.sentAt,
    required this.popularityScore,
  });

  factory ReceivedFriendRequestDTO.fromJson(Map<String, dynamic> json) => _$ReceivedFriendRequestDTOFromJson(json);
  Map<String, dynamic> toJson() => _$ReceivedFriendRequestDTOToJson(this);
} 