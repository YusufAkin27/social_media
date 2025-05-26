// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageDTO _$MessageDTOFromJson(Map<String, dynamic> json) => MessageDTO(
      messageId: json['messageId'] as String,
      content: json['content'] as String,
      senderUsername: json['senderUsername'] as String,
      receiverId: (json['receiverId'] as num).toInt(),
      sentAt: MessageDTO._dateTimeFromJson(json['sentAt'] as String),
      chatId: json['chatId'] as String,
      updatedAt: MessageDTO._dateTimeFromJson(json['updatedAt'] as String),
      isPinned: json['isPinned'] as bool,
      isDeleted: json['isDeleted'] as bool,
    );

Map<String, dynamic> _$MessageDTOToJson(MessageDTO instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'content': instance.content,
      'senderUsername': instance.senderUsername,
      'receiverId': instance.receiverId,
      'sentAt': MessageDTO._dateTimeToJson(instance.sentAt),
      'chatId': instance.chatId,
      'updatedAt': MessageDTO._dateTimeToJson(instance.updatedAt),
      'isPinned': instance.isPinned,
      'isDeleted': instance.isDeleted,
    };
