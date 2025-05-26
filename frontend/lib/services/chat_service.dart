import 'package:dio/dio.dart';
import 'package:social_media/models/message_dto.dart';
import 'package:social_media/models/private_chat_dto.dart';
import 'package:social_media/models/data_response_message.dart';
import 'package:social_media/models/response_message.dart';
import 'package:social_media/models/send_message_request.dart';
import 'package:social_media/models/edit_message_request.dart';
import 'package:social_media/models/delete_message_request.dart';
import 'package:social_media/models/update_message_status_request.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  final Dio _dio;

  ChatService(this._dio) {
    _dio.options.baseUrl =
        'http://192.168.89.61:8080/v1/api/privateChat'; // Base URL ayarlandı
  }

  // Yeni özel sohbet oluştur
  Future<ResponseMessage> createChat(String token, String username) async {
    final response = await _dio.post(
      '/createChat/$username',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Mesaj gönder
  Future<DataResponseMessage<MessageDTO>> sendPrivateMessage(
      String token, SendMessageRequest request) async {
    final response = await _dio.post(
      '/send',
      data: request.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<MessageDTO>.fromJson(
      response.data,
      (data) => MessageDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  // Kullanıcının sohbetlerini getir
  Future<DataResponseMessage<List<PrivateChatDTO>>> getChats(
      String token) async {
    final response = await _dio.get(
      '/getChats',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<PrivateChatDTO>>.fromJson(
      response.data,
      (data) => (data as List)
          .map((item) => PrivateChatDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  // Belirli bir sohbetin mesajlarını getir
  Future<DataResponseMessage<List<MessageDTO>>> getMessages(
      String token, String chatId) async {
    final response = await _dio.get(
      '/getMessages/$chatId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<MessageDTO>>.fromJson(
      response.data,
      (data) => (data as List)
          .map((item) => MessageDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  // Mesajı düzenle
  Future<ResponseMessage> editMessage(
      String token, EditMessageRequest request) async {
    final response = await _dio.put(
      '/editMessage',
      data: request.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Mesajı sil
  Future<ResponseMessage> deleteMessage(
      String token, DeleteMessageRequest request) async {
    final response = await _dio.delete(
      '/deleteMessage',
      data: request.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Sohbeti sil
  Future<ResponseMessage> deleteChat(String token, String chatId) async {
    final response = await _dio.delete(
      '/deleteChat/$chatId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Mesajın kimler tarafından okunduğunu getir
  Future<DataResponseMessage<List<String>>> getReadReceipts(
      String token, String messageId) async {
    final response = await _dio.get(
      '/readReceipts/$messageId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<String>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => item as String).toList(),
    );
  }

  // Kullanıcı durumunu getir
  Future<DataResponseMessage<Map<String, Object>>> getUserStatus(
      String token, String username) async {
    final response = await _dio.get(
      '/userStatus/$username',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<Map<String, Object>>.fromJson(
      response.data,
      (data) => data as Map<String, Object>,
    );
  }

  // Mesaj durumunu güncelle
  Future<ResponseMessage> updateMessageStatus(
      String token, UpdateMessageStatusRequest request) async {
    final response = await _dio.put(
      '/updateMessageStatus',
      data: request.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Sohbeti arşivle
  Future<ResponseMessage> archiveChat(String token, String chatId) async {
    final response = await _dio.put(
      '/archiveChat/$chatId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Sohbeti sabitle
  Future<ResponseMessage> pinChat(String token, String chatId) async {
    final response = await _dio.put(
      '/pinChat/$chatId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Sohbeti sabitlemeyi kaldır
  Future<ResponseMessage> unpinChat(String token, String chatId) async {
    final response = await _dio.delete(
      '/pinChat/$chatId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Sohbeti arşivden çıkar
  Future<ResponseMessage> unarchiveChat(String token, String chatId) async {
    final response = await _dio.delete(
      '/archiveChat/$chatId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }
}
