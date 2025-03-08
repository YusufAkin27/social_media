// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_message_status_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateMessageStatusRequest _$UpdateMessageStatusRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateMessageStatusRequest(
      messageId: json['messageId'] as String,
      status: json['status'] as String,
    );

Map<String, dynamic> _$UpdateMessageStatusRequestToJson(
        UpdateMessageStatusRequest instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'status': instance.status,
    };
