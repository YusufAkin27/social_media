import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:social_media/models/data_response_message.dart'; // Yeni model
import 'package:social_media/models/response_message.dart'; // Yeni model
import 'package:social_media/models/post_dto.dart'; // Yeni model
import 'package:social_media/models/comment_details_dto.dart'; // Yeni model
import 'package:social_media/models/like_details_dto.dart'; // Yeni model
import 'dart:convert';
import 'dart:async';

class PostService {
  final Dio _dio;
  final String baseUrl = 'http://192.168.89.61:8080/v1/api';

  PostService([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'http://192.168.89.61:8080/v1/api',
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            ));

  Future<ResponseMessage> addPost(
      String token,
      String? description,
      String? location,
      List<String>? tagAPerson,
      List<MultipartFile> mediaFiles) async {
    try {
      // HTTP Multipart request kullan (Dio yerine)
      final uri = Uri.parse('$baseUrl/post/add');

      // HTTP MultipartRequest oluştur
      var request = http.MultipartRequest('POST', uri);

      // Token ekle
      request.headers['Authorization'] = 'Bearer $token';

      // Debug için network bilgisini yazdır
      print('Connectivity check:');
      try {
        final testUri = Uri.parse('http://172.20.10.2:8080');
        final testResponse = await http.get(testUri).timeout(
              const Duration(seconds: 5),
              onTimeout: () => http.Response('Timeout', 408),
            );
        print('Test connection status: ${testResponse.statusCode}');
      } catch (e) {
        print('Connection test failed: $e');
      }

      // Diğer alanları ekle
      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }

      if (location != null && location.isNotEmpty) {
        request.fields['location'] = location;
      }

      if (tagAPerson != null && tagAPerson.isNotEmpty) {
        for (var tag in tagAPerson) {
          request.fields['tagAPerson'] = tag;
        }
      }

      // Medya dosyalarını ekle
      for (var dioFile in mediaFiles) {
        // MediaInfo nesnesinden bilgileri çıkar
        final fileName = path.basename(dioFile.filename ?? 'image.jpg');
        final bytes =
            await dioFile.finalize().expand((chunk) => chunk).toList();
        final Uint8List uint8List = Uint8List.fromList(bytes);

        // MIME type belirle
        String contentType = 'image/jpeg'; // Varsayılan
        if (fileName.endsWith('.png')) contentType = 'image/png';
        if (fileName.endsWith('.mp4')) contentType = 'video/mp4';

        // MultipartFile oluştur
        final httpFile = http.MultipartFile.fromBytes(
          'mediaFiles',
          uint8List,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        );

        request.files.add(httpFile);
      }

      // Debug bilgisi
      print('Sending request to: $uri');
      print('Headers: ${request.headers}');
      print('Fields: ${request.fields}');
      print(
          'Files: ${request.files.length} (${request.files.map((f) => f.filename).join(', ')})');

      // İsteği gönder
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          print('Request timeout after 60 seconds');
          throw TimeoutException('Request timed out after 60 seconds');
        },
      );

      // Response'u işle
      final response = await http.Response.fromStream(streamedResponse);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ResponseMessage.fromJson(responseData);
      } else {
        return ResponseMessage(
            message: responseData['message'] ??
                'Gönderi paylaşılamadı: ${response.statusCode}',
            isSuccess: false);
      }
    } on SocketException catch (e) {
      print('SocketException: $e');
      return ResponseMessage(
          message:
              'Sunucuya bağlanılamadı. İnternet bağlantınızı kontrol edin.',
          isSuccess: false);
    } on TimeoutException catch (e) {
      print('TimeoutException: $e');
      return ResponseMessage(
          message: 'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.',
          isSuccess: false);
    } on FormatException catch (e) {
      print('FormatException: $e');
      return ResponseMessage(
          message: 'Sunucu yanıtı işlenemedi. Geliştirici ile iletişime geçin.',
          isSuccess: false);
    } catch (e) {
      print('Unexpected error: $e');
      print('Error details: ${e.toString()}');
      print('Error runtimeType: ${e.runtimeType}');

      return ResponseMessage(
          message:
              'Gönderi paylaşılırken bir hata oluştu. Lütfen daha sonra tekrar deneyin.',
          isSuccess: false);
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
  Future<ResponseMessage> updatePost(
      String token,
      String postId,
      String? description,
      String? location,
      List<String>? tagAPerson,
      List<MultipartFile>? photos) async {
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
  Future<DataResponseMessage<PostDTO>> getPostDetails(
      String token, String postId) async {
    try {
      // Yeni API endpoint'i kullanarak gönderi detaylarını al
      final response = await _dio.get(
        '/post/details/$postId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status! < 500,
        ),
      );

      print('Post details response: ${response.statusCode}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        return DataResponseMessage<PostDTO>(
          message: response.data['message'] ??
              'Gönderi detayları başarıyla getirildi.',
          data: PostDTO.fromJson(data),
          isSuccess: true,
        );
      } else {
        return DataResponseMessage<PostDTO>(
          message: response.data['message'] ?? 'Gönderi detayları alınamadı.',
          data: null,
          isSuccess: false,
        );
      }
    } catch (e) {
      print('Post details error: $e');
      return DataResponseMessage<PostDTO>(
        message: 'Bir hata oluştu: $e',
        data: null,
        isSuccess: false,
      );
    }
  }

  // Kullanıcının postlarını alma
  Future<DataResponseMessage<List<PostDTO>>> getMyPosts(
      String token, int page) async {
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
  Future<DataResponseMessage<List<PostDTO>>> getUserPosts(
      String token, String username, int page) async {
    final response = await _dio.get(
      '/post/$username/posts',
      queryParameters: {'page': page},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<PostDTO>>.fromJson(
      response.data,
      (data) => (data as List)
          .map((item) => PostDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
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
  Future<DataResponseMessage<List<LikeDetailsDTO>>> getLikeDetails(
      String token, String postId, int page) async {
    final response = await _dio.get(
      '/post/like-details/$postId',
      queryParameters: {'page': page},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<LikeDetailsDTO>>.fromJson(
      response.data,
      (data) => (data as List)
          .map((item) => LikeDetailsDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  // Post yorum detayları
  Future<DataResponseMessage<List<CommentDetailsDTO>>> getCommentDetails(
      String token, String postId, int page) async {
    final response = await _dio.get(
      '/post/comment-details/$postId',
      queryParameters: {'page': page},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<CommentDetailsDTO>>.fromJson(
      response.data,
      (data) => (data as List)
          .map((item) =>
              CommentDetailsDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  // Arşivlenmiş postları alma
  Future<DataResponseMessage<List<PostDTO>>> getArchivedPosts(
      String token) async {
    final response = await _dio.get(
      '/post/archivedPosts',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<PostDTO>>.fromJson(
      response.data,
      (data) => (data as List)
          .map((item) => PostDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  // Arşivden post silme
  Future<ResponseMessage> deleteArchivedPost(
      String token, String postId) async {
    final response = await _dio.delete(
      '/post/$postId/archivedPost',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Kaydedilen postları alma
  Future<DataResponseMessage<List<PostDTO>>> getRecordedPosts(
      String token) async {
    final response = await _dio.get(
      '/post/recorded',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<PostDTO>>.fromJson(
      response.data,
      (data) => (data as List)
          .map((item) => PostDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
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
    try {
      print('PostService: Fetching popular posts...');
      final response = await _dio.get(
        '/post/getPopularity',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status != null && status < 500,
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      print(
          'PostService: Response received with status: ${response.statusCode}');

      if (response.statusCode != 200) {
        print('getPopularity failed with status: ${response.statusCode}');
        return DataResponseMessage<List<PostDTO>>(
          message: 'Sunucu hatası: ${response.statusCode}',
          data: [],
          isSuccess: false,
        );
      }

      // Validate that data is actually a list
      if (response.data['data'] == null) {
        print('PostService: Response data is null');
        return DataResponseMessage<List<PostDTO>>(
          message: 'Veri alınamadı',
          data: [],
          isSuccess: false,
        );
      }

      if (!(response.data['data'] is List)) {
        print(
            'PostService: Response data is not a list, it is: ${response.data['data'].runtimeType}');
        return DataResponseMessage<List<PostDTO>>(
          message: 'Veri formatı uyumsuz',
          data: [],
          isSuccess: false,
        );
      }

      try {
        return DataResponseMessage<List<PostDTO>>.fromJson(
          response.data,
          (data) => (data as List)
              .map((item) => PostDTO.fromJson(item as Map<String, dynamic>))
              .toList(),
        );
      } catch (e) {
        print('PostService: Error parsing response data: $e');
        return DataResponseMessage<List<PostDTO>>(
          message: 'Veri işlenirken hata oluştu: $e',
          data: [],
          isSuccess: false,
        );
      }
    } catch (e) {
      print('Error in getPopularity: $e');
      return DataResponseMessage<List<PostDTO>>(
        message: 'Popüler gönderiler alınırken hata oluştu: $e',
        data: [],
        isSuccess: false,
      );
    }
  }

  // Gönderi yorumları alma
  Future<DataResponseMessage<List<CommentDetailsDTO>>> getPostComments(
      String token, String postId) async {
    final response = await _dio.get(
      '/post/$postId/comments',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<CommentDetailsDTO>>.fromJson(
      response.data,
      (data) => (data as List)
          .map((item) =>
              CommentDetailsDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
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
