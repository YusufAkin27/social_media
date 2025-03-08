import 'package:dio/dio.dart';
import 'package:social_media/models/data_response_message.dart'; // Yeni model
import 'package:social_media/models/response_message.dart'; // Yeni model
import 'package:social_media/models/post_dto.dart'; // Yeni model
import 'package:social_media/models/comment_details_dto.dart'; // Yeni model
import 'package:social_media/models/like_details_dto.dart'; // Yeni model

class PostService {
  final Dio _dio;

  // Opsiyonel parametre alacak şekilde düzenlendi
  PostService([Dio? dio]) : _dio = dio ?? Dio(BaseOptions(
    baseUrl: 'http://localhost:8080/v1/api', // Base URL ayarlandı
    contentType: 'application/json',
  ));

  // Yeni post ekleme
  Future<ResponseMessage> addPost(String token, String? description, String? location, List<String>? tagAPerson, List<MultipartFile> mediaFiles) async {
    try {
      FormData formData = FormData.fromMap({
        'description': description,
        'location': location,
        'tagAPerson': tagAPerson,
        'mediaFiles': mediaFiles.map((file) => file).toList(),
      });
      
      final response = await _dio.post(
        '/post', // '/post/add' yerine sadece '/post' endpoint'i kullanılıyor
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: 'multipart/form-data', // Multipart form data olduğunu belirt
        ),
      );
      
      return ResponseMessage.fromJson(response.data);
    } catch (e) {
      print('Post ekleme hatası: $e');
      return ResponseMessage(
        message: 'Gönderi eklenirken bir hata oluştu: $e', 
        isSuccess: false
      );
    }
  }

  // Post silme
  Future<ResponseMessage> deletePost(String token, String postId) async {
    final response = await _dio.delete(
      '/post/$postId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Post güncelleme
  Future<ResponseMessage> updatePost(String token, String postId, String? description, String? location, List<String>? tagAPerson, List<MultipartFile>? photos) async {
    FormData formData = FormData.fromMap({
      'description': description,
      'location': location,
      'tagAPerson': tagAPerson,
      'photos': photos,
    });
    final response = await _dio.put(
      '/post/$postId',
      data: formData,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Post detayları alma
  Future<DataResponseMessage<PostDTO>> getPostDetails(String token, String postId) async {
    final response = await _dio.get(
      '/post/$postId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<PostDTO>.fromJson(
      response.data,
      (data) => PostDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  // Kullanıcının postlarını alma
  Future<DataResponseMessage<List<PostDTO>>> getMyPosts(String token, int page) async {
    try {
      final response = await _dio.get(
        '/post/my-posts',
        queryParameters: {'page': page},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      if (response.data['success'] == true) {
        final List<dynamic> postList = response.data['data'] ?? [];
        try {
          final posts = postList.map((item) => PostDTO.fromJson(item)).toList();
          return DataResponseMessage<List<PostDTO>>(
            message: response.data['message'] ?? 'Başarılı',
            data: posts,
            isSuccess: true,
          );
        } catch (e) {
          print('PostDTO dönüştürme hatası: $e');
          return DataResponseMessage<List<PostDTO>>(
            message: 'Veri dönüştürme hatası: $e',
            data: [],
            isSuccess: false,
          );
        }
      } else {
        return DataResponseMessage<List<PostDTO>>(
          message: response.data['message'] ?? 'Bir hata oluştu',
          data: [],
          isSuccess: false,
        );
      }
    } catch (e) {
      print('PostService getMyPosts error: $e');
      return DataResponseMessage<List<PostDTO>>(
        message: 'Bir hata oluştu: $e',
        data: [],
        isSuccess: false,
      );
    }
  }

  // Kullanıcıya ait postları alma
  Future<DataResponseMessage<List<PostDTO>>> getUserPosts(String token, String username, int page) async {
    final response = await _dio.get(
      '/post/$username/posts',
      queryParameters: {'page': page},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<PostDTO>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => PostDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // Post beğeni sayısını alma
  Future<ResponseMessage> getLikeCount(String token, String postId) async {
    final response = await _dio.get(
      '/post/like-count/$postId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Post yorum sayısını alma
  Future<ResponseMessage> getCommentCount(String token, String postId) async {
    final response = await _dio.get(
      '/post/comment-count/$postId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Post beğeni detayları
  Future<DataResponseMessage<List<LikeDetailsDTO>>> getLikeDetails(String token, String postId, int page) async {
    final response = await _dio.get(
      '/post/like-details/$postId',
      queryParameters: {'page': page},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<LikeDetailsDTO>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => LikeDetailsDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // Post yorum detayları
  Future<DataResponseMessage<List<CommentDetailsDTO>>> getCommentDetails(String token, String postId, int page) async {
    final response = await _dio.get(
      '/post/comment-details/$postId',
      queryParameters: {'page': page},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<CommentDetailsDTO>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => CommentDetailsDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // Arşivlenmiş postları alma
  Future<DataResponseMessage<List<PostDTO>>> getArchivedPosts(String token) async {
    final response = await _dio.get(
      '/post/archivedPosts',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<PostDTO>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => PostDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // Arşivden post silme
  Future<ResponseMessage> deleteArchivedPost(String token, String postId) async {
    final response = await _dio.delete(
      '/post/$postId/archivedPost',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Kaydedilen postları alma
  Future<DataResponseMessage<List<PostDTO>>> getRecordedPosts(String token) async {
    final response = await _dio.get(
      '/post/recorded',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<PostDTO>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => PostDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // Gönderi beğenme
  Future<ResponseMessage> likePost(String token, String postId) async {
    final response = await _dio.post(
      '/post/$postId/like',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Gönderi beğenisini kaldırma
  Future<ResponseMessage> unlikePost(String token, String postId) async {
    final response = await _dio.delete(
      '/post/$postId/unlike',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  Future<DataResponseMessage<List<PostDTO>>> getPopularity(String token) async {
final response = await _dio.get(
  '/post/getPopularity',
  options: Options(headers: {'Authorization': 'Bearer $token'}),
);
return DataResponseMessage<List<PostDTO>>.fromJson(response.data,
(data) => (data as List).map((item) => PostDTO.fromJson(item as Map<String, dynamic>)).toList(),
);
  }

  // Gönderi yorumları alma
  Future<DataResponseMessage<List<CommentDetailsDTO>>> getPostComments(String token, String postId) async {
    final response = await _dio.get(
      '/post/$postId/comments',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<CommentDetailsDTO>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => CommentDetailsDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // Gönderi paylaşma
  Future<ResponseMessage> sharePost(String token, String postId) async {
    final response = await _dio.post(
      '/post/$postId/share',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }
}
