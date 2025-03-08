// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_access_token_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateAccessTokenRequestDTO _$UpdateAccessTokenRequestDTOFromJson(
        Map<String, dynamic> json) =>
    UpdateAccessTokenRequestDTO(
      refreshToken: json['refreshToken'] as String,
      ipAddress: json['ipAddress'] as String,
      deviceInfo: json['deviceInfo'] as String,
    );

Map<String, dynamic> _$UpdateAccessTokenRequestDTOToJson(
        UpdateAccessTokenRequestDTO instance) =>
    <String, dynamic>{
      'refreshToken': instance.refreshToken,
      'ipAddress': instance.ipAddress,
      'deviceInfo': instance.deviceInfo,
    };
