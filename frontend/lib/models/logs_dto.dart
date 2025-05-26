import 'package:json_annotation/json_annotation.dart';

part 'logs_dto.g.dart';

@JsonSerializable()
class LogsDTO {
  final String logId; // UUID'ler String olarak temsil edilir
  final String message; // Mesaj içeriği
  @JsonKey(name: 'sentAt')
  final DateTime sentAt; // Gönderilme tarihi

  LogsDTO({
    required this.logId,
    required this.message,
    required this.sentAt,
  });

  factory LogsDTO.fromJson(Map<String, dynamic> json) => _$LogsDTOFromJson(json);
  Map<String, dynamic> toJson() => _$LogsDTOToJson(this);
} 