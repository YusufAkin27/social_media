import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'delete_message_request.g.dart';

@JsonSerializable()
class DeleteMessageRequest {
  final String messageId;
  final String chatId;

  DeleteMessageRequest({
    required this.messageId,
    required this.chatId,
  });

  factory DeleteMessageRequest.fromJson(Map<String, dynamic> json) => _$DeleteMessageRequestFromJson(json);
  Map<String, dynamic> toJson() => _$DeleteMessageRequestToJson(this);
} 