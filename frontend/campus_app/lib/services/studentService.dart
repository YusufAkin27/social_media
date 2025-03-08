import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:social_media/models/data_response_message.dart';
import 'package:social_media/models/response_message.dart';
import 'package:social_media/models/student_dto.dart';
import 'package:social_media/models/create_student_request.dart';
import 'package:social_media/models/update_student_profile_request.dart';
import 'package:social_media/models/public_account_details.dart';
import 'package:social_media/models/best_popularity_account.dart';
import 'package:social_media/models/home_story_dto.dart';
import 'package:social_media/models/search_account_dto.dart';
import 'package:social_media/models/post_dto.dart';
import 'package:social_media/models/private_account_details.dart';

class StudentService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:8080/v1/api/student', // Backend URL'ini güncelle
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  // Öğrenci kayıt olma
  Future<ResponseMessage> signUp(CreateStudentRequest model) async {
    try {
      final response = await _dio.post(
        '/sign-up',
        data: jsonEncode(model.toJson()), // Modelin toJson() metodunu çağırarak veri gönderiyoruz
      );

      if (response.statusCode == 200 && response.data != null) {
        try {
          return ResponseMessage.fromJson(response.data);
        } catch (jsonError) {
          print('JSON dönüşüm hatası: $jsonError');
          return ResponseMessage(
            message: 'Sunucu yanıtı işlenirken bir hata oluştu',
            isSuccess: false
          );
        }
      } else {
        return ResponseMessage(
          message: 'İşlem başarısız oldu. Lütfen daha sonra tekrar deneyin',
          isSuccess: false
        );
      }
    } catch (e) {
      print('StudentService signUp hatası: $e');
      return ResponseMessage(
        message: 'Bağlantı hatası: ${e.toString().split(":").first}',
        isSuccess: false
      );
    }
  }

  // Öğrenci aktif etme
  Future<ResponseMessage> active(String token) async {
    final response = await _dio.put('/active', options: Options(
      headers: {
        'Authorization': 'Bearer $token', // Burada gelen token'ı kullanıyoruz
      },
    ));
    return ResponseMessage.fromJson(response.data);
  }

  // Şifre sıfırlama
  Future<ResponseMessage> resetPassword(String token, String newPassword) async {
    final response = await _dio.put('/reset-password', queryParameters: {
      'token': token,
      'newPassword': newPassword,
    });
    return ResponseMessage.fromJson(response.data);
  }

  // Öğrenci profil bilgilerini getirme
  Future<DataResponseMessage<StudentDTO>> getStudentProfile(String token) async {
    final response = await _dio.get(
      '/profile',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token', // Burada gelen token'ı kullanıyoruz
        },
      ),
    );
    return DataResponseMessage<StudentDTO>.fromJson(
      response.data,
      (data) => StudentDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  // Profil bilgilerini güncelleme
  Future<ResponseMessage> updateStudentProfile(String token, dynamic model) async {
    final response = await _dio.put(
      '/profile',
      data: model is UpdateStudentProfileRequest ? jsonEncode(model.toJson()) : jsonEncode(model),
      options: Options(
        headers: {
          'Authorization': 'Bearer $token', // Burada gelen token'ı kullanıyoruz
        },
      ),
    );
    return ResponseMessage.fromJson(response.data);
  }

  // Profil fotoğrafı yükleme
  Future<ResponseMessage> uploadPhoto(String token, MultipartFile photo) async {
    final formData = FormData.fromMap({
      'file': photo,
    });
    final response = await _dio.post('/profile-photo', data: formData, options: Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    ));
    return ResponseMessage.fromJson(response.data);
  }

  // Öğrenci hesap silme
  Future<ResponseMessage> deleteStudent(String token) async {
    final response = await _dio.delete('/delete', options: Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    ));
    return ResponseMessage.fromJson(response.data);
  }

  // Öğrenci şifresini güncelleme
  Future<ResponseMessage> updatePassword(String token, String newPassword) async {
    final response = await _dio.put('/update-password', queryParameters: {
      'newPassword': newPassword,
    }, options: Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    ));
    return ResponseMessage.fromJson(response.data);
  }

  // FCM token güncelleme
  Future<ResponseMessage> updateFcmToken(String token, String fcmToken) async {
    final response = await _dio.put('/updateFcmToken', queryParameters: {
      'fcmToken': fcmToken,
    }, options: Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    ));
    return ResponseMessage.fromJson(response.data);
  }

  // Profil fotoğrafını silme
  Future<ResponseMessage> deleteProfilePhoto(String token) async {
    final response = await _dio.delete('/profile-photo', options: Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    ));
    return ResponseMessage.fromJson(response.data);
  }

  // Profil gizlilik durumunu değiştirme
  Future<ResponseMessage> changePrivate(String token, bool isPrivate) async {
    final response = await _dio.put('/change-private', queryParameters: {
      'isPrivate': isPrivate,
    }, options: Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    ));
    return ResponseMessage.fromJson(response.data);
  }

  // Öğrenci arama
  Future<DataResponseMessage<List<SearchAccountDTO>>> search(String token, String query, int page) async {
    final response = await _dio.get('/search', queryParameters: {
      'query': query,
      'page': page,
    }, options: Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    ));
    return DataResponseMessage<List<SearchAccountDTO>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => SearchAccountDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // Hesap detaylarını alma
  Future<DataResponseMessage<dynamic>> accountDetails(String token, int userId) async {
    final response = await _dio.get('/account-details/$userId', options: Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    ));

    // Assuming the response contains a field that indicates if the account is private
    final isPrivate = response.data['isPrivate']; // Adjust this based on your actual response structure
    final isFollowing = response.data['isFollowing']; // Adjust this based on your actual response structure

    if (isPrivate && !isFollowing) {
        // Return private account details
        final privateDetails = PrivateAccountDetails.fromJson(response.data);
        return DataResponseMessage<PrivateAccountDetails>.fromJson(
          response.data,
          (data) => privateDetails,
        );
    } else {
        // Return public account details
        final publicDetails = PublicAccountDetails.fromJson(response.data);
        return DataResponseMessage<PublicAccountDetails>.fromJson(
          response.data,
          (data) => publicDetails,
        );
    }
  }

  // Bölüme göre öğrencileri alma
  Future<DataResponseMessage<List<PublicAccountDetails>>> getStudentsByDepartment(String token, String department, int page) async {
    final response = await _dio.get('/students-by-department', queryParameters: {
      'department': department,
      'page': page,
    }, options: Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    ));
    return DataResponseMessage<List<PublicAccountDetails>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => PublicAccountDetails.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // Fakülteye göre öğrencileri alma
  Future<DataResponseMessage<List<PublicAccountDetails>>> getStudentsByFaculty(String token, String faculty, int page) async {
    final response = await _dio.get('/students-by-faculty', queryParameters: {
      'faculty': faculty,
      'page': page,
    }, options: Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    ));
    return DataResponseMessage<List<PublicAccountDetails>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => PublicAccountDetails.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // Sınıfa göre öğrencileri alma
  Future<DataResponseMessage<List<PublicAccountDetails>>> getStudentsByGrade(String token, String grade, int page) async {
    final response = await _dio.get('/students-by-grade', queryParameters: {
      'grade': grade,
      'page': page,
    }, options: Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    ));
    return DataResponseMessage<List<PublicAccountDetails>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => PublicAccountDetails.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // En iyi popülerlikteki öğrencileri alma
  Future<DataResponseMessage<List<BestPopularityAccount>>> getBestPopularity(String token) async {
    final response = await _dio.get('/best-popularity', options: Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    ));
    return DataResponseMessage<List<BestPopularityAccount>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => BestPopularityAccount.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // Ana sayfadaki postları alma
  Future<DataResponseMessage<List<PostDTO>>> getHomePosts(String token, int page) async {
    final response = await _dio.get('/home/posts', queryParameters: {
      'page': page,
    }, options: Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    ));
    return DataResponseMessage<List<PostDTO>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => PostDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // Ana sayfadaki hikayeleri alma
  Future<DataResponseMessage<List<HomeStoryDTO>>> getHomeStories(String token, int page) async {
    final response = await _dio.get('/home/stories', queryParameters: {
      'page': page,
    }, options: Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    ));
    return DataResponseMessage<List<HomeStoryDTO>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => HomeStoryDTO.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  // Önerilen bağlantıları alma
  Future<DataResponseMessage<List<String>>> getSuggestedConnections(String token) async {
    final response = await _dio.get('/suggested-connections', options: Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    ));
    return DataResponseMessage<List<String>>.fromJson(
      response.data,
      (data) => (data as List).map((item) => item as String).toList(),
    );
  }

  // Profil bilgilerini alma
  Future<DataResponseMessage<StudentDTO>> getProfile(String token) async {
    try {
      final response = await _dio.get('/profile', 
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data['success'] == true) {
        final studentData = response.data['data'];
        try {
          final student = StudentDTO.fromJson(studentData);
          return DataResponseMessage<StudentDTO>(
            message: response.data['message'] ?? 'Başarılı',
            data: student,
            isSuccess: true,
          );
        } catch (e) {
          print('StudentDTO dönüştürme hatası: $e');
          return DataResponseMessage<StudentDTO>(
            message: 'Veri dönüştürme hatası: $e',
            data: null,
            isSuccess: false,
          );
        }
      } else {
        return DataResponseMessage<StudentDTO>(
          message: response.data['message'] ?? 'Bir hata oluştu',
          data: null,
          isSuccess: false,
        );
      }
    } catch (e) {
      print('StudentService getProfile error: $e');
      return DataResponseMessage<StudentDTO>(
        message: 'Bir hata oluştu: $e',
        data: null,
        isSuccess: false,
      );
    }
  }

  Future<ResponseMessage> forgotPassword(String username) async {
    try {
      final response = await _dio.post('/forgot-password/$username');
      return ResponseMessage.fromJson(response.data);
    } catch (e) {
      print('Error in forgotPassword: $e');
      throw Exception('Failed to send forgot password request');
    }
  }
}