// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sent_friend_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SentFriendRequestDTO _$SentFriendRequestDTOFromJson(
        Map<String, dynamic> json) =>
    SentFriendRequestDTO(
      requestId: json['requestId'] as String,
      receiverPhotoUrl: json['receiverPhotoUrl'] as String,
      receiverUsername: json['receiverUsername'] as String,
      receiverFullName: json['receiverFullName'] as String,
      sentAt: json['sentAt'] as String,
      status: json['status'] as String,
      popularityScore: (json['popularityScore'] as num).toInt(),
    );

Map<String, dynamic> _$SentFriendRequestDTOToJson(
        SentFriendRequestDTO instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'receiverPhotoUrl': instance.receiverPhotoUrl,
      'receiverUsername': instance.receiverUsername,
      'receiverFullName': instance.receiverFullName,
      'sentAt': instance.sentAt,
      'status': instance.status,
      'popularityScore': instance.popularityScore,
    };
