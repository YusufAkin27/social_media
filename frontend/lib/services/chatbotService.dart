import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'dart:async'; // TimeoutException için gerekli import

/// Chatbot servislerini yöneten sınıf.
///
/// Bu sınıf, chatbot ile iletişim kurmak için gerekli API çağrılarını yapar,
/// kullanıcı mesajlarını gönderir ve yanıtları alır.
class ChatbotService {
  // API yapılandırma bilgileri
  static const String _baseUrl = "http://192.168.89.61:8080/v1/api";
  static const String _studentBaseUrl = "$_baseUrl/student";
  static const String _chatbotEndpoint = "/chatbot/sendMessage";

  // HTTP isteği için timeout süresi
  static const Duration _requestTimeout = Duration(seconds: 15);

  // Log için prefix
  static const String _logPrefix = 'ChatbotService';

  /// Kullanıcı mesajını chatbot'a gönderir
  ///
  /// [message] - Kullanıcının gönderdiği mesaj
  ///
  /// Geri dönüş değeri:
  /// - Map içinde 'success' anahtarı işlemin başarı durumunu belirtir
  /// - Başarılı ise 'message' anahtarı chatbot yanıtını içerir
  /// - Başarısız ise 'message' anahtarı hata mesajını içerir
  static Future<Map<String, dynamic>> sendMessage(String message) async {
    try {
      // Access token doğrulama
      final tokenResult = await _getAccessToken();
      if (!tokenResult['success']) {
        return tokenResult;
      }
      final accessToken = tokenResult['token'];

      // URL-safe mesaj oluştur
      final encodedMessage = Uri.encodeComponent(message);
      final apiUrl = '$_baseUrl$_chatbotEndpoint?message=$encodedMessage';

      _logInfo('Mesaj gönderiliyor: $apiUrl');

      // API isteği gönder
      final response = await _executeGetRequest(apiUrl, accessToken);

      // Yanıt işleme
      return _processResponse(response,
          successHandler: (data) => {'success': true, 'message': data},
          errorPrefix: 'Mesaj gönderimi başarısız');
    } catch (e) {
      return _handleException(e);
    }
  }

  /// Öğrenci profil bilgilerini getirir
  ///
  /// Geri dönüş değeri:
  /// - Map içinde 'success' anahtarı işlemin başarı durumunu belirtir
  /// - Başarılı ise 'data' anahtarı profil bilgilerini içerir
  /// - Başarısız ise 'message' anahtarı hata mesajını içerir
  static Future<Map<String, dynamic>> getStudentProfile() async {
    try {
      // Access token doğrulama
      final tokenResult = await _getAccessToken();
      if (!tokenResult['success']) {
        return tokenResult;
      }
      final accessToken = tokenResult['token'];

      final apiUrl = '$_studentBaseUrl/profile';

      _logInfo('Profil bilgileri alınıyor: $apiUrl');

      // API isteği gönder
      final response = await _executeGetRequest(apiUrl, accessToken);

      // Yanıt işleme
      return _processResponse(response,
          successHandler: (data) =>
              {'success': true, 'data': json.decode(data)},
          errorPrefix: 'Profil bilgileri alınamadı');
    } catch (e) {
      return _handleException(e);
    }
  }

  /// Access token'ı SharedPreferences'dan alır
  ///
  /// Geri dönüş değeri token bilgisini içeren Map:
  /// - {'success': true, 'token': 'token-değeri'}
  /// - {'success': false, 'message': 'hata-mesajı'}
  static Future<Map<String, dynamic>> _getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null || accessToken.isEmpty) {
        _logError('Access token bulunamadı');
        return {
          'success': false,
          'message': 'Oturum bilginiz bulunamadı. Lütfen tekrar giriş yapın.'
        };
      }

      return {'success': true, 'token': accessToken};
    } catch (e) {
      _logError('Token alınamadı', e);
      return {
        'success': false,
        'message': 'Oturum bilgisi işlenirken hata oluştu.'
      };
    }
  }

  /// HTTP GET isteği gönderir
  ///
  /// [url] - İstek yapılacak URL
  /// [token] - Yetkilendirme için access token
  ///
  /// HTTP yanıtını döndürür
  static Future<http.Response> _executeGetRequest(
      String url, String token) async {
    return http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(_requestTimeout);
  }

  /// HTTP yanıtını işler
  ///
  /// [response] - HTTP yanıtı
  /// [successHandler] - Başarılı yanıt durumunda çalışacak fonksiyon
  /// [errorPrefix] - Hata mesajlarına eklenecek ön bilgi
  ///
  /// İşlenmiş yanıtı içeren Map döndürür
  static Map<String, dynamic> _processResponse(http.Response response,
      {required Map<String, dynamic> Function(String) successHandler,
      required String errorPrefix}) {
    // Durum koduna göre işlem yap
    if (response.statusCode == 200) {
      _logInfo('Başarılı yanıt alındı (${response.statusCode})');
      return successHandler(response.body);
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      _logError('Yetkilendirme hatası: ${response.statusCode}');
      return {
        'success': false,
        'message': 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.'
      };
    } else {
      _logError('Sunucu hatası: ${response.statusCode}');
      return {
        'success': false,
        'message': '$errorPrefix: (${response.statusCode})'
      };
    }
  }

  /// İstisnaları işler ve uygun hata mesajı döndürür
  ///
  /// [e] - Yakalanan istisna
  ///
  /// Hata bilgisini içeren Map döndürür
  static Map<String, dynamic> _handleException(dynamic e) {
    _logError('İşlem hatası', e);

    // Spesifik hata türlerine göre farklı mesajlar oluşturulabilir
    if (e is http.ClientException) {
      return {
        'success': false,
        'message':
            'Sunucuya bağlanılamadı. Lütfen internet bağlantınızı kontrol edin.'
      };
    } else if (e is FormatException) {
      return {'success': false, 'message': 'Sunucudan gelen yanıt işlenemedi.'};
    } else if (e is TimeoutException) {
      return {
        'success': false,
        'message': 'Sunucu yanıt vermedi. Lütfen daha sonra tekrar deneyin.'
      };
    }

    return {
      'success': false,
      'message':
          'Beklenmeyen bir hata oluştu. Lütfen daha sonra tekrar deneyin.'
    };
  }

  /// Bilgilendirme mesajlarını loglar
  ///
  /// [message] - Log mesajı
  static void _logInfo(String message) {
    developer.log(message, name: _logPrefix);
  }

  /// Hata mesajlarını loglar
  ///
  /// [message] - Log mesajı
  /// [error] - Hata nesnesi (opsiyonel)
  static void _logError(String message, [dynamic error]) {
    developer.log(message, name: _logPrefix, error: error);
  }
}
