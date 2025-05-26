import 'package:json_annotation/json_annotation.dart';

part 'message_dto.g.dart';

@JsonSerializable()
class MessageDTO {
  final String messageId; // UUID'ler String olarak temsil edilir
  final String content; // Mesaj içeriği
  final String senderUsername; // Gönderenin kullanıcı adı
  final int receiverId; // Alıcının ID'si
  @JsonKey(name: 'sentAt', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime sentAt; // Mesajın gönderildiği tarih/saat
  final String chatId; // Sohbet ID'si
  @JsonKey(name: 'updatedAt', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime updatedAt; // Mesajın güncellendiği tarih/saat
  final bool isPinned; // Mesajın sabitlenip sabitlenmediği
  final bool isDeleted; // Mesajın silinip silinmediği

  MessageDTO({
    required this.messageId,
    required this.content,
    required this.senderUsername,
    required this.receiverId,
    required this.sentAt,
    required this.chatId,
    required this.updatedAt,
    required this.isPinned,
    required this.isDeleted,
  });

  factory MessageDTO.fromJson(Map<String, dynamic> json) => _$MessageDTOFromJson(json);
  Map<String, dynamic> toJson() => _$MessageDTOToJson(this);

  // Tarih formatlama fonksiyonları
  static DateTime _dateTimeFromJson(String date) => DateTime.parse(date);
  static String _dateTimeToJson(DateTime date) => date.toIso8601String();
} 