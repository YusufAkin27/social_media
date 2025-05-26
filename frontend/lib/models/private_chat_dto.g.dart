// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'private_chat_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrivateChatDTO _$PrivateChatDTOFromJson(Map<String, dynamic> json) =>
    PrivateChatDTO(
      chatId: json['chatId'] as String,
      chatName: json['chatName'] as String,
      chatPhoto: json['chatPhoto'] as String,
      username1: json['username1'] as String,
      username2: json['username2'] as String,
      lastEndMessage:
          MessageDTO.fromJson(json['lastEndMessage'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PrivateChatDTOToJson(PrivateChatDTO instance) =>
    <String, dynamic>{
      'chatId': instance.chatId,
      'chatName': instance.chatName,
      'chatPhoto': instance.chatPhoto,
      'username1': instance.username1,
      'username2': instance.username2,
      'lastEndMessage': instance.lastEndMessage,
    };
