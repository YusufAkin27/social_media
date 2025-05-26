// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenResponseDTO _$TokenResponseDTOFromJson(Map<String, dynamic> json) =>
    TokenResponseDTO(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );

Map<String, dynamic> _$TokenResponseDTOToJson(TokenResponseDTO instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
    };
