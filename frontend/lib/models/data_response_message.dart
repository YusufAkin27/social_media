import 'response_message.dart';

class DataResponseMessage<T> extends ResponseMessage {
  final T? data;

  DataResponseMessage({
    required String message,
    required bool isSuccess,
    required this.data,
  }) : super(message: message, isSuccess: isSuccess);

  factory DataResponseMessage.fromJson(Map<String, dynamic> json, T Function(Object?) fromJsonT) {
    final isSuccess = json['success'] as bool? ?? false;
    
    return DataResponseMessage<T>(
      message: json['message'] as String? ?? '',
      isSuccess: isSuccess,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'message': message,
      'success': isSuccess,
    };
    if (data != null) {
      json['data'] = data;
    }
    return json;
  }
} 