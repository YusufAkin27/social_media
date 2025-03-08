import 'package:dio/dio.dart';
import 'package:social_media/models/data_response_message.dart';
import 'package:social_media/models/response_message.dart';
import 'package:social_media/models/story_dto.dart';
import 'package:social_media/models/feature_story_dto.dart';
import 'package:social_media/models/story_details.dart';
import 'package:social_media/models/comment_details_dto.dart';
import 'package:social_media/models/search_account_dto.dart';

class StoryService {
  final Dio _dio;

  StoryService(this._dio) {
    _dio.options.baseUrl = 'http://localhost:8080/v1/api'; // Base URL ayarlandı
  }

  // Yeni hikaye ekleme
  Future<ResponseMessage> add(String token, MultipartFile file) async {
    final response = await _dio.post(
      '/story/add',
      data: FormData.fromMap({
        'file': file,
      }),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Mevcut bir hikayeyi silme
  Future<ResponseMessage> delete(String token, String storyId) async {
    final response = await _dio.delete(
      '/story/$storyId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Hikaye öne çıkarma
  Future<ResponseMessage> featureStory(String token, String storyId, String? featuredStoryId) async {
    final response = await _dio.put(
      '/story/$storyId/feature',
      queryParameters: {'featuredStoryId': featuredStoryId},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Hikaye güncelleme
  Future<ResponseMessage> featureUpdate(String token, String featureId, String? title, MultipartFile? file) async {
    final response = await _dio.put(
      '/story/$featureId/update',
      data: FormData.fromMap({
        'title': title,
        'file': file,
      }),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Belirli bir hikaye detaylarını alma
  Future<DataResponseMessage<StoryDetails>> getStoryDetails(String token, String storyId) async {
    final response = await _dio.get(
      '/story/$storyId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<StoryDetails>.fromJson(
      response.data,
      (data) => StoryDetails.fromJson(data as Map<String, dynamic>),
    );
  }

  // Belirli bir öğrencinin öne çıkarılan hikayelerini getir
  Future<DataResponseMessage<List<FeatureStoryDTO>>> getFeaturedStoriesByStudent(String token, int studentId) async {
    final response = await _dio.get(
      '/story/student/$studentId/featured-stories',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<FeatureStoryDTO>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => FeatureStoryDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // Kullanıcının kendi öne çıkarılan hikayelerini getir
  Future<DataResponseMessage<List<FeatureStoryDTO>>> getMyFeaturedStories(String token) async {
    final response = await _dio.get(
      '/story/me/featured-stories',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<FeatureStoryDTO>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => FeatureStoryDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // Tüm hikayeleri sayfalı olarak listeleme
  Future<DataResponseMessage<List<StoryDetails>>> getStories(String token, int page) async {
    final response = await _dio.get(
      '/story/list',
      queryParameters: {'page': page},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<StoryDetails>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => StoryDetails.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // Belirli bir hikayenin toplam görüntülenme sayısı
  Future<ResponseMessage> getStoryViewCount(String token, String storyId) async {
    final response = await _dio.get(
      '/story/$storyId/views',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Popüler hikayeleri getirme
  Future<DataResponseMessage<List<StoryDTO>>> getPopularStories(String token) async {
    final response = await _dio.get(
      '/story/popular',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<StoryDTO>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => StoryDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // Belirli bir hikayeye yapılan yorumları listeleme
  Future<DataResponseMessage<List<CommentDetailsDTO>>> getStoryComments(String token, String storyId) async {
    final response = await _dio.get(
      '/story/$storyId/comments',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<CommentDetailsDTO>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => CommentDetailsDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // Belirli bir hikayeye yapılan görüntüleme işlemi
  Future<ResponseMessage> viewStory(String token, String storyId) async {
    final response = await _dio.post(
      '/story/$storyId/view',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Arşivlenmiş hikayeleri alma
  Future<DataResponseMessage<List<StoryDTO>>> getArchivedStories(String token) async {
    final response = await _dio.get(
      '/story/archivedStories',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<StoryDTO>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => StoryDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // Arşivden hikaye silme
  Future<ResponseMessage> deleteArchived(String token, String storyId) async {
    final response = await _dio.delete(
      '/story/$storyId/archivedStory',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Belirli bir hikayenin süresini uzatma
  Future<ResponseMessage> extendStoryDuration(String token, String storyId, int hours) async {
    final response = await _dio.put(
      '/story/$storyId/extend',
      queryParameters: {'hours': hours},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Belirli bir hikayeyi görüntüleyen kullanıcıların listesi
  Future<DataResponseMessage<List<SearchAccountDTO>>> getStoryViewers(String token, String storyId) async {
    final response = await _dio.get(
      '/story/$storyId/viewers',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<SearchAccountDTO>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => SearchAccountDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // Öne çıkarılan hikaye detaylarını alma
  Future<DataResponseMessage<FeatureStoryDTO>> getFeatureId(String token, String featureId) async {
    final response = await _dio.get(
      '/story/feature/$featureId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<FeatureStoryDTO>.fromJson(
      response.data,
      (data) => FeatureStoryDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  // Belirli bir kullanıcının aktif hikayelerini getirme
  Future<DataResponseMessage<List<StoryDTO>>> getUserActiveStories(String token, int userId) async {
    final response = await _dio.get(
      '/story/user/$userId/active',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<StoryDTO>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => StoryDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // Hikaye beğeni bilgisini alma
  Future<ResponseMessage> getLike(String token, String storyId) async {
    final response = await _dio.get(
      '/story/$storyId/getLike',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }
}
