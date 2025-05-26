import 'package:dio/dio.dart';
import 'package:social_media/models/logs_dto.dart'; // Yeni model
import 'package:social_media/models/data_response_message.dart'; // Yeni model
import 'package:social_media/models/response_message.dart'; // Yeni model

class LogService {
  final Dio _dio;

  LogService(this._dio) {
    _dio.options.baseUrl =
        'http://192.168.89.61:8080/v1/api'; // Base URL ayarlandı
  }

  // Log silme
  Future<ResponseMessage> deleteLog(String token, String logId) async {
    final response = await _dio.delete(
      '/logs/$logId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Logları alma
  Future<DataResponseMessage<List<LogsDTO>>> getLogs(String token) async {
    final response = await _dio.get(
      '/logs',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<LogsDTO>>.fromJson(
      response.data,
      (data) => (data as List)
          .map((item) => LogsDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  // Belirli bir logun detaylarını alma
  Future<DataResponseMessage<LogsDTO>> getLogDetails(
      String token, String logId) async {
    final response = await _dio.get(
      '/logs/$logId/details',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<LogsDTO>.fromJson(
      response.data,
      (data) => LogsDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  // Logları sayfalı olarak alma
  Future<DataResponseMessage<List<LogsDTO>>> getLogsPaginated(
      String token, int page) async {
    final response = await _dio.get(
      '/logs',
      queryParameters: {'page': page},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<LogsDTO>>.fromJson(
      response.data,
      (data) => (data as List)
          .map((item) => LogsDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
