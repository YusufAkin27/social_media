// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'edit_message_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EditMessageRequest _$EditMessageRequestFromJson(Map<String, dynamic> json) =>
    EditMessageRequest(
      messageId: json['messageId'] as String,
      chatId: json['chatId'] as String,
      content: json['content'] as String,
    );

Map<String, dynamic> _$EditMessageRequestToJson(EditMessageRequest instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'chatId': instance.chatId,
      'content': instance.content,
    };
