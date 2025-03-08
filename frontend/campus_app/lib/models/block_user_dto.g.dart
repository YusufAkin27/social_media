// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'block_user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlockUserDTO _$BlockUserDTOFromJson(Map<String, dynamic> json) => BlockUserDTO(
      username: json['username'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      blockDate: DateTime.parse(json['blockDate'] as String),
      profilePhoto: json['profilePhoto'] as String,
    );

Map<String, dynamic> _$BlockUserDTOToJson(BlockUserDTO instance) =>
    <String, dynamic>{
      'username': instance.username,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'blockDate': instance.blockDate.toIso8601String(),
      'profilePhoto': instance.profilePhoto,
    };
