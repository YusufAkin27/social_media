import 'package:dio/dio.dart';
import 'package:social_media/models/data_response_message.dart';
import 'package:social_media/models/response_message.dart';
import 'package:social_media/models/story_dto.dart';
import 'package:social_media/models/post_dto.dart';
import 'package:social_media/models/search_account_dto.dart';

class LikeService {
  late Dio _dio;
  
  // Constructor'da Dio alabilecek şekilde düzenle
  LikeService([Dio? dio]) {
    if (dio != null) {
      _dio = dio;
    } else {
      // Dio verilmezse boş bir instance oluştur, initDio() ile güncellenecek
      _dio = Dio();
    }
  }
  
  // Service'i kullanmadan önce çağrılmalı
  Future<void> initDio(String token) async {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
  
  // Hikayeyi beğenme
  Future<ResponseMessage> likeStory(String token, String storyId) async {
    await initDio(token);
    final response = await _dio.post(
      '/likes/story/$storyId',
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Gönderiyi beğenme
  Future<ResponseMessage> likePost(String token, String postId) async {
    await initDio(token);
    final response = await _dio.post(
      '/likes/post/$postId',
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Hikaye beğenisini kaldırma (Unlike)
  Future<ResponseMessage> unlikeStory(String token, String storyId) async {
    await initDio(token);
    final response = await _dio.delete(
      '/likes/story/$storyId',
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Gönderi beğenisini kaldırma (Unlike)
  Future<ResponseMessage> unlikePost(String token, String postId) async {
    await initDio(token);
    final response = await _dio.delete(
      '/likes/post/$postId',
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Beğendiği hikayeleri listele
  Future<DataResponseMessage<List<StoryDTO>>> getUserLikedStories(String token) async {
    await initDio(token);
    final response = await _dio.get(
      '/likes/stories',
    );
    return DataResponseMessage<List<StoryDTO>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => StoryDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // Beğendiği gönderileri listele
  Future<DataResponseMessage<List<PostDTO>>> getUserLikedPosts(String token, {int page = 0, int size = 10}) async {
    try {
      await initDio(token);
      final response = await _dio.get(
        '/likes/posts',
        queryParameters: {
          'page': page,
          'size': size
        },
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
      print('LikeService getUserLikedPosts error: $e');
      return DataResponseMessage<List<PostDTO>>(
        message: 'Bir hata oluştu: $e',
        data: [],
        isSuccess: false,
      );
    }
  }

  // Belirli bir tarihten sonra gönderiye yapılan beğenileri getir
  Future<DataResponseMessage<List<PostDTO>>> getPostLikesAfter(String token, String postId, String dateTime) async {
    await initDio(token);
    final response = await _dio.get(
      '/likes/post/$postId/likes-after/$dateTime',
    );
    return DataResponseMessage<List<PostDTO>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => PostDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // Belirtilen hikayede belirli bir kullanıcının beğenisini arama
  Future<DataResponseMessage<SearchAccountDTO>> searchUserInStoryLikes(String token, String storyId, String username) async {
    await initDio(token);
    final response = await _dio.get(
      '/likes/story/$storyId/search/$username',
    );
    return DataResponseMessage<SearchAccountDTO>.fromJson(
      response.data,
      (data) => SearchAccountDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  // Belirtilen gönderide belirli bir kullanıcının beğenisini arama
  Future<DataResponseMessage<SearchAccountDTO>> searchUserInPostLikes(String token, String postId, String username) async {
    await initDio(token);
    final response = await _dio.get(
      '/likes/post/$postId/search/$username',
    );
    return DataResponseMessage<SearchAccountDTO>.fromJson(
      response.data,
      (data) => SearchAccountDTO.fromJson(data as Map<String, dynamic>),
    );
  }
  
  Future<bool> checkPostLike(String token, String postId) async {
    await initDio(token);
    final response = await _dio.get(
      '/likes/post/$postId/check',
    );
    return response.data['liked'] as bool;
  }
  
  // Post beğenme/beğeni kaldırma
  Future<ResponseMessage> toggleLike(String token, String postId) async {
    await initDio(token);
    final response = await _dio.post(
      '/likes/post/$postId/toggle',
    );
    return ResponseMessage.fromJson(response.data);
  }



}
