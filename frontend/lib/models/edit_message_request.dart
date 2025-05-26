import 'package:json_annotation/json_annotation.dart';

part 'edit_message_request.g.dart';

@JsonSerializable()
class EditMessageRequest {
  final String messageId;
  final String chatId;
  final String content;

  EditMessageRequest({
    required this.messageId,
    required this.chatId,
    required this.content,
  });

  factory EditMessageRequest.fromJson(Map<String, dynamic> json) => _$EditMessageRequestFromJson(json);
  Map<String, dynamic> toJson() => _$EditMessageRequestToJson(this);
} 