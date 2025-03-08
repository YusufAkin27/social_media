import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media/models/login_request_dto.dart';
import 'package:social_media/models/token_response_dto.dart';
import 'package:social_media/models/update_access_token_request_dto.dart';
import 'package:social_media/models/response_message.dart';

class AuthService {
  static Dio? _dioInstance;
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:8080/v1/api/auth', // Backend URL'ini güncelle
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  // Singleton pattern ile tek Dio örneği
  static Future<Dio> getDio() async {
    if (_dioInstance == null) {
      _dioInstance = Dio(
        BaseOptions(
          baseUrl: 'http://localhost:8080/v1/api', // Ana API URL'i
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      // Token yenileme interceptor'unu ekle
      _dioInstance!.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            // Her istekte token ekle
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('accessToken');
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            return handler.next(options);
          },
          onError: (DioException error, handler) async {
            // 403 hatası alındıysa (token süresi doldu)
            if (error.response?.statusCode == 403 || error.response?.statusCode == 401) {
              print('Token süresi doldu, yenileniyor...');
              
              try {
                // Token'ı yenile
                await AuthService().refreshToken();
                
                // Token yenilendikten sonra orijinal isteği tekrar gönder
                final prefs = await SharedPreferences.getInstance();
                final newToken = prefs.getString('accessToken');
                
                // Orijinal isteğin kopyasını oluştur
                final opts = Options(
                  method: error.requestOptions.method,
                  headers: {
                    ...error.requestOptions.headers,
                    'Authorization': 'Bearer $newToken',
                  },
                );
                
                // İsteği yeni token ile tekrarla
                final response = await _dioInstance!.request(
                  error.requestOptions.path,
                  data: error.requestOptions.data,
                  queryParameters: error.requestOptions.queryParameters,
                  options: opts,
                );
                
                // Başarılı yanıtı işle
                return handler.resolve(response);
              } catch (e) {
                // Token yenileme başarısız oldu - oturum süresi dolmuş olabilir
                print('Token yenileme başarısız: $e');
                return handler.next(error);
              }
            }
            
            // Diğer hataları normal şekilde işle
            return handler.next(error);
          },
        ),
      );
    }
    
    return _dioInstance!;
  }

  Future<TokenResponseDTO> login(LoginRequestDTO loginRequest) async {
    try {
      // Use the properties of loginRequest
      final response = await _dio.post(
        '/login',
        data: loginRequest.toJson(), // JSON'a dönüştürülüyor
      );

      if (response.data != null) {
        final tokenData = response.data;

        // SharedPreferences ile tokenları saklıyoruz
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', tokenData['accessToken']);
        await prefs.setString('refreshToken', tokenData['refreshToken']);

        // Gelen veriyi TokenResponseDTO'ya dönüştürüyoruz
        return TokenResponseDTO.fromJson(tokenData); 
      } else {
        final errorMessage = response.data['message'] ?? "Giriş başarısız";
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception("Bağlantı hatası: $e");
    }
  }

  Future<bool> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refreshToken');
      final ipAddress = "192.168.1.1"; // Kullanıcının IP adresini alman gerek
      final deviceInfo = "Flutter App v1.0"; // Cihaz bilgisi alınmalı

      if (refreshToken == null) {
        throw Exception("Yenileme tokenı bulunamadı");
      }

      final response = await _dio.post(
        '/refresh',
        data: jsonEncode({
          'refreshToken': refreshToken,
          'ipAddress': ipAddress,
          'deviceInfo': deviceInfo,
        }),
      );

      if (response.statusCode == 200) {
        final newTokenData = response.data;
        await prefs.setString('accessToken', newTokenData['accessToken']);
        return true;
      } else {
        throw Exception("Token yenileme başarısız");
      }
    } catch (e) {
      print("Token yenileme hatası: $e");
      return false;
    }
  }

  Future<ResponseMessage> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        throw Exception("Çıkış yapacak kullanıcı bulunamadı");
      }

      final response = await _dio.post(
        '/logout',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');

      // Çıkış yanıtını ResponseMessage modeline dönüştür
      return ResponseMessage.fromJson(response.data);
    } catch (e) {
      throw Exception("Çıkış yaparken hata oluştu: $e");
    }
  }
}
