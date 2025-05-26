import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:social_media/models/follower.dart';

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
  });
}

class FollowerService {
  final String baseUrl;
  
  FollowerService({required this.baseUrl});
  
  Future<ApiResponse<List<Follower>>> getFollowers(String token, int page) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/follow-relations/followers?page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15)); // Timeout set to 15 seconds
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> followersJson = responseData['data'];
          final followers = followersJson
              .map((json) => Follower.fromJson(json as Map<String, dynamic>))
              .toList();
          
          return ApiResponse<List<Follower>>(
            success: true,
            data: followers,
          );
        } else {
          return ApiResponse<List<Follower>>(
            success: false,
            message: responseData['message'] ?? 'Veri alınamadı',
          );
        }
      } else {
        return ApiResponse<List<Follower>>(
          success: false,
          message: 'HTTP Hatası: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse<List<Follower>>(
        success: false,
        message: 'Bağlantı hatası: $e',
      );
    }
  }
  
  Future<ApiResponse<List<Follower>>> searchFollowers(String token, String query, int page) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/follow-relations/followers/search?query=$query&page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> followersJson = responseData['data'];
          final followers = followersJson
              .map((json) => Follower.fromJson(json as Map<String, dynamic>))
              .toList();
          
          return ApiResponse<List<Follower>>(
            success: true,
            data: followers,
          );
        } else {
          return ApiResponse<List<Follower>>(
            success: false,
            message: responseData['message'] ?? 'Arama sonuçları alınamadı',
          );
        }
      } else {
        return ApiResponse<List<Follower>>(
          success: false,
          message: 'HTTP Hatası: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse<List<Follower>>(
        success: false,
        message: 'Bağlantı hatası: $e',
      );
    }
  }
  
  Future<ApiResponse<void>> removeFollower(String token, int followerId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/follow-relations/followers/$followerId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        return ApiResponse<void>(
          success: responseData['success'] == true,
          message: responseData['message'],
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: 'HTTP Hatası: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Bağlantı hatası: $e',
      );
    }
  }
} 