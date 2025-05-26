import 'package:dio/dio.dart';
import 'package:social_media/models/received_friend_request_dto.dart';
import 'package:social_media/models/sent_friend_request_dto.dart';
import 'package:social_media/models/data_response_message.dart';
import 'package:social_media/models/response_message.dart';
import 'package:social_media/services/authService.dart';

class FriendRequestService {
  Dio? _dio;
  
  // Constructor now gets Dio instance from AuthService
  FriendRequestService() {
    _init();
  }
  
  Future<void> _init() async {
    _dio = await AuthService.getDio();
  }

  // Yeni bir arkadaşlık isteği gönder
  Future<ResponseMessage> sendFriendRequest(int userId) async {
    final dio = _dio ?? await AuthService.getDio();
    final response = await dio.post(
      '/friendsRequest/send/$userId',
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Kullanıcıya gelen arkadaşlık isteklerini getir
  Future<DataResponseMessage<List<ReceivedFriendRequestDTO>>> getReceivedFriendRequests(int page) async {
    final dio = _dio ?? await AuthService.getDio();
    final response = await dio.get(
      '/friendsRequest/received',
      queryParameters: {'page': page},
    );
    return DataResponseMessage<List<ReceivedFriendRequestDTO>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => ReceivedFriendRequestDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // Kullanıcı tarafından gönderilen arkadaşlık isteklerini getir
  Future<DataResponseMessage<List<SentFriendRequestDTO>>> getSentFriendRequests(int page) async {
    final dio = _dio ?? await AuthService.getDio();
    final response = await dio.get(
      '/friendsRequest/sent',
      queryParameters: {'page': page},
    );
    return DataResponseMessage<List<SentFriendRequestDTO>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => SentFriendRequestDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // Arkadaşlık isteğini kabul et
  Future<ResponseMessage> acceptFriendRequest(String requestId) async {
    final dio = _dio ?? await AuthService.getDio();
    final response = await dio.put(
      '/friendsRequest/accept/$requestId',
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Arkadaşlık isteğini reddet
  Future<ResponseMessage> rejectFriendRequest(String requestId) async {
    final dio = _dio ?? await AuthService.getDio();
    final response = await dio.put(
      '/friendsRequest/reject/$requestId',
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Arkadaşlık isteğini iptal et (gönderen tarafından)
  Future<ResponseMessage> cancelFriendRequest(String requestId) async {
    final dio = _dio ?? await AuthService.getDio();
    final response = await dio.delete(
      '/friendsRequest/cancel/$requestId',
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Belirli bir arkadaşlık isteğini getir
  Future<DataResponseMessage<dynamic>> getFriendRequestById(String requestId) async {
    final dio = _dio ?? await AuthService.getDio();
    final response = await dio.get(
      '/friendsRequest/$requestId',
    );
    return DataResponseMessage<dynamic>.fromJson(response.data, (data) => data);
  }

  // Arkadaşlık isteklerini reddetme (toplu)
  Future<ResponseMessage> rejectFriendRequestsBulk(List<String> requestIds) async {
    final dio = _dio ?? await AuthService.getDio();
    final response = await dio.put(
      '/friendsRequest/reject-bulk',
      data: requestIds,
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Arkadaşlık isteklerini kabul etme (toplu)
  Future<ResponseMessage> acceptFriendRequestsBulk(List<String> requestIds) async {
    final dio = _dio ?? await AuthService.getDio();
    final response = await dio.put(
      '/friendsRequest/accept-bulk',
      data: requestIds,
    );
    return ResponseMessage.fromJson(response.data);
  }
}
