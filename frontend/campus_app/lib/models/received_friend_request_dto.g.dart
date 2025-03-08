// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'received_friend_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceivedFriendRequestDTO _$ReceivedFriendRequestDTOFromJson(
        Map<String, dynamic> json) =>
    ReceivedFriendRequestDTO(
      requestId: json['requestId'] as String,
      senderPhotoUrl: json['senderPhotoUrl'] as String,
      senderUsername: json['senderUsername'] as String,
      senderFullName: json['senderFullName'] as String,
      sentAt: json['sentAt'] as String,
      popularityScore: (json['popularityScore'] as num).toInt(),
    );

Map<String, dynamic> _$ReceivedFriendRequestDTOToJson(
        ReceivedFriendRequestDTO instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'senderPhotoUrl': instance.senderPhotoUrl,
      'senderUsername': instance.senderUsername,
      'senderFullName': instance.senderFullName,
      'sentAt': instance.sentAt,
      'popularityScore': instance.popularityScore,
    };
