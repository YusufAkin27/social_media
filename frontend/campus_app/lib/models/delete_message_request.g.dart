// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_message_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeleteMessageRequest _$DeleteMessageRequestFromJson(
        Map<String, dynamic> json) =>
    DeleteMessageRequest(
      messageId: json['messageId'] as String,
      chatId: json['chatId'] as String,
    );

Map<String, dynamic> _$DeleteMessageRequestToJson(
        DeleteMessageRequest instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'chatId': instance.chatId,
    };
