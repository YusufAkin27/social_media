import 'dart:convert';
import 'dart:math';
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
import 'package:social_media/models/suggest_user_request.dart';

class StudentService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl:
          'http://192.168.89.61:8080/v1/api/student', // Backend URL'ini güncelle
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
      validateStatus: (status) {
        return status != null && status < 500;
      },
    ),
  );

  // Constructor to initialize interceptors
  StudentService() {
    _dio.options.baseUrl = 'http://192.168.89.61:8080/v1/api/student';
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
    _dio.options.sendTimeout = const Duration(seconds: 60);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) {
          print('StudentService - Dio error: ${error.type} - ${error.message}');
          // Continue with the error
          return handler.next(error);
        },
        onRequest: (options, handler) {
          print('StudentService - Request to: ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
              'StudentService - Response from: ${response.requestOptions.path} - Status: ${response.statusCode}');
          return handler.next(response);
        },
      ),
    );
  }

  // Öğrenci kayıt olma
  Future<ResponseMessage> signUp(CreateStudentRequest model) async {
    try {
      final response = await _dio.post(
        '/sign-up',
        data: jsonEncode(model
            .toJson()), // Modelin toJson() metodunu çağırarak veri gönderiyoruz
      );

      if (response.statusCode == 200 && response.data != null) {
        try {
          return ResponseMessage.fromJson(response.data);
        } catch (jsonError) {
          print('JSON dönüşüm hatası: $jsonError');
          return ResponseMessage(
              message: 'Sunucu yanıtı işlenirken bir hata oluştu',
              isSuccess: false);
        }
      } else {
        return ResponseMessage(
            message: 'İşlem başarısız oldu. Lütfen daha sonra tekrar deneyin',
            isSuccess: false);
      }
    } catch (e) {
      print('StudentService signUp hatası: $e');
      return ResponseMessage(
          message: 'Bağlantı hatası: ${e.toString().split(":").first}',
          isSuccess: false);
    }
  }

  // Öğrenci aktif etme
  Future<ResponseMessage> active(String token) async {
    final response = await _dio.put('/active',
        options: Options(
          headers: {
            'Authorization':
                'Bearer $token', // Burada gelen token'ı kullanıyoruz
          },
        ));
    return ResponseMessage.fromJson(response.data);
  }

  // Şifre sıfırlama
  Future<ResponseMessage> resetPassword(
      String token, String newPassword) async {
    final response = await _dio.put('/reset-password', queryParameters: {
      'token': token,
      'newPassword': newPassword,
    });
    return ResponseMessage.fromJson(response.data);
  }

  // Öğrenci profil bilgilerini getirme
  Future<DataResponseMessage<StudentDTO>> getStudentProfile(
      String token) async {
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
  Future<ResponseMessage> updateStudentProfile(
      String token, dynamic model) async {
    final response = await _dio.put(
      '/profile',
      data: model is UpdateStudentProfileRequest
          ? jsonEncode(model.toJson())
          : jsonEncode(model),
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
    final response = await _dio.post('/profile-photo',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ));
    return ResponseMessage.fromJson(response.data);
  }

  // Öğrenci hesap silme
  Future<ResponseMessage> deleteStudent(String token) async {
    final response = await _dio.delete('/delete',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ));
    return ResponseMessage.fromJson(response.data);
  }

  // Öğrenci şifresini güncelleme
  Future<ResponseMessage> updatePassword(
      String token, String newPassword) async {
    final response = await _dio.put('/update-password',
        queryParameters: {
          'newPassword': newPassword,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ));
    return ResponseMessage.fromJson(response.data);
  }

  // FCM token güncelleme
  Future<ResponseMessage> updateFcmToken(String token, String fcmToken) async {
    final response = await _dio.put('/updateFcmToken',
        queryParameters: {
          'fcmToken': fcmToken,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ));
    return ResponseMessage.fromJson(response.data);
  }

  // Profil fotoğrafını silme
  Future<ResponseMessage> deleteProfilePhoto(String token) async {
    final response = await _dio.delete('/profile-photo',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ));
    return ResponseMessage.fromJson(response.data);
  }

  // Profil gizlilik durumunu değiştirme
  Future<ResponseMessage> changePrivate(String token, bool isPrivate) async {
    final response = await _dio.put('/change-private',
        queryParameters: {
          'isPrivate': isPrivate,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ));
    return ResponseMessage.fromJson(response.data);
  }

  // Öğrenci arama
  Future<DataResponseMessage<List<SearchAccountDTO>>> search(
      String token, String query, int page) async {
    try {
      print('StudentService: Searching for "$query"...');
      final response = await _dio.get(
        '/search',
        queryParameters: {
          'query': query,
          'page': page,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      print(
          'StudentService: Search response received with status: ${response.statusCode}');

      if (response.statusCode != 200) {
        print(
            'StudentService search failed with status: ${response.statusCode}');
        return DataResponseMessage<List<SearchAccountDTO>>(
          message: 'Sunucu hatası: ${response.statusCode}',
          data: [],
          isSuccess: false,
        );
      }

      // Validate that data is actually a list
      if (response.data['data'] == null) {
        print('StudentService: Search response data is null');
        return DataResponseMessage<List<SearchAccountDTO>>(
          message: 'Arama sonucu bulunamadı',
          data: [],
          isSuccess: true,
        );
      }

      if (!(response.data['data'] is List)) {
        print(
            'StudentService: Search response data is not a list, it is: ${response.data['data'].runtimeType}');
        return DataResponseMessage<List<SearchAccountDTO>>(
          message: 'Veri formatı uyumsuz',
          data: [],
          isSuccess: false,
        );
      }

      try {
        final result = DataResponseMessage<List<SearchAccountDTO>>.fromJson(
          response.data,
          (data) => (data as List)
              .map((item) =>
                  SearchAccountDTO.fromJson(item as Map<String, dynamic>))
              .toList(),
        );
        print(
            'StudentService: Found ${result.data?.length ?? 0} search results');
        return result;
      } catch (e) {
        print('StudentService: Error parsing search response data: $e');
        return DataResponseMessage<List<SearchAccountDTO>>(
          message: 'Arama sonuçları işlenirken hata oluştu: $e',
          data: [],
          isSuccess: false,
        );
      }
    } catch (e) {
      print('StudentService search error: $e');
      return DataResponseMessage<List<SearchAccountDTO>>(
        message: 'Arama sırasında bir hata oluştu: $e',
        data: [],
        isSuccess: false,
      );
    }
  }

  // Hesap detaylarını alma
  Future<DataResponseMessage<dynamic>> accountDetails(
      String token, int userId) async {
    final response = await _dio.get('/account-details/$userId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ));

    // Assuming the response contains a field that indicates if the account is private
    final isPrivate = response.data[
        'isPrivate']; // Adjust this based on your actual response structure
    final isFollowing = response.data[
        'isFollowing']; // Adjust this based on your actual response structure

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
  Future<DataResponseMessage<List<PublicAccountDetails>>>
      getStudentsByDepartment(String token, String department, int page) async {
    final response = await _dio.get('/students-by-department',
        queryParameters: {
          'department': department,
          'page': page,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ));
    return DataResponseMessage<List<PublicAccountDetails>>.fromJson(
      response.data,
      (data) => (data as List)
          .map((item) =>
              PublicAccountDetails.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  // Fakülteye göre öğrencileri alma
  Future<DataResponseMessage<List<PublicAccountDetails>>> getStudentsByFaculty(
      String token, String faculty, int page) async {
    final response = await _dio.get('/students-by-faculty',
        queryParameters: {
          'faculty': faculty,
          'page': page,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ));
    return DataResponseMessage<List<PublicAccountDetails>>.fromJson(
      response.data,
      (data) => (data as List)
          .map((item) =>
              PublicAccountDetails.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  // Sınıfa göre öğrencileri alma
  Future<DataResponseMessage<List<PublicAccountDetails>>> getStudentsByGrade(
      String token, String grade, int page) async {
    final response = await _dio.get('/students-by-grade',
        queryParameters: {
          'grade': grade,
          'page': page,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ));
    return DataResponseMessage<List<PublicAccountDetails>>.fromJson(
      response.data,
      (data) => (data as List)
          .map((item) =>
              PublicAccountDetails.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  // En iyi popülerlikteki öğrencileri alma
  Future<DataResponseMessage<List<BestPopularityAccount>>> getBestPopularity(
      String token) async {
    final response = await _dio.get('/best-popularity',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ));
    return DataResponseMessage<List<BestPopularityAccount>>.fromJson(
      response.data,
      (data) => (data as List)
          .map((item) =>
              BestPopularityAccount.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  // Ana sayfadaki postları alma
  Future<DataResponseMessage<List<PostDTO>>> getHomePosts(
      String token, int page) async {
    final response = await _dio.get('/home/posts',
        queryParameters: {
          'page': page,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ));
    return DataResponseMessage<List<PostDTO>>.fromJson(
      response.data,
      (data) => (data as List)
          .map((item) => PostDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  // Ana sayfadaki hikayeleri alma
  Future<DataResponseMessage<List<HomeStoryDTO>>> getHomeStories(
      String token, int page) async {
    try {
      print('===== getHomeStories START =====');
      print('API isteği yapılıyor: /home/stories');
      print('Token: ${token.substring(0, min(10, token.length))}...');
      print('Page: $page');

      final response = await _dio.get(
        '/home/stories',
        queryParameters: {
          'page': page,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => true, // All status codes will be handled
        ),
      );

      print('API yanıtı alındı. Status: ${response.statusCode}');
      print('API yanıtı: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data != null && response.data['data'] != null) {
          final List<dynamic> storyData = response.data['data'];
          print('Hikaye sayısı: ${storyData.length}');

          List<HomeStoryDTO> stories = [];
          for (var item in storyData) {
            try {
              final story = HomeStoryDTO.fromJson(item);
              stories.add(story);
              print(
                  'Hikaye eklendi: ${story.username}, Fotoğraf sayısı: ${story.photos.length}');
            } catch (e) {
              print('Hikaye dönüştürme hatası: $e');
            }
          }

          print('Toplam ${stories.length} hikaye başarıyla dönüştürüldü');
          return DataResponseMessage<List<HomeStoryDTO>>(
            message: response.data['message'] ?? 'Başarılı',
            data: stories,
            isSuccess: true,
          );
        } else {
          print('Hikaye verisi boş veya null');
          return DataResponseMessage<List<HomeStoryDTO>>(
            message: 'Hikaye bulunamadı',
            data: [],
            isSuccess: true,
          );
        }
      } else {
        print('API hatası: ${response.statusCode}');
        return DataResponseMessage<List<HomeStoryDTO>>(
          message: 'API hatası: ${response.statusCode}',
          data: [],
          isSuccess: false,
        );
      }
    } catch (e) {
      print('getHomeStories hatası: $e');
      return DataResponseMessage<List<HomeStoryDTO>>(
        message: 'Bağlantı hatası: $e',
        data: [],
        isSuccess: false,
      );
    } finally {
      print('===== getHomeStories END =====');
    }
  }

  // Önerilen bağlantıları alma
  Future<DataResponseMessage<List<String>>> getSuggestedConnections(
      String token) async {
    final response = await _dio.get('/suggested-connections',
        options: Options(
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
  Future<DataResponseMessage<StudentDTO>> fetchProfile(String? token) async {
    try {
      print('StudentService - Fetching profile data');
      final response = await _dio.get(
        '/profile',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${token ?? ""}',
          },
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      print(
          'StudentService - Profile response received with status: ${response.statusCode}');

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
        print(
            'StudentService - Profile fetch failed: ${response.data['message']}');
        return DataResponseMessage<StudentDTO>(
          message: response.data['message'] ?? 'Bir hata oluştu',
          data: null,
          isSuccess: false,
        );
      }
    } catch (e) {
      print('StudentService fetchProfile error: $e');

      if (e is DioException) {
        final String errorMessage;
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            errorMessage =
                'Bağlantı zaman aşımına uğradı. Lütfen internet bağlantınızı kontrol edin.';
            break;
          case DioExceptionType.badResponse:
            errorMessage = 'Sunucu hatası: ${e.response?.statusCode}';
            break;
          case DioExceptionType.connectionError:
            errorMessage =
                'Bağlantı hatası. Lütfen internet bağlantınızı kontrol edin.';
            break;
          default:
            errorMessage = 'Bir hata oluştu: ${e.message}';
        }

        return DataResponseMessage<StudentDTO>(
          message: errorMessage,
          data: null,
          isSuccess: false,
        );
      }

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

  // Önerilen kullanıcıları alma
  Future<DataResponseMessage<List<SuggestUserRequest>>> fetchSuggestedUsers(
      String? token) async {
    try {
      final response = await _dio.get('/suggested-users',
          options: Options(
            headers: {
              'Authorization': 'Bearer ${token ?? ""}',
            },
          ));

      // Convert SearchAccountDTO to SuggestUserRequest
      final List<dynamic> data = response.data['data'] ?? [];
      final users = data.map((item) {
        final searchAccount =
            SearchAccountDTO.fromJson(item as Map<String, dynamic>);
        return SuggestUserRequest(
          username: searchAccount.username,
          profilePhotoUrl:
              searchAccount.profilePhoto, // Map profilePhoto to profilePhotoUrl
          fullName: searchAccount.fullName,
          isFollowing: searchAccount.isFollow,
        );
      }).toList();

      return DataResponseMessage<List<SuggestUserRequest>>(
        message: response.data['message'] ?? 'Başarılı',
        data: users,
        isSuccess: true,
      );
    } catch (e) {
      print('Error in fetchSuggestedUsers: $e');
      return DataResponseMessage<List<SuggestUserRequest>>(
        message: 'Bir hata oluştu: $e',
        data: [],
        isSuccess: false,
      );
    }
  }

  // Ana sayfa hikayelerini alma
  Future<DataResponseMessage<List<HomeStoryDTO>>> fetchHomeStories(
      String? token, int page) async {
    try {
      final response = await _dio.get('/home/stories',
          queryParameters: {
            'page': page,
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer ${token ?? ""}',
            },
          ));
      return DataResponseMessage<List<HomeStoryDTO>>.fromJson(
        response.data,
        (data) => (data as List)
            .map((item) => HomeStoryDTO.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      print('Error in fetchHomeStories: $e');
      return DataResponseMessage<List<HomeStoryDTO>>(
        message: 'Bir hata oluştu: $e',
        data: [],
        isSuccess: false,
      );
    }
  }

  // Ana sayfa postlarını alma
  Future<DataResponseMessage<List<PostDTO>>> fetchHomePosts(
      String? token, int page) async {
    try {
      final response = await _dio.get('/home/posts',
          queryParameters: {
            'page': page,
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer ${token ?? ""}',
            },
          ));
      return DataResponseMessage<List<PostDTO>>.fromJson(
        response.data,
        (data) => (data as List)
            .map((item) => PostDTO.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      print('Error in fetchHomePosts: $e');
      return DataResponseMessage<List<PostDTO>>(
        message: 'Bir hata oluştu: $e',
        data: [],
        isSuccess: false,
      );
    }
  }

  // Profil fotoğrafını kaldırma
  Future<ResponseMessage> removeProfilePhoto(String? token) async {
    try {
      final response = await _dio.delete('/profile-photo',
          options: Options(
            headers: {
              'Authorization': 'Bearer ${token ?? ""}',
            },
          ));
      return ResponseMessage.fromJson(response.data);
    } catch (e) {
      print('Error in removeProfilePhoto: $e');
      return ResponseMessage(
          message: 'Profil fotoğrafı kaldırılamadı: $e', isSuccess: false);
    }
  }

  // En popüler öğrencileri alma
  Future<DataResponseMessage<List<BestPopularityAccount>>> fetchBestPopularity(
      String? token) async {
    int retryCount = 0;
    const int maxRetries = 3;
    const Duration initialTimeout =
        Duration(seconds: 40); // Increased timeout significantly

    Future<DataResponseMessage<List<BestPopularityAccount>>>
        attemptFetch() async {
      try {
        final response = await _dio.get(
          '/best-popularity',
          options: Options(
            headers: {
              'Authorization': 'Bearer ${token ?? ""}',
            },
            sendTimeout: initialTimeout,
            receiveTimeout: initialTimeout,
          ),
        );

        if (response.statusCode != 200) {
          print(
              'fetchBestPopularity failed with status: ${response.statusCode}');
          return DataResponseMessage<List<BestPopularityAccount>>(
            message: 'Sunucu hatası: ${response.statusCode}',
            data: [],
            isSuccess: false,
          );
        }

        return DataResponseMessage<List<BestPopularityAccount>>.fromJson(
          response.data,
          (data) => (data as List)
              .map((item) =>
                  BestPopularityAccount.fromJson(item as Map<String, dynamic>))
              .toList(),
        );
      } catch (e) {
        print('Error in fetchBestPopularity attempt $retryCount: $e');
        if (e is DioException &&
            (e.type == DioExceptionType.receiveTimeout ||
                e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.sendTimeout)) {
          if (retryCount < maxRetries) {
            retryCount++;
            print(
                'Retrying fetchBestPopularity... Attempt $retryCount of $maxRetries');

            // Exponential backoff: wait longer between each retry
            await Future.delayed(Duration(seconds: retryCount * 2));
            return attemptFetch();
          }
        }

        return DataResponseMessage<List<BestPopularityAccount>>(
          message: 'Veri alınırken hata oluştu: $e',
          data: [],
          isSuccess: false,
        );
      }
    }

    return attemptFetch();
  }
}
