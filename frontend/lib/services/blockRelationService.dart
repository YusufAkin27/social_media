import 'package:dio/dio.dart';
import 'package:social_media/models/block_user_dto.dart';
import 'package:social_media/models/data_response_message.dart';
import 'package:social_media/models/response_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlockRelationService {
  final Dio _dio;

  BlockRelationService(this._dio) {
    _dio.options.baseUrl =
        'http://192.168.89.61:8080/v1/api'; // Base URL ayarlandı
  }

  // Kullanıcının engellediği kişileri sayfalı şekilde al
  Future<DataResponseMessage<List<BlockUserDTO>>> getBlockedUsers(
      String token, int page) async {
    final response = await _dio.get(
      '/block-relations/blocked',
      queryParameters: {'page': page},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return DataResponseMessage<List<BlockUserDTO>>.fromJson(
      response.data,
      (data) =>
          (data as List).map((item) => BlockUserDTO.fromJson(item)).toList(),
    );
  }

  // Kullanıcıyı engelleme
  Future<ResponseMessage> addWithReason(String token, int userId) async {
    final response = await _dio.post(
      '/block-relations/block/$userId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return ResponseMessage.fromJson(response.data);
  }

  // Kullanıcıyı engelden çıkarma
  Future<ResponseMessage> unblock(String token, int userId) async {
    final response = await _dio.delete(
      '/block-relations/unblock/$userId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return ResponseMessage.fromJson(response.data);
  }

  // Kullanıcının engellenme durumunu kontrol etme
  Future<ResponseMessage> checkBlockStatus(String token, int userId) async {
    final response = await _dio.get(
      '/block-relations/is-blocked/$userId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return ResponseMessage.fromJson(response.data);
  }

  // Engellenen kullanıcıların geçmişini alma
  Future<DataResponseMessage<List<DateTime>>> getBlockHistory(
      String token, int userId) async {
    final response = await _dio.get(
      '/block-relations/block-history/$userId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return DataResponseMessage<List<DateTime>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => DateTime.parse(item)).toList(),
    );
  }

  // Engellenen kullanıcı sayısını alma
  Future<DataResponseMessage<int>> getBlockCount(String token) async {
    final response = await _dio.get(
      '/block-relations/block-count',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return DataResponseMessage<int>.fromJson(
      response.data,
      (data) => data as int,
    );
  }

  // Belirli bir kullanıcının detaylarını alma
  Future<DataResponseMessage<BlockUserDTO>> getUserDetails(
      String token, int userId) async {
    final response = await _dio.get(
      '/block-relations/user/$userId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return DataResponseMessage<BlockUserDTO>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => BlockUserDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  // Kullanıcıyı engelleme ile ilgili bir sebep ekleme
  Future<Response> addWithReasonAndComment(
      String token, int userId, String reason) async {
    final response = await _dio.post(
      '/block-relations/block/$userId',
      data: {'reason': reason},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response;
  }
}
