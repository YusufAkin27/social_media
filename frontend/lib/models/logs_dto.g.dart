// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logs_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LogsDTO _$LogsDTOFromJson(Map<String, dynamic> json) => LogsDTO(
      logId: json['logId'] as String,
      message: json['message'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
    );

Map<String, dynamic> _$LogsDTOToJson(LogsDTO instance) => <String, dynamic>{
      'logId': instance.logId,
      'message': instance.message,
      'sentAt': instance.sentAt.toIso8601String(),
    };
