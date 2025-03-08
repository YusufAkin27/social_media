import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media/services/storyService.dart';
import 'package:social_media/widgets/message_display.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:social_media/models/followed_user_dto.dart';
import 'package:social_media/models/response_message.dart';

class AddStoryScreen extends StatefulWidget {
  const AddStoryScreen({Key? key}) : super(key: key);

  @override
  _AddStoryScreenState createState() => _AddStoryScreenState();
}

class _AddStoryScreenState extends State<AddStoryScreen> with SingleTickerProviderStateMixin {
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
          _message = "Web'de video önizleme desteklenmemektedir, ancak video yükleyebilirsiniz.";
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
        await _uploadMediaForMobile(token);
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
      // Web için multipart request oluşturuyoruz
      final url = Uri.parse('http://localhost:8080/v1/api/story/add');
      
      // HTTP isteği oluşturma
      var request = http.MultipartRequest('POST', url);
      
      // Token ekleme
      request.headers['Authorization'] = 'Bearer $token';
      
      // Dosya adını alma
      final fileName = _selectedMediaFile!.name;
      
      // Medya verilerini ekleme
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        _webMediaBytes!,
        filename: fileName,
      );
      
      request.files.add(multipartFile);
      
      // İsteği gönderme ve cevabı alma
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      // Convert http.Response to ResponseMessage
      final responseMessage = ResponseMessage(
        isSuccess: response.statusCode == 200,
        message: response.body, // Adjust this based on your API response structure
      );

      // Yanıtı işleme
      _handleUploadResponse(responseMessage);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = "Web'de yükleme sırasında hata: $e";
        _isSuccess = false;
      });
      print("Web yükleme hatası: $e");
    }
  }

  // Mobil için medya yükleme işlemi
  Future<void> _uploadMediaForMobile(String token) async {
    try {
      // Dosya adını alma
      final fileName = _mediaFile!.path.split('/').last;
      
      // Medya dosyasını MultipartFile'a dönüştürme
      final formData = await MultipartFile.fromFile(
        _mediaFile!.path,
        filename: fileName,
      );

      // StoryService üzerinden hikaye ekleme
      final response = await _storyService.add(token, formData);
      
      // Yanıtı işleme
      _handleUploadResponse(response);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = "Mobil cihazda yükleme sırasında hata: $e";
        _isSuccess = false;
      });
      print("Mobil yükleme hatası: $e");
    }
  }

  // Yükleme yanıtını işleme
  void _handleUploadResponse(ResponseMessage response) {
    if (response.isSuccess) {
      setState(() {
        _isLoading = false;
        _message = response.message ?? "Hikaye başarıyla yüklendi!";
        _isSuccess = true;
        
        // Medya değişkenlerini temizle
        _selectedMediaFile = null;
        _mediaFile = null;
        _webMediaBytes = null;
        _isVideo = false;
        _videoController?.dispose();
        _videoController = null;
      });

      // 2 saniye bekledikten sonra ana sayfaya dön
      Future.delayed(Duration(seconds: 2), () {
        Navigator.pop(context, true); // Yenileme gerektiğini belirtmek için true döndür
      });
    } else {
      setState(() {
        _isLoading = false;
        _message = response.message ?? "Hikaye eklenirken sunucu hatası.";
        _isSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPortrait = size.height > size.width;
    
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          onPrimary: Colors.black,
          secondary: Colors.white70,
          onSecondary: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w300, fontSize: 20),
          bodyLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w300),
          bodyMedium: TextStyle(color: Colors.white70, fontWeight: FontWeight.w300),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          labelStyle: TextStyle(color: Colors.white70),
          hintStyle: TextStyle(color: Colors.white38),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            minimumSize: const Size(100, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white, width: 1),
            foregroundColor: Colors.white,
            minimumSize: const Size(100, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 15,
            ),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Hikaye Ekle',
            style: TextStyle(
              letterSpacing: 0.5,
              fontWeight: FontWeight.w300,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (_selectedMediaFile != null)
              IconButton(
                icon: Icon(Icons.check, size: 24),
                onPressed: _uploadStory,
                tooltip: 'Hikaye olarak paylaş',
              ),
          ],
        ),
        body: SafeArea(
          child: FadeTransition(
            opacity: _animation,
            child: Column(
              children: [
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: MessageDisplay(
                      message: _message!,
                      isSuccess: _isSuccess,
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: _isLoading
                        ? _buildLoadingIndicator()
                        : _selectedMediaFile != null
                            ? _buildMediaPreview(isPortrait, size)
                            : _buildMediaSelectionOptions(isPortrait, size),
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
  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.0,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'İşleniyor...',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // Medya önizleme
  Widget _buildMediaPreview(bool isPortrait, Size size) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Story Görünümü Simülasyonu
        Container(
          height: isPortrait ? size.height * 0.6 : size.height * 0.7,
          width: isPortrait ? size.width * 0.85 : size.width * 0.5,
          margin: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 15,
                offset: Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Medya İçeriği
              _isVideo
                  ? _buildVideoPreview()
                  : _buildImagePreview(),
                  
              // Overlay Gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.4),
                      ],
                      stops: const [0.0, 0.2, 0.8, 1.0],
                    ),
                  ),
                ),
              ),
              
              // Video Kontrolü
              if (_isVideo && _videoController != null && _videoController!.value.isInitialized)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StreamBuilder(
                          stream: _videoController!.position.asStream(),
                          builder: (context, snapshot) {
                            final duration = snapshot.data ?? Duration.zero;
                            final seconds = duration.inSeconds;
                            final maxSeconds = _videoController!.value.duration.inSeconds;
                            return Text(
                              '${seconds}s / ${maxSeconds}s',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            );
                          },
                        ),
                      ],
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
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white38),
                ),
              ),
              SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _uploadStory,
                icon: Icon(Icons.send, size: 18),
                label: Text('Paylaş'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(130, 44),
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
    if (kIsWeb) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam,
                color: Colors.white.withOpacity(0.5),
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
                color: Colors.white,
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
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image,
              color: Colors.white.withOpacity(0.5),
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
  Widget _buildMediaSelectionOptions(bool isPortrait, Size size) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isPortrait ? 20 : size.width * 0.2,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSvgIllustration(), // SVG illustration
          SizedBox(height: 40),
          Text(
            'Hikayene Ne Eklemek İstersin?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w200,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Takipçilerinle paylaşmak için fotoğraf veya video seç',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
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
              ),
              _buildMediaOptionCard(
                icon: Icons.photo_outlined,
                label: 'Galeri',
                onTap: _getPhotoFromGallery,
              ),
              _buildMediaOptionCard(
                icon: Icons.videocam_outlined,
                label: 'Video',
                onTap: _getVideoFromGallery,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // SVG Illustration placeholder
  Widget _buildSvgIllustration() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Center(
        child: Icon(
          Icons.add_photo_alternate_outlined,
          size: 60,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  // Medya seçim kartı
  Widget _buildMediaOptionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}