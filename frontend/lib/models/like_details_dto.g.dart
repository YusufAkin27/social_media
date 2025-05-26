// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'like_details_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LikeDetailsDTO _$LikeDetailsDTOFromJson(Map<String, dynamic> json) =>
    LikeDetailsDTO(
      userId: (json['userId'] as num).toInt(),
      username: json['username'] as String,
      profilePhoto: json['profilePhoto'] as String,
    );

Map<String, dynamic> _$LikeDetailsDTOToJson(LikeDetailsDTO instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'username': instance.username,
      'profilePhoto': instance.profilePhoto,
    };
