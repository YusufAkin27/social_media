import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media/models/login_request_dto.dart';
import 'package:social_media/models/token_response_dto.dart';
import 'package:social_media/models/update_access_token_request_dto.dart';
import 'package:social_media/models/response_message.dart';
import 'dart:developer' as developer;
import 'package:device_info_plus/device_info_plus.dart';

class AuthService {
  static Dio? _dioInstance;
  static AuthService? _instance;
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl:
          'http://192.168.89.61:8080/v1/api/auth', // Android emülatör için localhost
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  // Token yenileme işlemi için kilit mekanizması
  static bool _isRefreshing = false;
  static Future<void>? _refreshingFuture;

  // Singleton pattern
  static AuthService getInstance() {
    _instance ??= AuthService();
    return _instance!;
  }

  // Singleton pattern ile tek Dio örneği
  static Future<Dio> getDio() async {
    if (_dioInstance == null) {
      _dioInstance = Dio(
        BaseOptions(
          baseUrl: 'http://192.168.89.61:8080/v1/api', // Ana API URL'i
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
            // 401 veya 403 hatası alındıysa (token süresi doldu)
            if (error.response?.statusCode == 401 ||
                error.response?.statusCode == 403) {
              // Orijinal isteği sakla
              final RequestOptions originalRequest = error.requestOptions;

              developer.log('Token süresi doldu, yenileniyor...',
                  name: 'AuthService');

              try {
                // Eğer zaten token yenileniyorsa, bekleyin
                if (_isRefreshing) {
                  await _refreshingFuture;
                } else {
                  // Token'ı yenile
                  _isRefreshing = true;
                  _refreshingFuture = getInstance().refreshToken();
                  await _refreshingFuture;
                  _isRefreshing = false;
                }

                // Token yenilendikten sonra orijinal isteği tekrar gönder
                final prefs = await SharedPreferences.getInstance();
                final newToken = prefs.getString('accessToken');

                if (newToken == null) {
                  throw DioException(
                    requestOptions: originalRequest,
                    error: 'Token yenileme başarısız oldu',
                    type: DioExceptionType.unknown,
                  );
                }

                // Orijinal isteği yeni token ile tekrar dene
                final response = await _dioInstance!.fetch(originalRequest
                  ..headers['Authorization'] = 'Bearer $newToken');

                // Başarılı yanıtı işle
                return handler.resolve(response);
              } catch (e) {
                // Token yenileme başarısız oldu
                developer.log('Token yenileme başarısız: $e',
                    name: 'AuthService', error: e);

                // Kullanıcı oturumunu sonlandır
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('accessToken');
                await prefs.remove('refreshToken');

                // Orijinal hatayı döndür
                return handler.next(error);
              } finally {
                _isRefreshing = false;
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
      final deviceInfo = await _getDeviceInfo();
      final ipAddress = await _getIpAddress();
      final loginTime = DateTime.now().toIso8601String();

      developer.log(
        'Giriş denemesi: ${loginRequest.username} | IP: $ipAddress | Cihaz: $deviceInfo | Zaman: $loginTime',
        name: 'AuthService',
      );

      final response = await _dio.post(
        '/login',
        data: loginRequest.toJson(),
      );

      if (response.statusCode == 200) {
        final tokenData = response.data;
        final tokenResponse = TokenResponseDTO.fromJson(tokenData);

        // Token'ları kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', tokenResponse.accessToken);
        await prefs.setString('refreshToken', tokenResponse.refreshToken);

        // Giriş yapan kullanıcı bilgilerini logla
        developer.log(
          'KULLANICI GİRİŞ YAPTI',
          name: 'AuthService',
        );
        developer.log(
          'Kullanıcı: ${loginRequest.username}',
          name: 'AuthService',
        );
        developer.log(
          'IP Adresi: $ipAddress',
          name: 'AuthService',
        );
        developer.log(
          'Cihaz Bilgileri: $deviceInfo',
          name: 'AuthService',
        );
        developer.log(
          'Giriş Zamanı: $loginTime',
          name: 'AuthService',
        );
        developer.log(
          'Token Bilgileri: Erişim Token: ${tokenResponse.accessToken.substring(0, 10)}..., Yenileme Token: ${tokenResponse.refreshToken.substring(0, 10)}...',
          name: 'AuthService',
        );

        return tokenResponse;
      } else {
        developer.log(
          'Giriş başarısız: ${loginRequest.username} | Hata: ${response.data['message']} | IP: $ipAddress | Cihaz: $deviceInfo',
          name: 'AuthService',
        );
        throw Exception(response.data['message'] ?? "Giriş başarısız");
      }
    } on DioException catch (e) {
      final deviceInfo = await _getDeviceInfo();
      final ipAddress = await _getIpAddress();

      if (e.type == DioExceptionType.connectionTimeout) {
        developer.log(
          'Bağlantı zaman aşımı: ${loginRequest.username} | IP: $ipAddress | Cihaz: $deviceInfo',
          name: 'AuthService',
        );
        throw Exception("Bağlantı zaman aşımına uğradı");
      }

      final errorMessage =
          e.response?.data['message'] ?? e.message ?? "Giriş başarısız";
      developer.log(
        'Giriş hatası: ${loginRequest.username} | Hata: $errorMessage | IP: $ipAddress | Cihaz: $deviceInfo',
        name: 'AuthService',
      );
      throw Exception(errorMessage);
    } catch (e) {
      developer.log(
        'Beklenmeyen giriş hatası: ${loginRequest.username} | Hata: $e',
        name: 'AuthService',
        error: e,
      );
      throw Exception("Beklenmeyen bir hata oluştu: $e");
    }
  }

  // Token yenileme işlemi
  Future<bool> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refreshToken');

      if (refreshToken == null) {
        developer.log('Yenileme tokenı bulunamadı', name: 'AuthService');
        return false;
      }

      // Update token request objesi oluştur
      final updateTokenRequest = UpdateAccessTokenRequestDTO(
        refreshToken: refreshToken,
        ipAddress: await _getIpAddress(),
        deviceInfo: await _getDeviceInfo(),
      );

      // Yeni bir Dio nesnesi oluştur
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: 'http://192.168.89.61:8080/v1/api/auth',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      final response = await refreshDio.post(
        '/refresh',
        data: updateTokenRequest.toJson(),
      );

      if (response.statusCode == 200) {
        final newTokenData = response.data;
        await prefs.setString('accessToken', newTokenData['accessToken']);
        if (newTokenData['refreshToken'] != null) {
          await prefs.setString('refreshToken', newTokenData['refreshToken']);
        }
        developer.log('Token başarıyla yenilendi', name: 'AuthService');
        return true;
      } else {
        developer.log('Token yenileme başarısız: Sunucu isteği reddetti',
            name: 'AuthService');
        return false;
      }
    } catch (e) {
      developer.log('Token yenileme hatası: $e', name: 'AuthService', error: e);
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

      // Token'ları temizle
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');

      return ResponseMessage.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? "Çıkış yaparken hata oluştu");
    } catch (e) {
      throw Exception("Beklenmeyen bir hata oluştu: $e");
    }
  }

  // Yardımcı metodlar
  Future<String> _getDeviceInfo() async {
    try {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      return 'Android ${deviceInfo.model} (${deviceInfo.id})';
    } catch (e) {
      return 'Unknown Device';
    }
  }

  Future<String> _getIpAddress() async {
    try {
      final response = await Dio().get('https://api64.ipify.org?format=json');
      return response.data['ip'];
    } catch (e) {
      return 'Unknown IP';
    }
  }
}
