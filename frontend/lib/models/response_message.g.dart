// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResponseMessage _$ResponseMessageFromJson(Map<String, dynamic> json) =>
    ResponseMessage(
      message: json['message'] as String,
      isSuccess: json['isSuccess'] as bool,
    );

Map<String, dynamic> _$ResponseMessageToJson(ResponseMessage instance) =>
    <String, dynamic>{
      'message': instance.message,
      'isSuccess': instance.isSuccess,
    };
