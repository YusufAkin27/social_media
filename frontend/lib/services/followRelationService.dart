import 'package:dio/dio.dart';
import 'package:social_media/models/followed_user_dto.dart';
import 'package:social_media/models/data_response_message.dart';
import 'package:social_media/models/response_message.dart';
import 'package:social_media/models/search_account_dto.dart';
import 'package:social_media/models/post_dto.dart';

class FollowRelationService {
  final Dio _dio;

  FollowRelationService(this._dio) {
    _dio.options.baseUrl =
        'http://192.168.89.61:8080/v1/api'; // Base URL ayarlandı
  }

  // Kullanıcının takip ettiği kişileri sayfalı şekilde al
  Future<DataResponseMessage<List<FollowedUserDTO>>> getFollowing(
      String token, int page) async {
    final response = await _dio.get(
      '/follow-relations/following',
      queryParameters: {'page': page},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<FollowedUserDTO>>.fromJson(
      response.data,
      (data) => (data as List)
          .map((item) => FollowedUserDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  // Kullanıcıyı takip eden kişileri sayfalı şekilde al
  Future<DataResponseMessage<List<FollowedUserDTO>>> getFollowers(
      String token, int page) async {
    final response = await _dio.get(
      '/follow-relations/followers',
      queryParameters: {'page': page},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<FollowedUserDTO>>.fromJson(
      response.data,
      (data) => (data as List)
          .map((item) => FollowedUserDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  // Takip edilen birini sil
  Future<ResponseMessage> removeFollowing(String token, int userId) async {
    final response = await _dio.delete(
      '/follow-relations/following/$userId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Takipçi birini sil
  Future<ResponseMessage> removeFollower(String token, int userId) async {
    final response = await _dio.delete(
      '/follow-relations/followers/$userId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Takipçi arama (Kullanıcı adı veya isimle) sayfalama ile
  Future<DataResponseMessage<List<FollowedUserDTO>>> searchFollowers(
      String token, String query, int page) async {
    final response = await _dio.get(
      '/follow-relations/followers/search',
      queryParameters: {'query': query, 'page': page},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<FollowedUserDTO>>.fromJson(
      response.data,
      (data) => (data as List)
          .map((item) => FollowedUserDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  // Takip edilen kişiler arasında arama (Kullanıcı adı veya isimle) sayfalama ile
  Future<DataResponseMessage<List<FollowedUserDTO>>> searchFollowing(
      String token, String query, int page) async {
    final response = await _dio.get(
      '/follow-relations/following/search',
      queryParameters: {'query': query, 'page': page},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<FollowedUserDTO>>.fromJson(
      response.data,
      (data) => (data as List)
          .map((item) => FollowedUserDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  // Kullanıcının takipçi sayısını ve takip edilen kişi sayısını göster
  Future<ResponseMessage> getFollowersCount(String token) async {
    final response = await _dio.get(
      '/follow-relations/followers-count',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  Future<ResponseMessage> getFollowingCount(String token) async {
    final response = await _dio.get(
      '/follow-relations/following-count',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Ortak takipçileri göster (Hem takipçi hem takip edilen)
  Future<DataResponseMessage<List<String>>> getCommonFollowers(
      String token, String username) async {
    final response = await _dio.get(
      '/follow-relations/common-followers/$username',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<String>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => item as String).toList(),
    );
  }

  // Takip edilen veya takipçi kişilerin paylaşımlarını göster
  Future<DataResponseMessage<List<PostDTO>>> getFollowingPosts(
      String token, String username) async {
    final response = await _dio.get(
      '/follow-relations/following/$username/posts',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<PostDTO>>.fromJson(
      response.data,
      (data) => (data as List)
          .map((item) => PostDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  // Herhangi bir kullanıcının takipçi listesi
  Future<DataResponseMessage<List<SearchAccountDTO>>> getFollowersByUsername(
      String token, String username) async {
    final response = await _dio.get(
      '/follow-relations/followers/$username',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<SearchAccountDTO>>.fromJson(
      response.data,
      (data) => (data as List)
          .map(
              (item) => SearchAccountDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  // Herhangi bir kullanıcının takip ettiği kullanıcılar listesi
  Future<DataResponseMessage<List<SearchAccountDTO>>> getFollowingByUsername(
      String token, String username) async {
    final response = await _dio.get(
      '/follow-relations/following/$username',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<SearchAccountDTO>>.fromJson(
      response.data,
      (data) => (data as List)
          .map(
              (item) => SearchAccountDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  // Takipçi listesinde arama yapma
  Future<DataResponseMessage<List<SearchAccountDTO>>> searchInFollowers(
      String token, String username, String query) async {
    final response = await _dio.get(
      '/follow-relations/followers/search/$username',
      queryParameters: {'query': query},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<SearchAccountDTO>>.fromJson(
      response.data,
      (data) => (data as List)
          .map(
              (item) => SearchAccountDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  // Takip edilenler listesinde arama yapma
  Future<DataResponseMessage<List<SearchAccountDTO>>> searchInFollowing(
      String token, String username, String query) async {
    final response = await _dio.get(
      '/follow-relations/following/search/$username',
      queryParameters: {'query': query},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return DataResponseMessage<List<SearchAccountDTO>>.fromJson(
      response.data,
      (data) => (data as List)
          .map(
              (item) => SearchAccountDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
