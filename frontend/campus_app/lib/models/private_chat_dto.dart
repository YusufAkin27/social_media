import 'package:json_annotation/json_annotation.dart';
import 'message_dto.dart'; // MessageDTO'yu içe aktarın

part 'private_chat_dto.g.dart';

@JsonSerializable()
class PrivateChatDTO {
  final String chatId; // UUID'ler String olarak temsil edilir
  final String chatName; // Sohbet adı
  final String chatPhoto; // Sohbet fotoğrafı
  final String username1; // Kullanıcı 1
  final String username2; // Kullanıcı 2
  final MessageDTO lastEndMessage; // Son mesaj

  PrivateChatDTO({
    required this.chatId,
    required this.chatName,
    required this.chatPhoto,
    required this.username1,
    required this.username2,
    required this.lastEndMessage,
  });

  factory PrivateChatDTO.fromJson(Map<String, dynamic> json) => _$PrivateChatDTOFromJson(json);
  Map<String, dynamic> toJson() => _$PrivateChatDTOToJson(this);
} 