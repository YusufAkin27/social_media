// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequestDTO _$LoginRequestDTOFromJson(Map<String, dynamic> json) =>
    LoginRequestDTO(
      username: json['username'] as String,
      password: json['password'] as String,
      ipAddress: json['ipAddress'] as String,
      deviceInfo: json['deviceInfo'] as String,
    );

Map<String, dynamic> _$LoginRequestDTOToJson(LoginRequestDTO instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
      'ipAddress': instance.ipAddress,
      'deviceInfo': instance.deviceInfo,
    };
