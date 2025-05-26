import 'package:dio/dio.dart';
import 'package:social_media/models/data_response_message.dart';
import 'package:social_media/models/response_message.dart';
import 'package:social_media/models/story_dto.dart';
import 'package:social_media/models/post_dto.dart';
import 'package:social_media/models/search_account_dto.dart';

class LikeService {
  final Dio _dio;
  final String _baseUrl = 'http://192.168.89.61:8080/v1/api/likes';

  // Constructor'da Dio alabilecek şekilde düzenle
  LikeService([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: Duration(seconds: 30),
              receiveTimeout: Duration(seconds: 30),
              sendTimeout: Duration(seconds: 30),
              validateStatus: (status) {
                return status != null && status < 500;
              },
            )) {
    // Initialize interceptors in constructor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) {
          print('LikeService - Dio error: ${error.type} - ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  // Gönderiyi beğenme
  Future<ResponseMessage> likePost(String token, String postId) async {
    try {
      final response = await _dio.post(
        'http://172.20.10.2:8080/v1/api/likes/post/$postId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Beğeni başarılı: ${response.statusCode}');
        return ResponseMessage.fromJson(response.data);
      } else {
        print('Beğeni hatası: ${response.statusCode} - ${response.data}');
        return ResponseMessage(
          message: 'Beğeni işlemi başarısız: ${response.statusCode}',
          isSuccess: false,
        );
      }
    } catch (e) {
      print('LikePost exception: $e');
      return ResponseMessage(
        message: 'Beğeni işlemi sırasında hata: $e',
        isSuccess: false,
      );
    }
  }

  // Gönderi beğenisini kaldırma (Unlike)
  Future<ResponseMessage> unlikePost(String token, String postId) async {
    try {
      final response = await _dio.delete(
        'http://172.20.10.2:8080/v1/api/likes/post/$postId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        print('Beğeni kaldırma başarılı: ${response.statusCode}');
        return ResponseMessage.fromJson(response.data);
      } else {
        print(
            'Beğeni kaldırma hatası: ${response.statusCode} - ${response.data}');
        return ResponseMessage(
          message: 'Beğeni kaldırma işlemi başarısız: ${response.statusCode}',
          isSuccess: false,
        );
      }
    } catch (e) {
      print('UnlikePost exception: $e');
      return ResponseMessage(
        message: 'Beğeni kaldırma işlemi sırasında hata: $e',
        isSuccess: false,
      );
    }
  }

  // Beğeni durumunu kontrol et
  Future<bool> checkPostLike(String token, String postId) async {
    try {
      final response = await _dio.get(
        'http://172.20.10.2:8080/v1/api/likes/posts/$postId/check',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final bool isLiked = response.data['liked'] ?? false;
        print('Beğeni durumu: $isLiked');
        return isLiked;
      } else {
        print('Beğeni durumu kontrol hatası: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('CheckPostLike exception: $e');
      return false;
    }
  }

  // Post beğenme/beğeni kaldırma (Toggle)
  Future<ResponseMessage> toggleLike(String token, String postId) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/post/$postId/toggle',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        print('Beğeni toggle başarılı: ${response.statusCode}');
        return ResponseMessage.fromJson(response.data);
      } else {
        print(
            'Beğeni toggle hatası: ${response.statusCode} - ${response.data}');
        return ResponseMessage(
          message: 'Beğeni değiştirme işlemi başarısız: ${response.statusCode}',
          isSuccess: false,
        );
      }
    } catch (e) {
      print('ToggleLike exception: $e');
      return ResponseMessage(
        message: 'Beğeni değiştirme işlemi sırasında hata: $e',
        isSuccess: false,
      );
    }
  }

  // Beğendiği gönderileri listele
  Future<DataResponseMessage<List<PostDTO>>> getUserLikedPosts(String token,
      {int page = 0, int size = 10}) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/posts',
        queryParameters: {'page': page, 'size': size},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
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
          message: response.data['message'] ??
              'Bir hata oluştu: ${response.statusCode}',
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

  // Hikayeyi beğenme (ihtiyaç olursa kullanılacak)
  Future<ResponseMessage> likeStory(String token, String storyId) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/story/$storyId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ResponseMessage.fromJson(response.data);
      } else {
        return ResponseMessage(
          message: 'Hikaye beğeni işlemi başarısız: ${response.statusCode}',
          isSuccess: false,
        );
      }
    } catch (e) {
      return ResponseMessage(
        message: 'Hikaye beğeni işlemi sırasında hata: $e',
        isSuccess: false,
      );
    }
  }

  // Hikaye beğenisini kaldırma (ihtiyaç olursa kullanılacak)
  Future<ResponseMessage> unlikeStory(String token, String storyId) async {
    try {
      final response = await _dio.delete(
        '$_baseUrl/story/$storyId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        return ResponseMessage.fromJson(response.data);
      } else {
        return ResponseMessage(
          message:
              'Hikaye beğeni kaldırma işlemi başarısız: ${response.statusCode}',
          isSuccess: false,
        );
      }
    } catch (e) {
      return ResponseMessage(
        message: 'Hikaye beğeni kaldırma işlemi sırasında hata: $e',
        isSuccess: false,
      );
    }
  }

  // Beğendiği hikayeleri listele
  Future<DataResponseMessage<List<StoryDTO>>> getUserLikedStories(
      String token) async {
    final response = await _dio.get(
      '$_baseUrl/stories',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        validateStatus: (status) => status! < 500,
      ),
    );
    return DataResponseMessage<List<StoryDTO>>.fromJson(
      response.data,
      (data) => (data as List)
          .map((item) => StoryDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  // Belirtilen hikayede belirli bir kullanıcının beğenisini arama
  Future<DataResponseMessage<SearchAccountDTO>> searchUserInStoryLikes(
      String token, String storyId, String username) async {
    final response = await _dio.get(
      '$_baseUrl/story/$storyId/search/$username',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        validateStatus: (status) => status! < 500,
      ),
    );
    return DataResponseMessage<SearchAccountDTO>.fromJson(
      response.data,
      (data) => SearchAccountDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  // Belirtilen gönderide belirli bir kullanıcının beğenisini arama
  Future<DataResponseMessage<SearchAccountDTO>> searchUserInPostLikes(
      String token, String postId, String username) async {
    final response = await _dio.get(
      '$_baseUrl/post/$postId/search/$username',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        validateStatus: (status) => status! < 500,
      ),
    );
    return DataResponseMessage<SearchAccountDTO>.fromJson(
      response.data,
      (data) => SearchAccountDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  // Belirli bir tarihten sonra gönderiye yapılan beğenileri getir
  Future<DataResponseMessage<List<PostDTO>>> getPostLikesAfter(
      String token, String postId, String dateTime) async {
    final response = await _dio.get(
      '$_baseUrl/post/$postId/likes-after/$dateTime',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        validateStatus: (status) => status! < 500,
      ),
    );
    return DataResponseMessage<List<PostDTO>>.fromJson(
      response.data,
      (data) => (data as List)
          .map((item) => PostDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
