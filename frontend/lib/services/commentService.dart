import 'package:dio/dio.dart';

class CommentService {
  final Dio _dio;

  CommentService(this._dio) {
    _dio.options.baseUrl =
        'http://192.168.89.61:8080/v1/api'; // Base URL ayarlandı
  }

  // Hikayeye yorum yapma
  Future<Response> addCommentToStory(
      String token, String storyId, String content) async {
    final response = await _dio.post(
      '/comments/story/$storyId',
      data: {'content': content},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response;
  }

  // Gönderiye yorum yapma
  Future<Response> addCommentToPost(
      String token, String postId, String content) async {
    try {
      if (content.isEmpty) {
        throw Exception("Comment content cannot be empty");
      }

      final response = await _dio.post(
        '/comments/post/$postId?content=${Uri.encodeComponent(content)}',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return response;
      } else {
        throw Exception(
            "Failed to add comment: ${response.statusCode} - ${response.data}");
      }
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  // Yorum silme
  Future<Response> deleteComment(String token, String commentId) async {
    final response = await _dio.delete(
      '/comments/$commentId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response;
  }

  // Kullanıcının yaptığı yorumları sayfalı olarak listeleme
  Future<Response> getUserComments(String token, int page) async {
    final response = await _dio.get(
      '/comments/user',
      queryParameters: {'page': page},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response;
  }

  // Belirli bir hikayedeki yorumları sayfalı olarak listeleme
  Future<Response> getStoryComments(
      String token, String storyId, int page) async {
    final response = await _dio.get(
      '/comments/story/$storyId',
      queryParameters: {'page': page},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response;
  }

  // Belirli bir gönderideki yorumları sayfalı olarak listeleme
  Future<Response> getPostComments(String token, String postId, int page,
      {int limit = 10}) async {
    final response = await _dio.get(
      '/comments/post/$postId',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response;
  }

  // Belirli bir yorumun detaylarını getirme
  Future<Response> getCommentDetails(String token, String commentId) async {
    final response = await _dio.get(
      '/comments/$commentId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response;
  }

  // Belli bir hikayede kullanıcı yorumu arama
  Future<Response> searchUserInStoryComments(
      String token, String storyId, String username) async {
    final response = await _dio.get(
      '/comments/story/$storyId/search/$username',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response;
  }

  // Belli bir gönderide kullanıcı yorumu arama
  Future<Response> searchUserInPostComments(
      String token, String postId, String username) async {
    final response = await _dio.get(
      '/comments/post/$postId/search/$username',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response;
  }
}
