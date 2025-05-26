import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media/models/home_story_dto.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:social_media/services/storyService.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:line_icons/line_icons.dart';
import 'dart:math' as math;
import 'package:social_media/screens/no_story_screen.dart';
import 'package:provider/provider.dart';
import 'package:social_media/theme/theme_provider.dart';

class StoryViewerScreen extends StatefulWidget {
  final HomeStoryDTO story;
  final List<HomeStoryDTO> allStories;
  final int initialIndex;

  const StoryViewerScreen({
    Key? key,
    required this.story,
    required this.allStories,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  _StoryViewerScreenState createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentStoryIndex = 0;
  int _currentUserIndex = 0;
  Timer? _timer;
  bool _isLoading = true;
  final StoryService _storyService = StoryService(Dio());
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();

    print(
        "StoryViewerScreen - initializing with ${widget.allStories.length} stories");
    print(
        "Initial story: ${widget.story.username}, photos: ${widget.story.photos.length}");

    // Debug all stories for verification
    for (int i = 0; i < widget.allStories.length; i++) {
      final story = widget.allStories[i];
      print(
          "Story $i - User: ${story.username}, Photos: ${story.photos.length}");
      if (story.photos.isNotEmpty) {
        print("  First photo URL: ${story.photos.first}");
      } else {
        print("  No photos available");
      }
    }

    // Hikayeleri kontrol et ve foto olmadığında NoStoryScreen'e yönlendir
    if (widget.story.photos.isEmpty) {
      print("Story has no photos, will redirect to NoStoryScreen");
      // initState içinde Navigator kullanabilmek için Future.microtask kullanıyoruz
      Future.microtask(() {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => NoStoryScreen(
              message: 'Bu Kullanıcının Hikayesi Bulunamadı',
              subMessage:
                  '${widget.story.username} kullanıcısının henüz bir hikayesi yok veya hikaye yüklenemedi.',
              isError: false,
              onRetry: () => _reloadStories(),
              onReturn: () => Navigator.of(context).pop(),
            ),
          ),
        );
      });
      return;
    }

    _currentUserIndex = widget.initialIndex;
    _currentStoryIndex = 0;
    _pageController = PageController(initialPage: _currentUserIndex);

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 5000), // 5 saniye
    );

    // Durum çubuğunu gizle
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );

    _loadStories();

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    // Hikaye görüntülendiğinde sunucuya bildir
    _markStoryAsViewed();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _timer?.cancel();

    // Durum çubuğunu geri getir
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );

    super.dispose();
  }

  Future<void> _loadStories() async {
    setState(() {
      _isLoading = true;
    });

    print("Loading stories in viewer");

    // Eğer veri zaten yüklüyse doğrudan gösterelim
    if (widget.story.photos.isNotEmpty) {
      print(
          "Story already has ${widget.story.photos.length} photos, showing directly");
      setState(() {
        _isLoading = false;
      });
      _startStoryTimer();
      return;
    } else {
      print("Story has no photos, trying to fetch story details");
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      // Hikaye ID ile detayları yüklemeyi dene
      bool storyDetailsLoaded = false;
      if (widget.story.storyId.isNotEmpty) {
        print(
            "Trying to load story details using storyId: ${widget.story.storyId.first}");
        // final response = await _storyService.getStoryDetails(accessToken, widget.story.storyId[0]);
        // API implementasyonu yoksa aşağıdaki satırı kullanabilirsiniz:
        // storyDetailsLoaded = true; // Başarılı olduğunu varsay
      }

      setState(() {
        _isLoading = false;
      });

      // Hala hikaye fotoğrafı yoksa NoStoryScreen'e yönlendir
      if (widget.story.photos.isEmpty && !storyDetailsLoaded) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => NoStoryScreen(
              message: 'Hikaye Bulunamadı',
              subMessage:
                  'Bu hikaye şu anda görüntülenemiyor veya silinmiş olabilir.',
              isError: true,
              onRetry: () => _reloadStories(),
              onReturn: () => Navigator.of(context).pop(),
            ),
          ),
        );
        return;
      }

      _startStoryTimer();
    } catch (e) {
      print('Hikaye yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });

      // Hata durumunda NoStoryScreen'e yönlendir
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => NoStoryScreen(
            message: 'Hata Oluştu',
            subMessage:
                'Hikaye yüklenirken bir sorun oluştu. Lütfen daha sonra tekrar deneyin.',
            isError: true,
            onRetry: () => _reloadStories(),
            onReturn: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }
  }

  // Hikayeleri yeniden yükle
  void _reloadStories() {
    _loadStories();
  }

  Future<void> _markStoryAsViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      // Eğer API'niz destekliyorsa, hikayeyi görüntülendi olarak işaretleyin
      // await _storyService.markStoryAsViewed(accessToken, widget.allStories[_currentUserIndex].storyId[_currentStoryIndex]);
    } catch (e) {
      print('Hikaye görüntülendi olarak işaretlenirken hata: $e');
    }
  }

  void _startStoryTimer() {
    // Önceki zamanlayıcıyı iptal et
    _timer?.cancel();

    // Animasyonu başlat
    _animationController.forward(from: 0.0);
  }

  void _nextStory() {
    final HomeStoryDTO currentUserStory = widget.allStories[_currentUserIndex];
    final int storiesCount = currentUserStory.photos.length;

    // Kullanıcının son hikayesi mi?
    if (_currentStoryIndex < storiesCount - 1) {
      setState(() {
        _currentStoryIndex++;
      });
      _startStoryTimer();
      _markStoryAsViewed();
    } else {
      // Son kullanıcı mı?
      if (_currentUserIndex < widget.allStories.length - 1) {
        setState(() {
          _currentUserIndex++;
          _currentStoryIndex = 0;
          _pageController.animateToPage(
            _currentUserIndex,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
        _startStoryTimer();
        _markStoryAsViewed();
      } else {
        // Tüm hikayeler bitti, geri dön
        Navigator.of(context).pop();
      }
    }
  }

  void _previousStory() {
    // Aynı kullanıcının önceki hikayesi var mı?
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
      });
      _startStoryTimer();
      _markStoryAsViewed();
    } else {
      // Önceki kullanıcı var mı?
      if (_currentUserIndex > 0) {
        setState(() {
          _currentUserIndex--;
          final previousUserStory = widget.allStories[_currentUserIndex];
          _currentStoryIndex = previousUserStory.photos.length - 1;
          _pageController.animateToPage(
            _currentUserIndex,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
        _startStoryTimer();
        _markStoryAsViewed();
      }
    }
  }

  void _onTapDown(TapDownDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final xPos = details.globalPosition.dx;

    // Ekranın sol %30'una dokunuldu
    if (xPos < screenWidth * 0.3) {
      _previousStory();
    }
    // Ekranın sağ %30'una dokunuldu
    else if (xPos > screenWidth * 0.7) {
      _nextStory();
    }
    // Ekranın ortasına dokunuldu (duraklat/devam)
    else {
      setState(() {
        _isPaused = !_isPaused;
        if (_isPaused) {
          _animationController.stop();
        } else {
          _animationController.forward();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Tema durumuna göre değişen renkler
    final backgroundColor = themeProvider.isDarkMode
        ? Colors.black
        : Color(0xFF121212).withOpacity(0.9); // Açık tema için daha açık ton

    final overlayColor = themeProvider.isDarkMode
        ? Colors.black.withOpacity(0.7)
        : Colors.grey[800]!.withOpacity(0.7);

    final textColor =
        Colors.white; // Hikaye ekranında metin her zaman beyaz olsun

    final accentColor = themeProvider.isDarkMode
        ? Color(0xFF00A8CC)
        : Theme.of(context).primaryColor;

    final secondaryColor = themeProvider.isDarkMode
        ? Color(0xFF45C4B0)
        : Theme.of(context).colorScheme.secondary;

    final borderColor =
        themeProvider.isDarkMode ? Colors.white : Colors.white.withOpacity(0.8);

    final progressBarColor =
        themeProvider.isDarkMode ? Colors.white : Colors.white.withOpacity(0.9);

    final progressBarBgColor = themeProvider.isDarkMode
        ? Colors.white.withOpacity(0.5)
        : Colors.white.withOpacity(0.4);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: GestureDetector(
        onTapDown: _onTapDown,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: accentColor))
            : PageView.builder(
                controller: _pageController,
                physics:
                    NeverScrollableScrollPhysics(), // Manuel geçişleri kontrol edeceğiz
                itemCount: widget.allStories.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentUserIndex = index;
                    _currentStoryIndex = 0;
                  });
                  _startStoryTimer();
                  _markStoryAsViewed();
                },
                itemBuilder: (context, userIndex) {
                  final HomeStoryDTO userStory = widget.allStories[userIndex];
                  final List<String> storyPhotos = userStory.photos;

                  print(
                      "Building story for user: ${userStory.username}, photos: ${storyPhotos.length}, current index: $_currentStoryIndex");

                  if (storyPhotos.isEmpty) {
                    print("WARNING: No photos for ${userStory.username}");
                    // Show an empty state for this story
                    return Container(
                      color: backgroundColor,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported,
                                color: textColor, size: 64),
                            SizedBox(height: 16),
                            Text(
                              "Bu hikayede görüntülenecek içerik bulunamadı",
                              style: TextStyle(color: textColor, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Make sure _currentStoryIndex is valid for this user's stories
                  int displayIndex = userIndex == _currentUserIndex
                      ? math.min(_currentStoryIndex, storyPhotos.length - 1)
                      : 0;

                  String imageUrl = storyPhotos[displayIndex];
                  print("Displaying image at index $displayIndex: $imageUrl");

                  return Container(
                    color: backgroundColor,
                    child: Stack(
                      children: [
                        // Hikaye içeriği
                        Positioned.fill(
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: overlayColor,
                              child: Center(
                                child: CircularProgressIndicator(
                                    color: accentColor),
                              ),
                            ),
                            errorWidget: (context, url, error) {
                              print(
                                  "Error loading story image: $error, URL: $url");
                              return Container(
                                color: overlayColor,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error,
                                          color: textColor, size: 40),
                                      SizedBox(height: 16),
                                      Text(
                                        "Görsel yüklenemedi",
                                        style: TextStyle(
                                            color: textColor, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Karanlık overlay (daha iyi kontrast için)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.center,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        // İlerleme çubukları
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 10,
                          left: 10,
                          right: 10,
                          child: Row(
                            children: List.generate(
                              storyPhotos.length,
                              (index) => Expanded(
                                child: Container(
                                  height: 3,
                                  margin: EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: index < _currentStoryIndex
                                        ? progressBarColor
                                        : progressBarBgColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: index == _currentStoryIndex
                                      ? AnimatedBuilder(
                                          animation: _animationController,
                                          builder: (context, child) {
                                            return FractionallySizedBox(
                                              widthFactor:
                                                  _animationController.value,
                                              alignment: Alignment.centerLeft,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: progressBarColor,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Kullanıcı bilgileri
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 20,
                          left: 10,
                          right: 10,
                          child: Row(
                            children: [
                              // Profil fotoğrafı
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: borderColor, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 5,
                                        spreadRadius: 0,
                                      )
                                    ]),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: CachedNetworkImage(
                                    imageUrl: userStory.profilePhoto,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: themeProvider.isDarkMode
                                          ? Colors.grey[900]
                                          : Colors.grey[200],
                                      child: Center(
                                          child: Icon(LineIcons.user,
                                              color: accentColor, size: 20)),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      color: themeProvider.isDarkMode
                                          ? Colors.grey[900]
                                          : Colors.grey[200],
                                      child: Center(
                                          child: Icon(
                                              LineIcons.exclamationCircle,
                                              color: Colors.red,
                                              size: 20)),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              // Kullanıcı adı
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    userStory.username,
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.5),
                                          blurRadius: 5,
                                        )
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '• Şimdi',
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.8),
                                      fontSize: 13,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.5),
                                          blurRadius: 5,
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Spacer(),
                              // Kapat butonu
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black38,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: textColor,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Hikaye kontrolleri
                        _isPaused
                            ? Center(
                                child: Container(
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.play_arrow,
                                    color: secondaryColor,
                                    size: 50,
                                  ),
                                ),
                              )
                            : SizedBox.shrink(),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
