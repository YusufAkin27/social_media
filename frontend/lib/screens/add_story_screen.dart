import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media/services/storyService.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:social_media/models/followed_user_dto.dart';
import 'package:social_media/models/response_message.dart';
import 'package:social_media/widgets/error_toast.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:social_media/theme/theme_provider.dart';
import 'package:social_media/theme/app_theme.dart';
import 'dart:ui';

class AddStoryScreen extends StatefulWidget {
  const AddStoryScreen({Key? key}) : super(key: key);

  @override
  _AddStoryScreenState createState() => _AddStoryScreenState();
}

class _AddStoryScreenState extends State<AddStoryScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();

  // Medya değişkenleri
  XFile? _selectedMediaFile;
  File? _mediaFile;
  Uint8List? _webMediaBytes;
  bool _isVideo = false;
  VideoPlayerController? _videoController;

  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;
  final StoryService _storyService = StoryService(Dio());
  String? _uploadingText;

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Kameradan fotoğraf çekme
  Future<void> _getMediaFromCamera() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70, // Kalite optimizasyonu
    );

    if (photo != null) {
      _handleSelectedMedia(photo, false);
    }
  }

  // Galeriden fotoğraf seçme
  Future<void> _getPhotoFromGallery() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Kalite optimizasyonu
    );

    if (photo != null) {
      _handleSelectedMedia(photo, false);
    }
  }

  // Galeriden video seçme
  Future<void> _getVideoFromGallery() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 30), // Maksimum video süresi
    );

    if (video != null) {
      _handleSelectedMedia(video, true);
    }
  }

  // Seçilen medyayı işleme
  Future<void> _handleSelectedMedia(XFile mediaFile, bool isVideo) async {
    setState(() {
      _isLoading = true;
      _selectedMediaFile = mediaFile;
      _isVideo = isVideo;
    });

    if (kIsWeb) {
      // Web için medya işleme
      final bytes = await mediaFile.readAsBytes();
      setState(() {
        _webMediaBytes = bytes;
      });
    } else {
      // Mobil için medya işleme
      setState(() {
        _mediaFile = File(mediaFile.path);
      });
    }

    // Video ise kontrolcü başlat
    if (isVideo) {
      _initializeVideoPlayer();
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Video oynatıcı başlatma
  Future<void> _initializeVideoPlayer() async {
    if (_isVideo) {
      if (kIsWeb) {
        // Web'de video URL'i gerekiyor, web için video önizleme şu an desteklenmemektedir
        setState(() {
          _message =
              "Web'de video önizleme desteklenmemektedir, ancak video yükleyebilirsiniz.";
          _isSuccess = true;
        });
      } else {
        final controller = VideoPlayerController.file(_mediaFile!);
        _videoController = controller;
        await controller.initialize();
        await controller.setLooping(true);
        await controller.play();
        setState(() {});
      }
    }
  }

  // Hikaye yükleme
  Future<void> _uploadStory() async {
    if (_selectedMediaFile == null) {
      setState(() {
        _message = "Lütfen bir fotoğraf veya video seçin";
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';

      if (token.isEmpty) {
        setState(() {
          _isLoading = false;
          _message = "Oturum bilgisi bulunamadı";
          _isSuccess = false;
        });
        return;
      }

      if (kIsWeb) {
        // Web için yükleme işlemi
        await _uploadMediaForWeb(token);
      } else {
        // Mobil için yükleme işlemi
        // Dio metodu veya http metodu seçimi
        final useHttp = true; // Http kullanmak için true, Dio için false yapın

        if (useHttp) {
          await _uploadMediaWithHttp(token);
        } else {
          await _uploadMediaForMobile(token);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = "Hikaye eklenirken bir hata oluştu: $e";
        _isSuccess = false;
      });
      print("Hata detayı: $e");
    }
  }

  // Web için medya yükleme işlemi
  Future<void> _uploadMediaForWeb(String token) async {
    try {
      print('Web için hikaye yükleme başlatılıyor...');

      setState(() {
        _uploadingText = 'Yükleme hazırlanıyor...';
      });

      // Web için multipart request oluşturuyoruz
      final url = Uri.parse('http://192.168.89.61:8080/v1/api/story/add');

      // HTTP isteği oluşturma
      var request = http.MultipartRequest('POST', url);

      // Token ekleme
      request.headers['Authorization'] = 'Bearer $token';
      print('Token başlığı eklendi: ${token.substring(0, 15)}...');

      // Dosya adını alma
      final fileName = _selectedMediaFile!.name;

      // Medya türünü belirten bir alan ekle
      request.fields['mediaType'] = _isVideo ? 'video' : 'image';
      print('Medya türü: ${_isVideo ? "video" : "image"}');

      setState(() {
        _uploadingText = 'Medya düzenleniyor...';
      });

      // Medya verilerini ekleme
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        _webMediaBytes!,
        filename: fileName,
      );

      request.files.add(multipartFile);
      print('Dosya eklendi: $fileName (${_webMediaBytes!.length} bytes)');

      setState(() {
        _uploadingText = 'Hikaye yükleniyor...';
      });

      // İsteği gönderme ve cevabı alma
      print('İstek gönderiliyor...');
      final streamedResponse = await request.send();

      setState(() {
        _uploadingText = 'Sunucu yanıtı bekleniyor...';
      });

      final response = await http.Response.fromStream(streamedResponse);

      print('Sunucu yanıtı: ${response.statusCode} - ${response.body}');

      setState(() {
        _uploadingText = 'İşlem tamamlanıyor...';
      });

      // Yanıtı işle
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        responseData = {
          'success': response.statusCode == 200,
          'message': response.body
        };
      }

      // Convert http.Response to ResponseMessage
      final responseMessage = ResponseMessage(
        isSuccess: response.statusCode == 200,
        message:
            responseData['message'] ?? responseData['error'] ?? response.body,
      );

      // Yanıtı işleme
      _handleUploadResponse(responseMessage);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = "Web'de yükleme sırasında hata: $e";
        _isSuccess = false;
        _uploadingText = null;
      });
      print("Web yükleme hatası: $e");
    }
  }

  // HTTP ile mobil için medya yükleme işlemi (Alternatif)
  Future<void> _uploadMediaWithHttp(String token) async {
    try {
      // API URL'i
      final url = Uri.parse('http://192.168.89.61:8080/v1/api/story/add');

      // HTTP MultipartRequest oluşturma
      var request = http.MultipartRequest('POST', url);

      // Token ekleme
      request.headers['Authorization'] = 'Bearer $token';

      // Medya türünü ekle
      request.fields['mediaType'] = _isVideo ? 'video' : 'image';

      // Dosya ekle
      final file = await http.MultipartFile.fromPath(
        'file',
        _mediaFile!.path,
        filename: _mediaFile!.path.split('/').last,
      );

      setState(() {
        _uploadingText = 'Hikaye yükleniyor...';
      });

      request.files.add(file);

      // İsteği gönder
      print(
          'Hikaye yükleniyor: ${_mediaFile!.path} (${_isVideo ? "video" : "image"})');
      final streamedResponse = await request.send();

      setState(() {
        _uploadingText = 'Sunucu yanıtı bekleniyor...';
      });

      final response = await http.Response.fromStream(streamedResponse);

      print('Sunucu yanıtı: ${response.statusCode} - ${response.body}');

      // Yanıtı işle
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        responseData = {
          'success': response.statusCode == 200,
          'message': response.body
        };
      }

      final responseMessage = ResponseMessage(
        isSuccess: response.statusCode == 200,
        message: responseData['message'] ??
            responseData['error'] ??
            'Hikaye yükleme yanıtı alındı',
      );

      // Yanıtı işleme
      _handleUploadResponse(responseMessage);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = "HTTP ile yükleme sırasında hata: $e";
        _isSuccess = false;
        _uploadingText = null;
      });
      print("HTTP yükleme hatası: $e");
    }
  }

  // Mobil için medya yükleme işlemi
  Future<void> _uploadMediaForMobile(String token) async {
    try {
      print('Dio ile hikaye yükleme başlatılıyor...');

      setState(() {
        _uploadingText = 'Yükleme hazırlanıyor...';
      });

      // Dosya adını alma
      final fileName = _mediaFile!.path.split('/').last;
      print('Dosya adı: $fileName');

      // Form verileri oluştur
      final formData = FormData();

      // Medya dosyasını MultipartFile'a dönüştürme
      final mediaFile = await MultipartFile.fromFile(
        _mediaFile!.path,
        filename: fileName,
      );

      // Dosyayı ve medya türünü ekle
      formData.files.add(MapEntry('file', mediaFile));
      formData.fields.add(MapEntry('mediaType', _isVideo ? 'video' : 'image'));
      print('Form data hazır: mediaType=${_isVideo ? "video" : "image"}');

      setState(() {
        _uploadingText = 'Bağlantı kuruluyor...';
      });

      // Dio client oluştur
      final dio = Dio(BaseOptions(
        baseUrl: 'http://192.168.89.61:8080/v1/api',
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));

      print('Dio istemcisi oluşturuldu, istek gönderiliyor...');

      // İsteği gönder
      final response = await dio.post(
        '/story/add',
        data: formData,
        onSendProgress: (sent, total) {
          final progress = (sent / total * 100).toStringAsFixed(1);
          print('Yükleme ilerlemesi: $progress%');
          setState(() {
            _uploadingText = 'Yükleniyor: $progress%';
          });
        },
      );

      print('Sunucu yanıtı: ${response.statusCode} - ${response.data}');

      setState(() {
        _uploadingText = 'İşlem tamamlandı!';
      });

      // Yanıtı ResponseMessage'a dönüştür
      final responseMessage = ResponseMessage(
        isSuccess: response.statusCode == 200,
        message: response.data['message'] ??
            response.data['error'] ??
            'Hikaye başarıyla yüklendi',
      );

      // Yanıtı işleme
      _handleUploadResponse(responseMessage);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = "Mobil cihazda yükleme sırasında hata: $e";
        _isSuccess = false;
        _uploadingText = null;
      });
      print("Mobil yükleme hatası: $e");

      if (e is DioException) {
        print("Dio hatası tipi: ${e.type}");
        print("Dio hata yanıtı: ${e.response}");
        print("Dio hata mesajı: ${e.message}");
      }
    }
  }

  // Yükleme yanıtını işleme
  void _handleUploadResponse(ResponseMessage response) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final successColor =
        themeProvider.currentTheme.colorScheme.tertiary ?? Colors.green;
    final errorColor = themeProvider.currentTheme.colorScheme.error;

    if (response.isSuccess) {
      setState(() {
        _isLoading = false;
        _message = response.message ?? "Hikaye başarıyla yüklendi!";
        _isSuccess = true;
        _uploadingText = null;

        // Medya değişkenlerini temizle
        _selectedMediaFile = null;
        _mediaFile = null;
        _webMediaBytes = null;
        _isVideo = false;
        _videoController?.dispose();
        _videoController = null;
      });

      // Başarılı animasyonu göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Hikaye başarıyla paylaşıldı!'),
            ],
          ),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 2),
        ),
      );

      // 2 saniye bekledikten sonra ana sayfaya dön
      Future.delayed(Duration(seconds: 2), () {
        Navigator.pop(
            context, true); // Yenileme gerektiğini belirtmek için true döndür
      });
    } else {
      setState(() {
        _isLoading = false;
        _message = response.message ?? "Hikaye eklenirken sunucu hatası.";
        _isSuccess = false;
      });

      // Hata mesajını göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(_message ?? 'Bir hata oluştu'),
              ),
            ],
          ),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPortrait = size.height > size.width;
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Tema renkleri
    final backgroundColor = themeProvider.currentTheme.scaffoldBackgroundColor;
    final cardColor = themeProvider.currentTheme.cardColor;
    final primaryColor = themeProvider.currentTheme.colorScheme.primary;
    final accentColor = themeProvider.currentTheme.colorScheme.secondary;
    final textColor = themeProvider.currentTheme.colorScheme.onBackground;
    final errorColor = themeProvider.currentTheme.colorScheme.error;
    final successColor =
        themeProvider.currentTheme.colorScheme.tertiary ?? Colors.green;

    // Tema tipi için özel renkler
    final overlayColor = _getOverlayColor(themeProvider.themeType);
    final cardBgColor = _getCardBackgroundColor(themeProvider.themeType);
    final buttonColor = _getButtonColor(themeProvider.themeType);

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Hikaye Ekle',
          style: TextStyle(
            color: textColor,
            letterSpacing: 0.5,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: IconThemeData(color: textColor),
        leading: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cardColor.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          if (_selectedMediaFile != null)
            Container(
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.check, size: 22, color: primaryColor),
                onPressed: _uploadStory,
                tooltip: 'Hikaye olarak paylaş',
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _getBackgroundGradient(themeProvider.themeType),
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _animation,
            child: Column(
              children: [
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ErrorToast(
                      message: _message ?? '',
                      duration: const Duration(seconds: 3),
                      maxLength: 60,
                      onDismiss: () {
                        setState(() {
                          _message = '';
                        });
                      },
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: _isLoading
                        ? _buildLoadingIndicator(primaryColor, textColor)
                        : _selectedMediaFile != null
                            ? _buildMediaPreview(isPortrait, size, primaryColor,
                                buttonColor, cardColor, textColor, overlayColor)
                            : _buildMediaSelectionOptions(
                                isPortrait,
                                size,
                                cardBgColor,
                                primaryColor,
                                textColor,
                                buttonColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Yükleme göstergesi
  Widget _buildLoadingIndicator(Color primaryColor, Color textColor) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              color: primaryColor,
              strokeWidth: 3.0,
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _uploadingText ?? 'İşleniyor...',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Medya önizleme
  Widget _buildMediaPreview(bool isPortrait, Size size, Color primaryColor,
      Color buttonColor, Color cardColor, Color textColor, Color overlayColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Story Görünümü Simülasyonu
        Container(
          height: isPortrait ? size.height * 0.6 : size.height * 0.7,
          width: isPortrait ? size.width * 0.85 : size.width * 0.5,
          margin: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.2),
                blurRadius: 20,
                offset: Offset(0, 8),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: Offset(0, 10),
                spreadRadius: 2,
              ),
            ],
            border: Border.all(
              color: primaryColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Medya İçeriği
              _isVideo ? _buildVideoPreview() : _buildImagePreview(),

              // Overlay Gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        overlayColor.withOpacity(0.4),
                        Colors.transparent,
                        Colors.transparent,
                        overlayColor.withOpacity(0.4),
                      ],
                      stops: const [0.0, 0.2, 0.8, 1.0],
                    ),
                  ),
                ),
              ),

              // Video Kontrolü
              if (_isVideo &&
                  _videoController != null &&
                  _videoController!.value.isInitialized)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer,
                          color: primaryColor,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        StreamBuilder(
                          stream: _videoController!.position.asStream(),
                          builder: (context, snapshot) {
                            final duration = snapshot.data ?? Duration.zero;
                            final seconds = duration.inSeconds;
                            final maxSeconds =
                                _videoController!.value.duration.inSeconds;
                            return Text(
                              '${seconds}s / ${maxSeconds}s',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

              // Medya Tipi İkonu
              Positioned(
                left: 16,
                top: 16,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _isVideo ? Icons.videocam : Icons.photo,
                    color: _isVideo ? Colors.red : Colors.cyan,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Kontrol Butonları
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedMediaFile = null;
                    _mediaFile = null;
                    _webMediaBytes = null;
                    _isVideo = false;
                    _videoController?.dispose();
                    _videoController = null;
                  });
                },
                icon: Icon(Icons.refresh, size: 18),
                label: Text('Yeni Medya'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textColor,
                  side: BorderSide(color: textColor.withOpacity(0.4)),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _uploadStory,
                icon: Icon(Icons.send, size: 18),
                label: Text('Paylaş'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  minimumSize: Size(130, 44),
                  elevation: 4,
                  shadowColor: buttonColor.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Video önizleme
  Widget _buildVideoPreview() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.currentTheme.colorScheme.primary;

    if (kIsWeb) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam,
                color: primaryColor.withOpacity(0.5),
                size: 50,
              ),
              SizedBox(height: 16),
              Text(
                'Web tarayıcısında\nvideo önizleme yapılamıyor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      if (_videoController != null && _videoController!.value.isInitialized) {
        return AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        );
      } else {
        return Container(
          color: Colors.black,
          child: Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: primaryColor,
                strokeWidth: 2.0,
              ),
            ),
          ),
        );
      }
    }
  }

  // Resim önizleme
  Widget _buildImagePreview() {
    if (kIsWeb) {
      return _webMediaBytes != null
          ? Image.memory(
              _webMediaBytes!,
              fit: BoxFit.cover,
            )
          : _buildImageErrorWidget();
    } else {
      return _mediaFile != null
          ? Image.file(
              _mediaFile!,
              fit: BoxFit.cover,
            )
          : _buildImageErrorWidget();
    }
  }

  Widget _buildImageErrorWidget() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.currentTheme.colorScheme.primary;

    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image,
              color: primaryColor.withOpacity(0.5),
              size: 50,
            ),
            SizedBox(height: 16),
            Text(
              'Görüntü yüklenemedi',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Medya seçim seçenekleri
  Widget _buildMediaSelectionOptions(
      bool isPortrait,
      Size size,
      Color cardBgColor,
      Color primaryColor,
      Color textColor,
      Color buttonColor) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPortrait ? 20 : size.width * 0.2,
        vertical: 30,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSvgIllustration(primaryColor, textColor), // SVG illustration
          SizedBox(height: 40),
          Text(
            'Hikayene Ne Eklemek İstersin?',
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Takipçilerinle paylaşmak için fotoğraf veya video seç',
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontSize: 15,
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 48),

          // Media option cards
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _buildMediaOptionCard(
                icon: Icons.camera_alt_outlined,
                label: 'Kamera',
                onTap: _getMediaFromCamera,
                cardBgColor: cardBgColor,
                textColor: textColor,
                iconColor: buttonColor,
              ),
              _buildMediaOptionCard(
                icon: Icons.photo_outlined,
                label: 'Galeri',
                onTap: _getPhotoFromGallery,
                cardBgColor: cardBgColor,
                textColor: textColor,
                iconColor: buttonColor,
              ),
              _buildMediaOptionCard(
                icon: Icons.videocam_outlined,
                label: 'Video',
                onTap: _getVideoFromGallery,
                cardBgColor: cardBgColor,
                textColor: textColor,
                iconColor: buttonColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // SVG Illustration placeholder
  Widget _buildSvgIllustration(Color primaryColor, Color textColor) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.2),
            primaryColor.withOpacity(0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.add_photo_alternate_outlined,
          size: 60,
          color: primaryColor.withOpacity(0.8),
        ),
      ),
    );
  }

  // Medya seçim kartı
  Widget _buildMediaOptionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color cardBgColor,
    required Color textColor,
    required Color iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 110,
          height: 120,
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: textColor.withOpacity(0.1), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withOpacity(0.15),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
              ),
              SizedBox(height: 16),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                icon == Icons.camera_alt_outlined
                    ? 'Hemen çek'
                    : icon == Icons.photo_outlined
                        ? 'Galeriden seç'
                        : 'Video ekle',
                style: TextStyle(
                  color: textColor.withOpacity(0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tema tipi için arka plan gradyeni
  List<Color> _getBackgroundGradient(ThemeType themeType) {
    switch (themeType) {
      case ThemeType.vaporwave:
        return [
          AppColors.vaporwaveBackground,
          Color(0xFF0A0118),
        ];
      case ThemeType.midnight:
        return [
          AppColors.midnightBackground,
          Color(0xFF091220),
        ];
      case ThemeType.nature:
        return [
          AppColors.natureBackground,
          Color(0xFF15211D),
        ];
      case ThemeType.cream:
        return [
          AppColors.creamBackground,
          Color(0xFFF3E9C6),
        ];
      case ThemeType.light:
        return [
          AppColors.lightBackground,
          Color(0xFFE8EAF0),
        ];
      default: // Dark
        return [
          AppColors.background,
          Color(0xFF0A0A0A),
        ];
    }
  }

  // Tema tipi için overlay rengi
  Color _getOverlayColor(ThemeType themeType) {
    switch (themeType) {
      case ThemeType.vaporwave:
        return AppColors.vaporwaveAccent;
      case ThemeType.midnight:
        return AppColors.midnightAccent;
      case ThemeType.nature:
        return AppColors.natureAccent;
      case ThemeType.cream:
        return Colors.brown;
      case ThemeType.light:
        return Colors.indigo;
      default: // Dark
        return Colors.purple;
    }
  }

  // Tema tipi için kart arkaplan rengi
  Color _getCardBackgroundColor(ThemeType themeType) {
    switch (themeType) {
      case ThemeType.vaporwave:
        return AppColors.vaporwaveCardBackground;
      case ThemeType.midnight:
        return AppColors.midnightCardBackground;
      case ThemeType.nature:
        return AppColors.natureCardBackground;
      case ThemeType.cream:
        return AppColors.creamCardBackground;
      case ThemeType.light:
        return AppColors.lightCardBackground;
      default: // Dark
        return AppColors.cardBackground;
    }
  }

  // Tema tipi için buton rengi
  Color _getButtonColor(ThemeType themeType) {
    switch (themeType) {
      case ThemeType.vaporwave:
        return AppColors.vaporwaveButtonBackground;
      case ThemeType.midnight:
        return AppColors.midnightButtonBackground;
      case ThemeType.nature:
        return AppColors.natureButtonBackground;
      case ThemeType.cream:
        return AppColors.creamButtonBackground;
      case ThemeType.light:
        return AppColors.lightButtonBackground;
      default: // Dark
        return AppColors.buttonBackground;
    }
  }
}
