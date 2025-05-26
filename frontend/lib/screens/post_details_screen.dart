import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media/services/postService.dart';
import 'package:social_media/models/post_dto.dart';
import 'package:social_media/models/data_response_message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:social_media/widgets/profile_avatar_widget.dart';
import 'package:like_button/like_button.dart';
import 'package:shimmer/shimmer.dart';
import 'package:social_media/widgets/video_player_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:social_media/theme/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:social_media/theme/theme_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:social_media/screens/user_profile_screen.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';

class PostDetailsScreen extends StatefulWidget {
  final String postId;

  const PostDetailsScreen({Key? key, required this.postId}) : super(key: key);

  @override
  _PostDetailsScreenState createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen>
    with SingleTickerProviderStateMixin {
  final PostService _postService = PostService();
  late Future<DataResponseMessage<PostDTO>> _postDetailsFuture;
  bool isLiked = false;
  bool isSaved = false;
  int _currentImageIndex = 0;
  late AnimationController _likeAnimationController;
  String? _errorMessage;

  // Ek animasyon ve etkileşim için değişkenler
  bool _isDescriptionExpanded = false;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolling = false;
  final double _mediaMaxHeight = 500.0;

  // Video oynatma kontrolü
  bool _isVideoPlaying = true;

  @override
  void initState() {
    super.initState();

    // _postDetailsFuture'ı başlat
    _postDetailsFuture = Future.value(DataResponseMessage<PostDTO>(
      message: 'Yükleniyor...',
      data: null,
      isSuccess: true,
    ));

    _loadPostDetails();

    // Like animation controller
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    // Scroll kontrolcüsü dinleyicisi ekle
    _scrollController.addListener(() {
      final isScrolling = _scrollController.position.isScrollingNotifier.value;
      if (_isScrolling != isScrolling) {
        setState(() {
          _isScrolling = isScrolling;
        });
      }
    });

    // Sistem UI görünümünü ayarla
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    // Tam ekran modu için
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _scrollController.dispose();
    // Sistem UI'ı normale döndür
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    super.dispose();
  }

  Future<void> _loadPostDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';

    try {
      print('Gönderi detayları yükleniyor: ${widget.postId}');

      // Yükleme öncesi hafif gecikme ekle (animasyonların düzgün görünmesi için)
      await Future.delayed(const Duration(milliseconds: 300));

      // Doğrudan HTTP isteği yaparak gönderi detaylarını al
      final response = await http.get(
        Uri.parse(
            'http://192.168.89.61:8080/v1/api/post/details/${widget.postId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('API yanıtı: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final postData = PostDTO.fromJson(responseData['data']);

          // İşlem başarılı haptic feedback
          HapticFeedback.lightImpact();

          setState(() {
            _postDetailsFuture = Future.value(DataResponseMessage<PostDTO>(
              message: responseData['message'] ??
                  'Gönderi detayları başarıyla getirildi.',
              data: postData,
              isSuccess: true,
            ));

            // Beğeni durumunu ayarla
            isLiked = postData.isLiked;

            // Kaydetme durumunu kontrol et
            _checkIfSaved(token, widget.postId);
          });
        } else {
          setState(() {
            _errorMessage = responseData['message'] ?? 'Gönderi bulunamadı';
            _postDetailsFuture = Future.value(DataResponseMessage<PostDTO>(
              message: _errorMessage!,
              data: null,
              isSuccess: false,
            ));
          });
        }
      } else {
        setState(() {
          _errorMessage = 'API yanıt hatası: ${response.statusCode}';
          _postDetailsFuture = Future.value(DataResponseMessage<PostDTO>(
            message: _errorMessage!,
            data: null,
            isSuccess: false,
          ));
        });
      }
    } catch (e) {
      print('Gönderi detayları yüklenirken hata: $e');
      setState(() {
        _errorMessage = 'Gönderi detayları yüklenirken bir hata oluştu: $e';
        _postDetailsFuture = Future.value(DataResponseMessage<PostDTO>(
          message: _errorMessage!,
          data: null,
          isSuccess: false,
        ));
      });
    }
  }

  // Gönderinin kaydedilip kaydedilmediğini kontrol et
  Future<void> _checkIfSaved(String token, String postId) async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://192.168.89.61:8080/v1/api/post/recorded/$postId/check'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Spring Boot API doğrudan boolean değer döndürüyor
        final bool recorded = response.body.toLowerCase() == 'true';

        setState(() {
          isSaved = recorded;
        });
      }
    } catch (e) {
      print('Kaydetme durumu kontrol edilirken hata: $e');
    }
  }

  Future<bool> _toggleLike(PostDTO post) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';
    final postId = post.postId;

    // Değişiklik öncesi state'i hatırla
    final previousState = isLiked;

    // State'i hemen değiştir (optimistik UI güncellemesi)
    setState(() {
      isLiked = !isLiked;
    });

    try {
      http.Response response;

      if (previousState) {
        // Beğeniyi kaldır
        response = await http.delete(
          Uri.parse('http://192.168.89.61:8080/v1/api/likes/post/$postId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      } else {
        // Gönderiyi beğen
        response = await http.post(
          Uri.parse('http://192.168.89.61:8080/v1/api/likes/post/$postId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        // Beğeni başarılıysa animasyonu göster
        if (response.statusCode == 200 || response.statusCode == 201) {
          _likeAnimationController
              .forward()
              .then((_) => _likeAnimationController.reset());
          // Haptic feedback
          HapticFeedback.mediumImpact();
        }
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        // İşlem başarısız oldu, UI'ı eski haline getir
        setState(() {
          isLiked = previousState;
        });
        return false;
      }

      // İşlem başarılı
      return true;
    } catch (e) {
      // Hata durumunda UI'ı eski haline getir
      setState(() {
        isLiked = previousState;
        _errorMessage = 'Beğeni işlemi sırasında bir hata oluştu';
      });
      return false;
    }
  }

  // Gönderiyi paylaşma fonksiyonu - geliştirilmiş
  void _sharePost(BuildContext context, PostDTO post) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final cardColor =
        isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;
    final accentColor = isDarkMode ? AppColors.accent : AppColors.lightAccent;
    final textColor =
        isDarkMode ? AppColors.primaryText : AppColors.lightPrimaryText;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 25, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Gönderiyi Paylaş',
              style: GoogleFonts.poppins(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildShareOption(
                  icon: FontAwesomeIcons.solidComment,
                  label: 'Mesaj',
                  onTap: () {
                    Navigator.pop(context);
                    _showSuccessSnackbar(
                        context, 'Mesaj özelliği henüz aktif değil');
                  },
                  color: accentColor,
                ),
                _buildShareOption(
                  icon: FontAwesomeIcons.link,
                  label: 'Bağlantı',
                  onTap: () {
                    Navigator.pop(context);
                    _copyPostUrl(context, post);
                  },
                  color: Colors.blue,
                ),
                _buildShareOption(
                  icon: FontAwesomeIcons.instagram,
                  label: 'Story',
                  onTap: () {
                    Navigator.pop(context);
                    _showSuccessSnackbar(
                        context, 'Story özelliği henüz aktif değil');
                  },
                  color: Colors.pink,
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );

    // Hafif titreşim ekle
    HapticFeedback.selectionClick();
  }

  // Paylaşma seçeneği widgeti
  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Provider.of<ThemeProvider>(context).isDarkMode
                    ? AppColors.primaryText
                    : AppColors.lightPrimaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Geliştirilmiş kaydetme fonksiyonu
  Future<bool> _savePost(PostDTO post) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';
    final postId = post.postId;

    // Değişiklik öncesi state'i hatırla
    final previousState = isSaved;

    // State'i hemen değiştir (optimistik UI güncellemesi)
    setState(() {
      isSaved = !isSaved;
    });

    // Hafif titreşim ekle
    HapticFeedback.selectionClick();

    try {
      http.Response response;

      if (!previousState) {
        // POST isteği ile gönderiyi kaydet
        response = await http.post(
          Uri.parse('http://192.168.89.61:8080/v1/api/post/recorded/$postId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      } else {
        // DELETE isteği ile gönderi kaydını kaldır
        response = await http.delete(
          Uri.parse('http://192.168.89.61:8080/v1/api/post/recorded/$postId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      }

      if (response.statusCode == 200) {
        // Başarılı snackbar göster
        _showSuccessSnackbar(
          context,
          isSaved ? 'Gönderi kaydedildi' : 'Gönderi kaydedilenlerden çıkarıldı',
        );
        return true;
      } else {
        // API hatası, state'i eski haline getir
        setState(() {
          isSaved = previousState;
        });

        // Hata mesajını göster
        _showErrorSnackbar(
            context, 'İşlem başarısız oldu: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      // Hata durumunda UI'ı eski haline getir
      setState(() {
        isSaved = previousState;
      });

      // Hata mesajını göster
      _showErrorSnackbar(context, 'İşlem sırasında bir hata oluştu');
      return false;
    }
  }

  // Başarılı Snackbar
  void _showSuccessSnackbar(BuildContext context, String message) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final successColor =
        isDarkMode ? AppColors.success : AppColors.lightSuccess;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(10),
        elevation: 6,
      ),
    );
  }

  // Hata Snackbar
  void _showErrorSnackbar(BuildContext context, String message) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final errorColor = isDarkMode ? AppColors.error : AppColors.lightError;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(10),
        elevation: 6,
        action: SnackBarAction(
          label: 'TAMAM',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Kullanıcı profiline gitme fonksiyonu - Güncellendi
  void _navigateToProfile(BuildContext context, PostDTO post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          username: post.username,
          userId: post.userId,
        ),
      ),
    );

    // Hafif titreşim ekle
    HapticFeedback.selectionClick();
  }

  // URL kopyalama fonksiyonu
  void _copyPostUrl(BuildContext context, PostDTO post) {
    final String postUrl = 'app://campus/post/${post.postId}';
    Clipboard.setData(ClipboardData(text: postUrl));

    // Başarılı mesajı göster
    _showSuccessSnackbar(context, 'Gönderi linki panoya kopyalandı');

    // Titreşim ekle
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Tema bazlı renkler
    final backgroundColor =
        isDarkMode ? AppColors.background : AppColors.lightBackground;
    final cardColor =
        isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;
    final surfaceColor =
        isDarkMode ? AppColors.surfaceColor : AppColors.lightSurfaceColor;
    final textColor =
        isDarkMode ? AppColors.primaryText : AppColors.lightPrimaryText;
    final secondaryTextColor =
        isDarkMode ? AppColors.secondaryText : AppColors.lightSecondaryText;
    final accentColor = isDarkMode ? AppColors.accent : AppColors.lightAccent;
    final errorColor = isDarkMode ? AppColors.error : AppColors.lightError;
    final successColor =
        isDarkMode ? AppColors.success : AppColors.lightSuccess;

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            margin: EdgeInsets.only(left: 16, top: 8),
            decoration: BoxDecoration(
              color: _isScrolling
                  ? Colors.black.withOpacity(0.7)
                  : Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .shimmer(delay: 4000.ms, duration: 1800.ms),
        actions: [
          GestureDetector(
            onTap: () => _showPostOptionsBottomSheet(context),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              margin: EdgeInsets.only(right: 16, top: 8),
              decoration: BoxDecoration(
                color: _isScrolling
                    ? Colors.black.withOpacity(0.7)
                    : Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(10),
              child: Icon(
                Icons.more_horiz,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: backgroundColor,
          systemNavigationBarIconBrightness:
              isDarkMode ? Brightness.light : Brightness.dark,
        ),
      ),
      body: FutureBuilder<DataResponseMessage<PostDTO>>(
        future: _postDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(cardColor, surfaceColor);
          } else if (snapshot.hasError) {
            return _buildErrorState(
                'Gönderi yüklenirken bir hata oluştu: ${snapshot.error}',
                backgroundColor,
                errorColor,
                accentColor,
                textColor);
          } else if (!snapshot.hasData || snapshot.data?.data == null) {
            return _buildErrorState('Gönderi bulunamadı', backgroundColor,
                errorColor, accentColor, textColor);
          } else {
            final post = snapshot.data!.data!;
            return _buildPostDetails(
                context,
                post,
                backgroundColor,
                cardColor,
                surfaceColor,
                accentColor,
                textColor,
                secondaryTextColor,
                successColor);
          }
        },
      ),
    );
  }

  Widget _buildLoadingState(Color cardColor, Color surfaceColor) {
    return Shimmer.fromColors(
      baseColor: cardColor,
      highlightColor: surfaceColor,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gönderi medyası için iskelet
            Container(
              height: MediaQuery.of(context).size.height * 0.7,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
            ),

            // Ana içerik konteyneri
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              margin: EdgeInsets.zero,
              transform: Matrix4.translationValues(0.0, -30.0, 0.0),
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kullanıcı bilgisi için iskelet
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 16,
                              width: 140,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              height: 12,
                              width: 90,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),

                  // Etkileşim butonları için iskelet
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      4,
                      (index) => Container(
                        width: index == 2 ? 80 : 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),

                  // İstatistikler için iskelet
                  SizedBox(height: 20),
                  Container(
                    height: 16,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),

                  // Açıklama için iskelet
                  SizedBox(height: 20),
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    height: 16,
                    width: MediaQuery.of(context).size.width * 0.7,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),

                  // Konum ve etiketler için iskelet
                  SizedBox(height: 20),
                  Row(
                    children: List.generate(
                      3,
                      (index) => Container(
                        margin: EdgeInsets.only(right: 10),
                        width: 80,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  // Yorumlar için iskelet
                  SizedBox(height: 30),
                  Container(
                    height: 24,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, curve: Curves.easeOut);
  }

  Widget _buildErrorState(String message, Color backgroundColor,
      Color errorColor, Color accentColor, Color textColor) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            backgroundColor.withOpacity(0.8),
            backgroundColor,
          ],
          stops: [0.0, 0.6],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: backgroundColor.withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: errorColor.withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: errorColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  message.contains('bulunamadı')
                      ? Icons.search_off_rounded
                      : Icons.error_outline_rounded,
                  color: errorColor,
                  size: 56,
                ),
              ).animate().scale(
                  duration: 800.ms, curve: Curves.elasticOut, delay: 300.ms),
              SizedBox(height: 24),
              Text(
                message,
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: accentColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 4,
                  shadowColor: accentColor.withOpacity(0.4),
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _loadPostDetails();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Yeniden Dene',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Geri Dön',
                  style: GoogleFonts.poppins(
                    color: accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostDetails(
      BuildContext context,
      PostDTO post,
      Color backgroundColor,
      Color cardColor,
      Color surfaceColor,
      Color accentColor,
      Color textColor,
      Color secondaryTextColor,
      Color successColor) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Gönderi medyası
        SliverToBoxAdapter(
          child: _buildMediaCarousel(post),
        ),

        // Gönderi içeriği
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            margin: EdgeInsets.zero,
            transform: Matrix4.translationValues(0.0, -30.0, 0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kullanıcı bilgileri
                _buildPostHeader(context, post, textColor, secondaryTextColor,
                    backgroundColor),

                // Etkileşim butonları
                _buildPostActions(context, post, textColor, accentColor,
                    backgroundColor, surfaceColor),

                // Gönderi istatistikleri
                _buildPostStats(
                    post, textColor, secondaryTextColor, backgroundColor),

                // Gönderi açıklaması
                _buildPostDescription(
                    post, textColor, secondaryTextColor, backgroundColor),

                // Konum ve etiketler
                _buildLocationAndTags(
                    post, cardColor, accentColor, textColor, backgroundColor),

                // Gönderi zamanı
                _buildPostTime(post, secondaryTextColor, backgroundColor),

                // Yorumlar bölümü
                _buildCommentsSection(context, post, cardColor, surfaceColor,
                    accentColor, textColor, secondaryTextColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostHeader(BuildContext context, PostDTO post, Color textColor,
      Color secondaryTextColor, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateToProfile(context, post),
            child: Hero(
              tag: 'profile_${post.username}',
              child: ProfileAvatarWidget(
                profilePhotoUrl: post.profilePhoto,
                username: post.username,
                size: 50,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _navigateToProfile(context, post),
                  child: Text(
                    post.username,
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (post.location.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: Colors.blueAccent,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            post.location,
                            style: GoogleFonts.poppins(
                              color: secondaryTextColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_horiz, color: textColor),
            onPressed: () {
              _showPostOptionsBottomSheet(context);
            },
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            splashRadius: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaCarousel(PostDTO post) {
    if (post.content.isEmpty) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.6,
        color: Colors.black,
        child: Center(
          child: Icon(
            Icons.hide_image_rounded,
            color: Colors.white.withOpacity(0.7),
            size: 80,
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Ana karüsel
        CarouselSlider(
          options: CarouselOptions(
            height: MediaQuery.of(context).size.height * 0.65,
            viewportFraction: 1.0,
            enableInfiniteScroll: post.content.length > 1,
            autoPlay: false,
            enlargeCenterPage: false,
            onPageChanged: (index, reason) {
              setState(() {
                _currentImageIndex = index;
              });
            },
          ),
          items: post.content.map((mediaUrl) {
            return Builder(
              builder: (BuildContext context) {
                final bool isVideo = mediaUrl.toLowerCase().endsWith('.mp4') ||
                    mediaUrl.toLowerCase().contains('video');

                return GestureDetector(
                  onDoubleTap: () {
                    if (!isLiked) {
                      _toggleLike(post);

                      // Show heart animation
                      _likeAnimationController.forward().then((_) {
                        _likeAnimationController.reset();
                      });
                    }
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                    ),
                    child: isVideo
                        ? VideoPlayerWidget(
                            videoUrl: mediaUrl,
                            autoPlay: _isVideoPlaying,
                            looping: true,
                            showControls: true,
                            isInFeed: false,
                          )
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: mediaUrl,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white70,
                                    strokeWidth: 2,
                                  ),
                                ),
                                errorWidget: (context, url, error) => Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image_rounded,
                                      color: Colors.white.withOpacity(0.7),
                                      size: 60,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Görüntü yüklenemedi',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                );
              },
            );
          }).toList(),
        ),

        // Çift tıklama beğeni animasyonu
        Positioned.fill(
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: _likeAnimationController,
              curve: Curves.elasticOut,
            ),
            child: AnimatedOpacity(
              opacity: _likeAnimationController.value,
              duration: const Duration(milliseconds: 200),
              child: Center(
                child: Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 120,
                ),
              ),
            ),
          ),
        ),

        // Sayfa göstergeleri (birden fazla medya varsa)
        if (post.content.length > 1)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: post.content.asMap().entries.map((entry) {
                final index = entry.key;
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  width: _currentImageIndex == index ? 12 : 8,
                  height: _currentImageIndex == index ? 12 : 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    boxShadow: _currentImageIndex == index
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              spreadRadius: 1,
                            )
                          ]
                        : [],
                  ),
                );
              }).toList(),
            ),
          ),

        // Durum çubuğu arka planı
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 100,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
                stops: [0.0, 0.8],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostActions(BuildContext context, PostDTO post, Color textColor,
      Color accentColor, Color backgroundColor, Color surfaceColor) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Beğen butonu
          Container(
            decoration: BoxDecoration(
              color: isLiked
                  ? accentColor.withOpacity(0.1)
                  : surfaceColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: LikeButton(
              size: 30,
              isLiked: isLiked,
              circleColor: const CircleColor(
                start: Colors.redAccent,
                end: Colors.red,
              ),
              bubblesColor: const BubblesColor(
                dotPrimaryColor: Colors.redAccent,
                dotSecondaryColor: Colors.red,
              ),
              likeBuilder: (bool isLiked) {
                return Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border_rounded,
                  color: isLiked ? Colors.redAccent : textColor,
                  size: 24,
                );
              },
              onTap: (isLiked) async {
                return await _toggleLike(post);
              },
            ),
          ),

          const SizedBox(width: 12),

          // Yorum butonu
          Container(
            decoration: BoxDecoration(
              color: surfaceColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: IconButton(
              icon: Icon(Icons.chat_bubble_outline_rounded,
                  color: textColor, size: 22),
              onPressed: () {
                // Yorumlara otomatik kaydır
                if (_scrollController.hasClients) {
                  final commentsPosition =
                      MediaQuery.of(context).size.height * 1.3;
                  _scrollController.animateTo(
                    commentsPosition,
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeOutQuint,
                  );
                }
              },
              constraints: BoxConstraints(),
              padding: EdgeInsets.all(8),
              splashRadius: 24,
            ),
          ),

          const SizedBox(width: 12),

          // Paylaş butonu
          Container(
            decoration: BoxDecoration(
              color: surfaceColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: IconButton(
              icon: Icon(Icons.send_outlined, color: textColor, size: 22),
              onPressed: () => _sharePost(context, post),
              constraints: BoxConstraints(),
              padding: EdgeInsets.all(8),
              splashRadius: 24,
            ),
          ),

          const Spacer(),

          // Kaydet butonu
          Container(
            decoration: BoxDecoration(
              color: isSaved
                  ? accentColor.withOpacity(0.1)
                  : surfaceColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border_rounded,
                  key: ValueKey<bool>(isSaved),
                  color: isSaved ? accentColor : textColor,
                  size: 24,
                ),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
              ),
              onPressed: () => _savePost(post),
              constraints: BoxConstraints(),
              padding: EdgeInsets.all(8),
              splashRadius: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostStats(PostDTO post, Color textColor,
      Color secondaryTextColor, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${isLiked ? post.like + 1 : post.like} beğenme',
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              SizedBox(width: 16),
              Text(
                '${post.comment} yorum',
                style: GoogleFonts.poppins(
                  color: secondaryTextColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostDescription(PostDTO post, Color textColor,
      Color secondaryTextColor, Color backgroundColor) {
    // Uzun açıklamalar için gösterme ve gizleme kontrolü
    final bool hasDescription = post.description.trim().isNotEmpty;
    final bool isLongDescription = post.description.length > 150;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasDescription)
            GestureDetector(
              onTap: () {
                if (isLongDescription) {
                  setState(() {
                    _isDescriptionExpanded = !_isDescriptionExpanded;
                  });
                }
              },
              child: RichText(
                maxLines: _isDescriptionExpanded ? null : 4,
                overflow: _isDescriptionExpanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${post.username} ',
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    TextSpan(
                      text: post.description.trim(),
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 14.5,
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (isLongDescription && hasDescription)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isDescriptionExpanded = !_isDescriptionExpanded;
                  });
                },
                child: Text(
                  _isDescriptionExpanded ? 'Daha az göster' : 'Devamını göster',
                  style: GoogleFonts.poppins(
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationAndTags(PostDTO post, Color cardColor, Color accentColor,
      Color textColor, Color backgroundColor) {
    final bool hasTags = post.tagAPerson.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasTags) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Etiketlenenler',
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children: post.tagAPerson.map((tag) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accentColor.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          color: accentColor,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tag,
                        style: GoogleFonts.poppins(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPostTime(
      PostDTO post, Color secondaryTextColor, Color backgroundColor) {
    String timeAgo = post.howMoneyMinutesAgo;
    if (timeAgo.isEmpty) {
      try {
        timeAgo = timeago.format(post.createdAt, locale: 'tr');
      } catch (e) {
        timeAgo = '';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.access_time_rounded,
            color: secondaryTextColor.withOpacity(0.7),
            size: 14,
          ),
          SizedBox(width: 6),
          Text(
            timeAgo,
            style: GoogleFonts.poppins(
              color: secondaryTextColor.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(
      BuildContext context,
      PostDTO post,
      Color cardColor,
      Color surfaceColor,
      Color accentColor,
      Color textColor,
      Color secondaryTextColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: secondaryTextColor.withOpacity(0.1)),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Yorumlar (${post.comment})',
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Comment input field
          Container(
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: secondaryTextColor.withOpacity(0.1)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ProfileAvatarWidget(
                  profilePhotoUrl:
                      'https://example.com/placeholder.jpg', // Replace with user's profile photo
                  username: 'user',
                  size: 32,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    style: GoogleFonts.poppins(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Yorum yaz...',
                      hintStyle: GoogleFonts.poppins(color: secondaryTextColor),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: accentColor),
                  onPressed: () {
                    // Send comment
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Comments list
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.chat_bubble_outline, color: accentColor, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    'Yorumlar yükleniyor...',
                    style: GoogleFonts.poppins(
                      color: secondaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showPostOptionsBottomSheet(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final backgroundColor =
        isDarkMode ? AppColors.background : AppColors.lightBackground;
    final cardColor =
        isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;
    final textColor =
        isDarkMode ? AppColors.primaryText : AppColors.lightPrimaryText;
    final accentColor = isDarkMode ? AppColors.accent : AppColors.lightAccent;
    final errorColor = isDarkMode ? AppColors.error : AppColors.lightError;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 50,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildOptionItem(
                  icon: Icons.link,
                  text: 'Gönderi bağlantısını kopyala',
                  onTap: () {
                    Navigator.pop(context);
                    // Implementation
                  },
                  textColor: textColor,
                  iconColor: accentColor),
              _buildOptionItem(
                  icon: Icons.share,
                  text: 'Gönderiyi paylaş',
                  onTap: () {
                    Navigator.pop(context);
                    // Implementation
                  },
                  textColor: textColor,
                  iconColor: accentColor),
              _buildOptionItem(
                  icon: Icons.bookmark_border,
                  text: 'Gönderiyi kaydet',
                  onTap: () {
                    Navigator.pop(context);
                    // Implementation
                  },
                  textColor: textColor,
                  iconColor: accentColor),
              _buildOptionItem(
                  icon: Icons.report_problem_outlined,
                  text: 'Şikayet et',
                  onTap: () {
                    Navigator.pop(context);
                    // Implementation
                  },
                  isDestructive: true,
                  textColor: textColor,
                  iconColor: errorColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    required Color textColor,
    required Color iconColor,
    bool isDestructive = false,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final cardColor =
        isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;
    final errorColor = isDarkMode ? AppColors.error : AppColors.lightError;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDestructive
            ? errorColor.withOpacity(0.1)
            : cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? errorColor : iconColor,
        ),
        title: Text(
          text,
          style: GoogleFonts.poppins(
            color: isDestructive ? errorColor : textColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
