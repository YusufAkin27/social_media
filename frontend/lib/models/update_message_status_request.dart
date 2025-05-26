import 'package:json_annotation/json_annotation.dart';

part 'update_message_status_request.g.dart';

@JsonSerializable()
class UpdateMessageStatusRequest {
  final String messageId;
  final String status; // "delivered" veya "seen"

  UpdateMessageStatusRequest({
    required this.messageId,
    required this.status,
  });

  factory UpdateMessageStatusRequest.fromJson(Map<String, dynamic> json) => _$UpdateMessageStatusRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateMessageStatusRequestToJson(this);
} 