import 'package:json_annotation/json_annotation.dart';

part 'response_message.g.dart';

@JsonSerializable()
class ResponseMessage {
  final String message;
  final bool isSuccess;

  ResponseMessage({
    required this.message,
    required this.isSuccess,
  });

  factory ResponseMessage.fromJson(Map<String, dynamic> json) {
    // isSuccess alanı null ise false değerini ver
    final isSuccess = json['isSuccess'] as bool? ?? false;
    
    return ResponseMessage(
      message: json['message'] as String,
      isSuccess: isSuccess,
    );
  }
  
  Map<String, dynamic> toJson() => _$ResponseMessageToJson(this);
} 