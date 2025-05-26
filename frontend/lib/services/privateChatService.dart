import 'package:dio/dio.dart';

class PrivateChatService {
  final Dio _dio;

  PrivateChatService(this._dio) {
    _dio.options.baseUrl =
        'http://192.168.89.61:8080/v1/api'; // Base URL ayarlandı
  }

  // Yeni özel sohbet oluştur
  Future<Response> createChat(String token, String username) async {
    final response = await _dio.post(
      '/privateChat/createChat/$username',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response;
  }

  // Mesaj gönder
  Future<Response> sendPrivateMessage(
      String token, dynamic sendMessageRequest) async {
    final response = await _dio.post(
      '/privateChat/send',
      data: sendMessageRequest.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response;
  }

  // Mesaj gönder (dosya ile)
  Future<Response> sendPrivateMessageFiles(String token,
      dynamic sendMessageRequest, List<MultipartFile> files) async {
    final formData = FormData.fromMap({
      'message': sendMessageRequest.toJson(),
      'files': files,
    });

    final response = await _dio.post(
      '/privateChat/send/files',
      data: formData,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response;
  }

  // Kullanıcının sohbetlerini getir
  Future<Response> getChats(String token) async {
    final response = await _dio.get(
      '/privateChat/getChats',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response;
  }

  // Belirli bir sohbetin mesajlarını getir
  Future<Response> getMessages(String token, String chatId) async {
    final response = await _dio.get(
      '/privateChat/getMessages/$chatId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response;
  }

  // Mesajı düzenle
  Future<Response> editMessage(String token, dynamic editMessageRequest) async {
    final response = await _dio.put(
      '/privateChat/editMessage',
      data: editMessageRequest.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response;
  }

  // Mesajı sil
  Future<Response> deleteMessage(
      String token, dynamic deleteMessageRequest) async {
    final response = await _dio.delete(
      '/privateChat/deleteMessage',
      data: deleteMessageRequest.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response;
  }

  // Sohbeti sil
  Future<Response> deleteChat(String token, String chatId) async {
    final response = await _dio.delete(
      '/privateChat/deleteChat/$chatId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response;
  }

  // Mesajın kimler tarafından okunduğunu getir
  Future<Response> getReadReceipts(String token, String messageId) async {
    final response = await _dio.get(
      '/privateChat/readReceipts/$messageId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response;
  }

  // Kullanıcı durumunu getir
  Future<Response> getUserStatus(String token, String username) async {
    final response = await _dio.get(
      '/privateChat/userStatus/$username',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response;
  }

  // Mesaj durumunu güncelle
  Future<Response> updateMessageStatus(
      String token, dynamic updateMessageStatusRequest) async {
    final response = await _dio.put(
      '/privateChat/updateMessageStatus',
      data: updateMessageStatusRequest.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response;
  }

  // Sohbeti arşivle
  Future<Response> archiveChat(String token, String chatId) async {
    final response = await _dio.put(
      '/privateChat/archiveChat/$chatId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response;
  }

  // Sohbeti sabitle
  Future<Response> pinChat(String token, String chatId) async {
    final response = await _dio.put(
      '/privateChat/pinChat/$chatId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response;
  }

  // Sohbeti sabitlemeyi kaldır
  Future<Response> unpinChat(String token, String chatId) async {
    final response = await _dio.delete(
      '/privateChat/pinChat/$chatId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response;
  }

  // Sohbeti arşivden çıkar
  Future<Response> unarchiveChat(String token, String chatId) async {
    final response = await _dio.delete(
      '/privateChat/archiveChat/$chatId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response;
  }
}
