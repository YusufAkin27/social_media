import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math';

/// Video dosyaları için yardımcı sınıf.
/// Video boyutunu, tipini ve geçerliliğini kontrol etmeyi sağlar.
class VideoHelper {
  static final Dio _dio = Dio();
  static final Map<String, String> _cachedVideoTypes = {};
  static final List<String> _validatedUrls = [];
  
  /// Video türlerini kontrol eder
  static bool isVideoFile(String path) {
    if (path.isEmpty) return false;
    
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith('.mp4') || 
           lowerPath.endsWith('.mov') || 
           lowerPath.endsWith('.avi') || 
           lowerPath.endsWith('.mkv') || 
           lowerPath.endsWith('.webm') ||
           lowerPath.endsWith('.3gp') ||
           lowerPath.endsWith('.m4v') ||
           lowerPath.endsWith('.m3u8') ||
           lowerPath.endsWith('.mpd');
  }
  
  /// URL'nin erişilebilir olup olmadığını kontrol eder 
  static Future<bool> isVideoUrlAccessible(String url) async {
    if (!url.startsWith('http')) return false;
    
    // Daha önce doğrulanmış URL ise hemen true döndür
    if (_validatedUrls.contains(url)) {
      print('URL zaten doğrulanmış: $url');
      return true;
    }
    
    try {
      // Custom user agent ve kapsamlı headers ekleyin
      final customHeaders = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36',
        'Accept': '*/*',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
        'Range': 'bytes=0-1024', // Sadece başlangıç kısmını iste
      };
      
      // Önce DIO ile dene
      try {
        final dioResponse = await _dio.head(
          url,
          options: Options(
            headers: customHeaders,
            followRedirects: true,
            validateStatus: (status) => true,
            receiveTimeout: const Duration(seconds: 5),
            sendTimeout: const Duration(seconds: 5),
          ),
        );
        
        if (dioResponse.statusCode! >= 200 && dioResponse.statusCode! < 400) {
          _validatedUrls.add(url); // URL'yi doğrulanmış olarak kaydet
          return true;
        }
      } catch (dioError) {
        print('DIO hatası: $dioError');
        // DIO başarısız olursa HTTP ile devam et
      }
      
      // HTTP ile dene
      final response = await http.head(Uri.parse(url), headers: customHeaders).timeout(
        const Duration(seconds: 5),
        onTimeout: () => http.Response('Timeout', 408),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 400) {
        _validatedUrls.add(url); // URL'yi doğrulanmış olarak kaydet
        return true;
      }
      
      // Son çare: GET isteği ile bayt aralığı kontrolü
      final getResponse = await http.get(
        Uri.parse(url),
        headers: {'Range': 'bytes=0-1024'},
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => http.Response('Timeout', 408),
      );
      
      if (getResponse.statusCode >= 200 && getResponse.statusCode < 400) {
        _validatedUrls.add(url); // URL'yi doğrulanmış olarak kaydet
        return true;
      }
      
      return false;
    } catch (e) {
      print('Video URL kontrol hatası: $e');
      return false;
    }
  }
  
  /// Video dosyasının boyutunu alır (bayt cinsinden)
  static Future<int> getVideoSize(String url) async {
    try {
      if (url.startsWith('http')) {
        final response = await http.head(Uri.parse(url));
        final contentLength = response.headers['content-length'];
        if (contentLength != null) {
          return int.parse(contentLength);
        }
      } else if (File(url).existsSync()) {
        return File(url).lengthSync();
      }
    } catch (e) {
      print('Video boyut hatası: $e');
    }
    return 0;
  }
  
  /// Ön bellek kontrol eder ve temizler
  static Future<void> clearVideoCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/video_cache');
      
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
      
      // Önbelleğe alınmış video türlerini temizle
      _cachedVideoTypes.clear();
      
      // Doğrulanmış URL'leri temizle (opsiyonel)
      // _validatedUrls.clear();
    } catch (e) {
      print('Video önbellek temizleme hatası: $e');
    }
  }
  
  /// Video başlığını içerdiği keyframelardan oluşturur
  static Future<List<String>> extractVideoKeyframes(String videoUrl, {int count = 3}) async {
    // Bu fonksiyon sunucu tarafında gerçekleştirilecek
    // Şu an sadece mock veri döndürüyoruz
    return [];
  }
  
  /// Video stream türünü belirler (DASH, HLS, vs.)
  static Future<String> detectVideoStreamType(String url) async {
    if (!url.startsWith('http')) return 'file';
    
    // Daha önce tespit edilmiş tür varsa onu kullan
    if (_cachedVideoTypes.containsKey(url)) {
      return _cachedVideoTypes[url]!;
    }
    
    try {
      final lowerUrl = url.toLowerCase();
      String detectedType = 'unknown';
      
      if (lowerUrl.contains('.m3u8')) {
        detectedType = 'hls';
      } else if (lowerUrl.contains('.mpd')) {
        detectedType = 'dash';
      } else if (lowerUrl.contains('.ism')) {
        detectedType = 'smooth';
      } else {
        // İçerik türünü kontrol et
        try {
          final response = await _dio.head(url, options: Options(
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36',
              'Range': 'bytes=0-1024',
            },
            followRedirects: true,
            validateStatus: (status) => true,
            receiveTimeout: const Duration(seconds: 3),
          ));
          
          final contentType = response.headers.map['content-type']?.first ?? '';
          
          if (contentType.contains('mpegurl') || contentType.contains('m3u8')) {
            detectedType = 'hls';
          } else if (contentType.contains('dash') || contentType.contains('mpd')) {
            detectedType = 'dash';
          } else if (contentType.contains('mp4') || 
                    contentType.contains('video') || 
                    lowerUrl.endsWith('.mp4')) {
            detectedType = 'mp4';
          } else if (contentType.isNotEmpty) {
            // Diğer bilinen video içerik türleri
            detectedType = 'video';
          }
        } catch (e) {
          print('Content type kontrolü hatası: $e');
          
          // URL'den tahmin et
          if (isVideoFile(url)) {
            final extension = url.split('.').last.toLowerCase();
            detectedType = extension;
          }
        }
      }
      
      // Tespit edilen türü önbelleğe al
      _cachedVideoTypes[url] = detectedType;
      return detectedType;
    } catch (e) {
      print('Video tür tespit hatası: $e');
      return 'unknown';
    }
  }
  
  /// Test amaçlı: Desteklenen video formatları ve kodeklerini kontrol eder
  static Future<bool> isSupportedVideoFormat(String url) async {
    final type = await detectVideoStreamType(url);
    // HLS, DASH ve MP4 formatları desteklenir
    return ['hls', 'dash', 'mp4', 'video', 'webm'].contains(type);
  }
  
  /// URL'yi normalize eder ve düzeltir
  static String normalizeVideoUrl(String url) {
    if (url.isEmpty) return '';
    
    // URL boşluk içeriyorsa düzelt
    String normalizedUrl = url.trim();
    
    // URL kodlaması yap
    if (normalizedUrl.contains(' ')) {
      normalizedUrl = Uri.encodeFull(normalizedUrl);
    }
    
    // HTTP/HTTPS kontrolü
    if (!normalizedUrl.startsWith('http://') && !normalizedUrl.startsWith('https://')) {
      normalizedUrl = 'https://$normalizedUrl';
    }
    
    return normalizedUrl;
  }
} 