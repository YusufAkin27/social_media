import 'package:dio/dio.dart';
import 'package:social_media/models/received_friend_request_dto.dart';
import 'package:social_media/models/sent_friend_request_dto.dart';
import 'package:social_media/models/data_response_message.dart';
import 'package:social_media/models/response_message.dart';

class FriendRequestService {
  final Dio _dio;

  FriendRequestService(this._dio) {
    _dio.options.baseUrl = 'http://localhost:8080/v1/api'; // Base URL ayarlandı
  }

  // Yeni bir arkadaşlık isteği gönder
  Future<ResponseMessage> sendFriendRequest(String token, int userId) async {
    final response = await _dio.post(
      '/friendsRequest/send/$userId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Kullanıcıya gelen arkadaşlık isteklerini getir
  Future<DataResponseMessage<List<ReceivedFriendRequestDTO>>> getReceivedFriendRequests(String token, int page) async {
    final response = await _dio.get(
      '/friendsRequest/received',
      queryParameters: {'page': page},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<ReceivedFriendRequestDTO>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => ReceivedFriendRequestDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // Kullanıcı tarafından gönderilen arkadaşlık isteklerini getir
  Future<DataResponseMessage<List<SentFriendRequestDTO>>> getSentFriendRequests(String token, int page) async {
    final response = await _dio.get(
      '/friendsRequest/sent',
      queryParameters: {'page': page},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<SentFriendRequestDTO>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => SentFriendRequestDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // Arkadaşlık isteğini kabul et
  Future<ResponseMessage> acceptFriendRequest(String token, String requestId) async {
    final response = await _dio.put(
      '/friendsRequest/accept/$requestId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Arkadaşlık isteğini reddet
  Future<ResponseMessage> rejectFriendRequest(String token, String requestId) async {
    final response = await _dio.put(
      '/friendsRequest/reject/$requestId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Arkadaşlık isteğini iptal et (gönderen tarafından)
  Future<ResponseMessage> cancelFriendRequest(String token, String requestId) async {
    final response = await _dio.delete(
      '/friendsRequest/cancel/$requestId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Belirli bir arkadaşlık isteğini getir
  Future<DataResponseMessage<dynamic>> getFriendRequestById(String token, String requestId) async {
    final response = await _dio.get(
      '/friendsRequest/$requestId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<dynamic>.fromJson(response.data, (data) => data);
  }

  // Arkadaşlık isteklerini reddetme (toplu)
  Future<ResponseMessage> rejectFriendRequestsBulk(String token, List<String> requestIds) async {
    final response = await _dio.put(
      '/friendsRequest/reject-bulk',
      data: requestIds,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Arkadaşlık isteklerini kabul etme (toplu)
  Future<ResponseMessage> acceptFriendRequestsBulk(String token, List<String> requestIds) async {
    final response = await _dio.put(
      '/friendsRequest/accept-bulk',
      data: requestIds,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }
}
