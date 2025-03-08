import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media/services/postService.dart';
import 'package:social_media/services/followRelationService.dart';
import 'package:social_media/widgets/message_display.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:social_media/models/followed_user_dto.dart';
import 'package:social_media/models/response_message.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  // Medya değişkenleri
  List<XFile> _selectedMediaFiles = [];
  List<File> _mediaFiles = [];
  List<Uint8List> _webMediaBytes = [];
  List<bool> _isVideoList = [];
  List<VideoPlayerController?> _videoControllers = [];
  
  // Form değişkenleri
  String? _description;
  String? _location;
  List<String> _taggedPeople = [];
  final TextEditingController _tagController = TextEditingController();

  // Kullanıcı arama değişkenleri
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  final FollowRelationService _followService = FollowRelationService(Dio());

  int _currentStep = 0; // 0: Medya Seçimi, 1: Detaylar, 2: Önizleme ve Paylaşım
  
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;
  final PostService _postService = PostService(Dio());

  // Sayfa indeksi için değişken
  int _currentPageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _tagController.dispose();
    _searchController.dispose();
    
    for (final controller in _videoControllers) {
      controller?.dispose();
    }
    super.dispose();
  }

  // Kameradan fotoğraf çekme
  Future<void> _getMediaFromCamera() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70, // Kalite optimizasyonu
    );
    
    if (photo != null) {
      _addMedia(photo, false);
    }
  }

  // Galeriden fotoğraf ve video seçme
  Future<void> _getMediaFromGallery() async {
    final List<XFile>? mediaFiles = await _picker.pickMultiImage(
      imageQuality: 70, // Kalite optimizasyonu
    );

    if (mediaFiles != null && mediaFiles.isNotEmpty) {
      for (final mediaFile in mediaFiles) {
        // Medya türünü kontrol et
        if (mediaFile.mimeType!.startsWith('image/')) {
          _addMedia(mediaFile, false); // Fotoğraf
        } else if (mediaFile.mimeType!.startsWith('video/')) {
          _addMedia(mediaFile, true); // Video
        }
      }
    }
  }

  // Galeriden video seçme
  Future<void> _getVideoFromGallery() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 2), // Maksimum video süresi
    );

    if (video != null) {
      _addMedia(video, true); // Video
    }
  }

  // Medya ekleme
  void _addMedia(XFile mediaFile, bool isVideo) async {
    setState(() {
      _isLoading = true;
    });
    
    _selectedMediaFiles.add(mediaFile);
    _isVideoList.add(isVideo);
    
    if (kIsWeb) {
      // Web için medya işleme
      final bytes = await mediaFile.readAsBytes();
      setState(() {
        _webMediaBytes.add(bytes);
      });
    } else {
      // Mobil için medya işleme
      setState(() {
        _mediaFiles.add(File(mediaFile.path));
      });
    }
    
    // Video ise kontrolcü başlat
    if (isVideo) {
      if (kIsWeb) {
        _videoControllers.add(null);
      } else {
        final controller = VideoPlayerController.file(File(mediaFile.path));
        await controller.initialize();
        await controller.setLooping(true);
        _videoControllers.add(controller);
      }
    } else {
      _videoControllers.add(null);
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  // Medya silme
  void _removeMedia(int index) {
    setState(() {
      _selectedMediaFiles.removeAt(index);
      
      if (kIsWeb) {
        _webMediaBytes.removeAt(index);
      } else {
        _mediaFiles.removeAt(index);
      }
      
      final controller = _videoControllers[index];
      if (controller != null) {
        controller.dispose();
      }
      _videoControllers.removeAt(index);
      _isVideoList.removeAt(index);
    });
  }

  // Kişi etiketleme
  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_taggedPeople.contains(tag)) {
      setState(() {
        _taggedPeople.add(tag);
        _tagController.clear();
      });
    }
  }

  // Etiket silme
  void _removeTag(String tag) {
    setState(() {
      _taggedPeople.remove(tag);
    });
  }

  // Kişi etiketleme için kullanıcıları arama
  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';

      if (token.isEmpty) {
        setState(() {
          _isSearching = false;
          _message = "Oturum bilgisi bulunamadı";
          _isSuccess = false;
        });
        return;
      }

      // Call the searchFollowing method
      final response = await _followService.searchFollowing(token, query, 0);

      // Handle the response
      if (response.isSuccess && response.data != null) {
        final List<FollowedUserDTO> users = response.data!; // Null check ve force unwrap
        setState(() {
          _searchResults = users.map((user) => {
            'id': user.id,
            'username': user.username,
            'fullName': user.fullName,
            'profilePhotoUrl': user.profilePhotoUrl,
            'isActive': user.isActive,
            'isPrivate': user.isPrivate,
            'bio': user.bio,
            'popularityScore': user.popularityScore,
          }).toList();
          _isSearching = false;
        });
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
          _message = "Kullanıcılar aranırken bir hata oluştu";
          _isSuccess = false;
        });
      }
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _message = "Arama sırasında bir hata oluştu: $e";
        _isSuccess = false;
      });
      print("Arama hatası: $e");
    }
  }

  // Kullanıcıyı etiketle
  void _addUserTag(Map<String, dynamic> user) {
    if (!_taggedPeople.contains(user['username'])) {
      setState(() {
        _taggedPeople.add(user['username']);
        _searchController.clear();
        _searchResults = [];
      });
    }
  }

  // Sonraki adıma geçme
  void _nextStep() {
    print("Selected Media Files: ${_selectedMediaFiles.length}");
    if (_currentStep == 0 && _selectedMediaFiles.isEmpty) {
      setState(() {
        _message = "Lütfen en az bir fotoğraf veya video seçin";
        _isSuccess = false;
      });
      return;
    }
    
    setState(() {
      _currentStep += 1;
      _message = null;
    });
  }

  // Önceki adıma dönme
  void _previousStep() {
    setState(() {
      _currentStep -= 1;
      _message = null;
    });
  }

  // Gönderi paylaşma
  Future<void> _sharePost() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      // Medya kontrolleri
      print("Seçilen medya sayısı: ${_selectedMediaFiles.length}");
      print("Web medya sayısı: ${_webMediaBytes.length}");
      print("Mobil medya sayısı: ${_mediaFiles.length}");

      if (_selectedMediaFiles.isEmpty) {
        setState(() {
          _isLoading = false;
          _message = "Lütfen en az bir medya dosyası seçin.";
          _isSuccess = false;
        });
        return;
      }

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

      _description = _descriptionController.text.trim();
      _location = _locationController.text.trim();

      // Medya dosyalarını al
      final mediaMultipartFiles = await _getMediaMultipartFiles();

      // Check if media files are empty after conversion
      if (mediaMultipartFiles.isEmpty) {
        setState(() {
          _isLoading = false;
          if (kIsWeb && _webMediaBytes.isEmpty && _selectedMediaFiles.isNotEmpty) {
            _message = "Web tarayıcısında medya dosyaları doğru şekilde işlenemedi. Lütfen tekrar deneyin.";
          } else {
            _message = "Medya dosyaları dönüştürülemedi. Lütfen tekrar dosya seçin.";
          }
          _isSuccess = false;
        });
        return;
      }

      // PostService üzerinden gönderi ekleme
      final response = await _postService.addPost(
        token,
        _description,
        _location,
        _taggedPeople.isNotEmpty ? _taggedPeople : null,
        mediaMultipartFiles,
      );

      // Yanıtı işleme
      _handleUploadResponse(response);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = "Gönderi paylaşılırken bir hata oluştu: $e";
        _isSuccess = false;
      });
      print("Hata detayı: $e");
    }
  }

  // Medya dosyalarını MultipartFile'a dönüştürme
  Future<List<MultipartFile>> _getMediaMultipartFiles() async {
    List<MultipartFile> mediaMultipartFiles = [];
    
    // Web platformunda çalışıyorsa
    if (kIsWeb) {
      for (int i = 0; i < _webMediaBytes.length; i++) {
        final fileName = 'web_media_${DateTime.now().millisecondsSinceEpoch}_$i';
        final mimeType = _isVideoList[i] ? 'video/mp4' : 'image/jpeg';
        final multipartFile = MultipartFile.fromBytes(
          _webMediaBytes[i],
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        );
        mediaMultipartFiles.add(multipartFile);
      }
    } 
    // Mobil platformda çalışıyorsa
    else {
      for (int i = 0; i < _mediaFiles.length; i++) {
        final fileName = _mediaFiles[i].path.split('/').last;
        final multipartFile = await MultipartFile.fromFile(
          _mediaFiles[i].path,
          filename: fileName,
        );
        mediaMultipartFiles.add(multipartFile);
      }
    }
    
    print("Dönüştürülen medya dosyası sayısı: ${mediaMultipartFiles.length}");
    return mediaMultipartFiles;
  }

  // Yükleme yanıtını işleme
  void _handleUploadResponse(ResponseMessage response) {
    if (response.isSuccess) {
      final message = response.message ?? 'Gönderi başarıyla paylaşıldı';
      
      setState(() {
        _isLoading = false;
        _message = message; // Backend'den gelen mesajı ilet
        _isSuccess = true;

        // Değişkenleri temizle
        _selectedMediaFiles = [];
        _mediaFiles = [];
        _webMediaBytes = [];
        _isVideoList = [];
        _videoControllers.forEach((controller) => controller?.dispose());
        _videoControllers = [];
        _descriptionController.clear();
        _locationController.clear();
        _taggedPeople = [];
        _currentStep = 0;
      });

      // 2 saniye bekledikten sonra ana sayfaya dön
      Future.delayed(Duration(seconds: 2), () {
        Navigator.pop(context, true); // Yenileme gerektiğini belirtmek için true döndür
      });
    } else {
      final message = response.message ?? 'Gönderi paylaşılırken sunucu hatası';
      
      setState(() {
        _isLoading = false;
        _message = message; // Backend'den gelen hata mesajını ilet
        _isSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          _getAppBarTitle(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _currentStep > 0 ? _previousStep : () => Navigator.pop(context),
        ),
        actions: _currentStep == 2 ? [
          IconButton(
            icon: Icon(Icons.check, color: Colors.white),
            onPressed: _sharePost,
          ),
        ] : [],
      ),
      body: Column(
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
            child: _isLoading
                ? _buildLoadingIndicator()
                : _buildCurrentStep(),
          ),
          if (_currentStep < 2)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text(
                  _currentStep == 0 ? 'Devam Et' : 'Önizleme ve Paylaş',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Adıma göre başlık belirleme
  String _getAppBarTitle() {
    switch (_currentStep) {
      case 0:
        return 'Medya Seç';
      case 1:
        return 'Detaylar';
      case 2:
        return 'Önizleme ve Paylaş';
      default:
        return 'Gönderi Oluştur';
    }
  }

  // Yükleme göstergesi
  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Colors.white),
        SizedBox(height: 16),
        Text(
          'İşlem gerçekleştiriliyor...',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }

  // Güncel adıma göre içerik gösterme
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildMediaSelectionStep();
      case 1:
        return _buildDetailsStep();
      case 2:
        return _buildPreviewStep();
      default:
        return Container();
    }
  }

  // Adım 1: Medya seçimi
  Widget _buildMediaSelectionStep() {
    return Column(
      children: [
        // Seçilen medyalar
        if (_selectedMediaFiles.isNotEmpty)
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _selectedMediaFiles.length,
              itemBuilder: (context, index) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: _buildMediaThumbnail(index),
                      ),
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: () => _removeMedia(index),
                        child: Container(
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                    if (_isVideoList[index])
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: Container(
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.videocam, color: Colors.white, size: 16),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        
        // Medya seçim seçenekleri
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMediaOptionButton(
                icon: Icons.camera_alt,
                label: 'Kamera',
                onTap: _getMediaFromCamera,
              ),
              _buildMediaOptionButton(
                icon: Icons.photo,
                label: 'Fotoğraf',
                onTap: _getMediaFromGallery,
              ),
              _buildMediaOptionButton(
                icon: Icons.videocam,
                label: 'Video',
                onTap: _getVideoFromGallery,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Adım 2: Detaylar
  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Açıklama alanı
          Text(
            'Açıklama',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 5,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Gönderinizi açıklayın...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
          SizedBox(height: 24),
          
          // Konum alanı
          Text(
            'Konum',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _locationController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Konum ekleyin...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white),
              ),
              prefixIcon: Icon(Icons.location_on, color: Colors.white.withOpacity(0.7)),
            ),
          ),
          SizedBox(height: 24),
          
          // Kişi etiketleme alanı
          Text(
            'Kişileri Etiketle',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Column(
            children: [
              // Arama alanı
              TextField(
                controller: _searchController,
                style: TextStyle(color: Colors.white),
                onChanged: (value) => _searchUsers(value),
                decoration: InputDecoration(
                  hintText: 'Kullanıcı ara...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.7)),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchResults = [];
                            });
                          },
                        )
                      : null,
                ),
              ),
              
              // Arama sonuçları
              if (_isSearching)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
                
              if (_searchResults.isNotEmpty)
                Container(
                  height: 200,
                  margin: EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade800,
                          backgroundImage: user['profilePhotoUrl'] != null && user['profilePhotoUrl'].isNotEmpty
                              ? NetworkImage(user['profilePhotoUrl'])
                              : null,
                          child: user['profilePhotoUrl'] == null || user['profilePhotoUrl'].isEmpty
                              ? Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        title: Text(
                          user['username'] ?? '',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          user['fullName'] ?? '',
                          style: TextStyle(color: Colors.white.withOpacity(0.7)),
                        ),
                        trailing: user['isPrivate'] == true
                            ? Icon(Icons.lock, color: Colors.white.withOpacity(0.5), size: 16)
                            : null,
                        onTap: () => _addUserTag(user),
                      );
                    },
                  ),
                ),
              
              SizedBox(height: 16),
              
              // Manuel etiketleme alanı
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Veya manuel ekleyin...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        prefixIcon: Icon(Icons.person_add, color: Colors.white.withOpacity(0.7)),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    onPressed: _addTag,
                    icon: Icon(Icons.add, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          
          // Etiketlenen kişilerin listesi
          if (_taggedPeople.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _taggedPeople.map((tag) {
                return Chip(
                  label: Text(tag),
                  labelStyle: TextStyle(color: Colors.black),
                  backgroundColor: Colors.white,
                  deleteIcon: Icon(Icons.close, size: 16),
                  onDeleted: () => _removeTag(tag),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // Adım 3: Önizleme
  Widget _buildPreviewStep() {
    return Column(
      children: [
        // Medya önizleme
        Expanded(
          child: Stack(
            children: [
              // Medya gösterimi için PageView
              PageView.builder(
                controller: _pageController,
                itemCount: _selectedMediaFiles.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPageIndex = index;
                    
                    // Sayfa değiştiğinde video kontrolcüsünü güncelle
                    for (int i = 0; i < _videoControllers.length; i++) {
                      if (_videoControllers[i] != null && i != index && _isVideoList[i]) {
                        _videoControllers[i]!.pause();
                      }
                    }
                    
                    // Geçerli sayfadaki videonun oynatılması
                    if (_isVideoList[index] && _videoControllers[index] != null && !kIsWeb) {
                      _videoControllers[index]!.play();
                    }
                  });
                },
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _isVideoList[index]
                        ? _buildVideoPreview(index)
                        : _buildImagePreview(index),
                  );
                },
              ),
              
              // Sayfa göstergesi
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _selectedMediaFiles.length,
                    (index) => AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(horizontal: 3),
                      height: 8,
                      width: _currentPageIndex == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPageIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Sayfa numarası göstergesi
              if (_selectedMediaFiles.length > 1)
                Positioned(
                  top: 25,
                  right: 25,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentPageIndex + 1}/${_selectedMediaFiles.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              
              // Önceki/sonraki medya gezinme butonları
              if (_selectedMediaFiles.length > 1)
                Positioned.fill(
                  child: Row(
                    children: [
                      // Önceki medya
                      GestureDetector(
                        onTap: () {
                          if (_currentPageIndex > 0) {
                            _pageController.previousPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Container(
                          width: 60,
                          color: Colors.transparent,
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Spacer(),
                      // Sonraki medya
                      GestureDetector(
                        onTap: () {
                          if (_currentPageIndex < _selectedMediaFiles.length - 1) {
                            _pageController.nextPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Container(
                          width: 60,
                          color: Colors.transparent,
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        // Gönderi detayları
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 0,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kullanıcı bilgisi ve zaman
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    child: Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Önizleme',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'Şimdi',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              
              // Açıklama
              if (_descriptionController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _descriptionController.text,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              
              // Konum
              if (_locationController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        _locationController.text,
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                      ),
                    ],
                  ),
                ),
              
              // Etiketler
              if (_taggedPeople.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Wrap(
                    spacing: 8,
                    children: _taggedPeople.map((tag) {
                      return Text(
                        '@$tag',
                        style: TextStyle(color: Colors.blue, fontSize: 14),
                      );
                    }).toList(),
                  ),
                ),
              
              // Medya bilgisi
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.photo_library, 
                      color: Colors.white.withOpacity(0.7), 
                      size: 16
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${_selectedMediaFiles.length} medya',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Paylaş butonu
              ElevatedButton(
                onPressed: _sharePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: Size(double.infinity, 50),
                ),
                child: _isLoading 
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      ) 
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Paylaş',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Medya seçim butonu
  Widget _buildMediaOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Medya küçük resmi
  Widget _buildMediaThumbnail(int index) {
    if (_isVideoList[index]) {
      // Video küçük resmi
      return kIsWeb
          ? Container(
              color: Colors.black,
              child: Center(
                child: Icon(Icons.videocam, color: Colors.white),
              ),
            )
          : _videoControllers[index] != null && _videoControllers[index]!.value.isInitialized
              ? VideoPlayer(_videoControllers[index]!)
              : Container(
                  color: Colors.black,
                  child: Center(
                    child: Icon(Icons.videocam, color: Colors.white),
                  ),
                );
    } else {
      // Resim küçük resmi
      return kIsWeb
          ? Image.memory(
              _webMediaBytes[index],
              fit: BoxFit.cover,
            )
          : Image.file(
              _mediaFiles[index],
              fit: BoxFit.cover,
            );
    }
  }

  // Video önizleme
  Widget _buildVideoPreview(int index) {
    if (kIsWeb) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam, color: Colors.white, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Web tarayıcısında video önizleme',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      );
    } else {
      final controller = _videoControllers[index];
      if (controller != null && controller.value.isInitialized) {
        return GestureDetector(
          onTap: () {
            setState(() {
              if (controller.value.isPlaying) {
                controller.pause();
              } else {
                controller.play();
              }
            });
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(controller),
              if (!controller.value.isPlaying)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
            ],
          ),
        );
      } else {
        return Container(
          color: Colors.black,
          child: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
      }
    }
  }

  // Resim önizleme
  Widget _buildImagePreview(int index) {
    if (kIsWeb) {
      return _webMediaBytes.isNotEmpty
          ? Image.memory(
              _webMediaBytes[index],
              fit: BoxFit.contain,
            )
          : Container(
              color: Colors.black,
              child: Center(
                child: Text(
                  'Resim yüklenemedi',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
    } else {
      return _mediaFiles.isNotEmpty
          ? Image.file(
              _mediaFiles[index],
              fit: BoxFit.contain,
            )
          : Container(
              color: Colors.black,
              child: Center(
                child: Text(
                  'Resim yüklenemedi',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
    }
  }
} 