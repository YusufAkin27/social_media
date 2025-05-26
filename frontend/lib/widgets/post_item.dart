import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async'; // Timeout işlemleri için gerekli
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Import dart:convert for json decoding
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:social_media/screens/profile_screen.dart';
import 'package:social_media/screens/user_profile_screen.dart';
import 'package:like_button/like_button.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart'; // Import Dio
import 'package:social_media/services/commentService.dart'; // Import the CommentService
import 'package:visibility_detector/visibility_detector.dart'; // Görünürlük kontrolü için
import 'package:social_media/models/response_message.dart'; // ResponseMessage için
import 'package:flutter/cupertino.dart'; // Import for Cupertino icons
import 'package:social_media/widgets/video_player_widget.dart';
import 'package:social_media/theme/app_theme.dart'; // Import app theme
import 'package:social_media/utils/video_helper.dart'; // Import VideoHelper

class PostItem extends StatefulWidget {
  final Map<String, dynamic> post;
  final bool skipInvalidContent;
  final VoidCallback? onLikeToggle;

  const PostItem({
    Key? key,
    required this.post,
    this.skipInvalidContent = false,
    this.onLikeToggle,
  }) : super(key: key);

  @override
  _PostItemState createState() => _PostItemState();
}

class _PostItemState extends State<PostItem>
    with SingleTickerProviderStateMixin {
  final _commentController = TextEditingController();
  bool isLiked = false;
  bool isSaved = false;
  bool isRecorded = false;
  List<CommentDTO> comments = [];
  int currentPage = 0;
  bool isLoadingComments = false;
  ScrollController _scrollController = ScrollController();
  int _currentMediaIndex = 0;
  final PageController _mediaController = PageController();
  late PostDTO postData;
  bool hasValidContent = false;
  late PageController _pageController;
  int likeCount = 0;
  final Dio dioInstance = Dio(); // Create a Dio instance
  final CommentService _commentService =
      CommentService(Dio()); // Create an instance of CommentService
  bool _showLikeAnimation = false;
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;

  // Fotoğraf geçiş animasyonu kontrolcüsü
  final PageController _mediaPageController = PageController();
  double _currentPageValue = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
        initialPage: 0,
        viewportFraction: 0.999); // Hafif bir örtüşme efekti için
    _parsePostData();
    _checkIfLiked();
    _checkIfRecorded();
    _fetchComments();
    _scrollController.addListener(_onScroll);

    // Beğeni animasyonu için controller oluşturma
    _likeAnimationController = AnimationController(
      duration: Duration(milliseconds: 700),
      vsync: this,
    );

    _likeAnimation = CurvedAnimation(
      parent: _likeAnimationController,
      curve: Curves.elasticOut,
    );

    // Sayfa değişimini dinle
    _pageController.addListener(() {
      if (!_pageController.hasClients) return;

      setState(() {
        _currentPageValue = _pageController.page ?? 0;
        final page = _pageController.page?.round() ?? 0;
        if (currentPage != page) {
          currentPage = page;
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _mediaController.dispose();
    _pageController.dispose();
    _likeAnimationController.dispose();
    super.dispose();
  }

  void _parsePostData() {
    try {
      postData = PostDTO.fromJson(widget.post);
      hasValidContent = postData.hasValidContent();
      if (hasValidContent) {
        print('Post içeriği geçerli: ${postData.content.length} medya öğesi');
      } else {
        print('Post içeriği geçersiz veya boş');
      }
      likeCount = postData.like;
    } catch (e) {
      print('Post verisi ayrıştırılırken hata: $e');
      hasValidContent = false;
      postData = PostDTO(
        postId: '',
        userId: 0,
        username: 'Bilinmeyen',
        content: [],
        profilePhoto: '',
        description: 'İçerik yüklenirken hata oluştu',
        tagAPerson: [],
        location: '',
        createdAt: DateTime.now(),
        howMoneyMinutesAgo: '',
        like: 0,
        comment: 0,
        popularityScore: 0,
        isLiked: false,
      );
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // We're not implementing pagination for now
      // _loadMoreComments();
    }
  }

  void _checkIfLiked() async {
    // Backend'den beğeni durumu kontrol edilecek
    final postId = postData.postId;
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';

    try {
      print('Beğeni durumu kontrol ediliyor: $postId');
      // Doğrudan API adresini kullanarak beğeni durumunu kontrol et
      final response = await http.get(
        Uri.parse('http://192.168.89.61:8080/v1/api/likes/posts/$postId/check'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      print('Beğeni durumu yanıtı: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final bool liked = responseData['liked'] ?? false;
        print(
            'Gönderi $postId beğeni durumu: ${liked ? "Beğenilmiş" : "Beğenilmemiş"}');
        setState(() {
          isLiked = liked;
        });
      } else {
        print('Beğeni durumu kontrol hatası: ${response.statusCode}');
        setState(() {
          isLiked = false; // Default to false on error
        });
      }
    } catch (e) {
      print('Beğeni durumu kontrol edilirken hata: $e');
      setState(() {
        isLiked = false; // Default to false on error
      });
    }
  }

  void _checkIfRecorded() async {
    // Backend'den kaydetme durumu kontrol edilecek
    final postId = postData.postId;
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';

    try {
      print('Kaydetme durumu kontrol ediliyor: $postId');
      // Doğrudan API adresini kullanarak kaydetme durumunu kontrol et
      final response = await http.get(
        Uri.parse(
            'http://192.168.89.61:8080/v1/api/post/recorded/$postId/check'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      print(
          'Kaydetme durumu yanıtı: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        // Spring Boot API doğrudan boolean değer döndürüyor
        final bool recorded = response.body.toLowerCase() == 'true';
        print(
            'Gönderi $postId kaydetme durumu: ${recorded ? "Kaydedilmiş" : "Kaydedilmemiş"}');
        setState(() {
          isRecorded = recorded;
        });
      } else {
        print('Kaydetme durumu kontrol hatası: ${response.statusCode}');
        setState(() {
          isRecorded = false; // Default to false on error
        });
      }
    } catch (e) {
      print('Kaydetme durumu kontrol edilirken hata: $e');
      setState(() {
        isRecorded = false; // Default to false on error
      });
    }
  }

  Future<void> _fetchComments() async {
    if (isLoadingComments) return;

    setState(() {
      isLoadingComments = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';
    final postId = postData.postId;

    try {
      // Directly use http to get comments
      final response = await http.get(
        Uri.parse('http://192.168.89.61:8080/v1/api/comments/post/$postId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      print('Yorum getirme yanıtı: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> commentsData = responseData['data'];

          setState(() {
            comments = commentsData
                .map((commentData) => CommentDTO.fromJson(commentData))
                .toList();
          });
        }
      } else {
        print('Yorumlar yüklenirken hata: ${response.statusCode}');
      }
    } catch (e) {
      print('Yorumlar yüklenirken hata: $e');
    } finally {
      setState(() {
        isLoadingComments = false;
      });
    }
  }

  Future<void> _loadMoreComments() async {
    // For now, we're not implementing pagination as the API doesn't support it
    // Just refresh the comments
    return _fetchComments();
  }

  Future<void> _toggleLike() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';
    final postId = postData.postId;

    try {
      http.Response response;

      if (!isLiked) {
        // POST isteği ile gönderiyi beğen
        print('Gönderi beğeniliyor: $postId');
        response = await http.post(
          Uri.parse('http://192.168.89.61:8080/v1/api/likes/post/$postId'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        );
        print('Beğeni yanıtı: ${response.statusCode} - ${response.body}');
      } else {
        // DELETE isteği ile gönderi beğenisini kaldır
        print('Gönderi beğenisi kaldırılıyor: $postId');
        response = await http.delete(
          Uri.parse('http://192.168.89.61:8080/v1/api/likes/post/$postId'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        );
        print(
            'Beğeni kaldırma yanıtı: ${response.statusCode} - ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // API yanıtını işle
        final responseData = json.decode(response.body);
        final bool success = responseData['success'] ?? false;

        if (success) {
          setState(() {
            isLiked = !isLiked;
            likeCount = isLiked ? likeCount + 1 : likeCount - 1;
            if (likeCount < 0) likeCount = 0;
          });

          // Callback'i çağır
          widget.onLikeToggle?.call();

          // Haptic feedback ekleyelim
          HapticFeedback.mediumImpact();

          // Başarı mesajı
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isLiked ? 'Gönderi beğenildi' : 'Gönderi beğenisi kaldırıldı',
                style: TextStyle(color: AppColors.primaryText),
              ),
              backgroundColor: AppColors.cardBackground,
              duration: Duration(milliseconds: 800),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          print('Beğeni işlemi başarısız: ${responseData['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Beğeni işlemi başarısız oldu'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        print('Beğeni işlemi başarısız: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Beğeni işlemi başarısız oldu'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Beğeni durumu değiştirilirken hata: $e');
      // Hata mesajı
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Beğeni işlemi sırasında bir hata oluştu'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleDoubleTap() {
    // Beğeni durumunu API üzerinden güncelle
    _toggleLike();

    // Beğeni animasyonu göster
    setState(() {
      _showLikeAnimation = true;
    });

    // Animasyonu başlat
    _likeAnimationController.reset();
    _likeAnimationController.forward();

    // Haptic feedback ekle
    HapticFeedback.mediumImpact();

    // 1 saniye sonra animasyonu kapat
    Future.delayed(Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _showLikeAnimation = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Widget'ı oluşturmadan önce içeriği kontrol edelim
    if (widget.skipInvalidContent && !hasValidContent) {
      return SizedBox.shrink(); // Geçersiz içerikli postları gösterme
    }

    // Güvenli bir şekilde post verilerini kullanalım
    final String username = postData.username;
    final String profilePhoto = postData.profilePhoto;
    final String description = postData.description;
    final String location = postData.location;
    final List<String> taggedPeople = postData.tagAPerson;
    final int commentCount = postData.comment;
    final int popularityScore = postData.popularityScore;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side:
            BorderSide(color: AppColors.primaryText.withOpacity(0.1), width: 1),
      ),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kullanıcı bilgileri daha modern bir görünüm
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfileScreen(
                          username: username,
                          userId: postData.userId,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accent.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundImage: profilePhoto.isNotEmpty
                          ? NetworkImage(profilePhoto)
                          : null,
                      backgroundColor: AppColors.cardBackground,
                      child: profilePhoto.isEmpty
                          ? Icon(CupertinoIcons.person_fill,
                              color: AppColors.primaryText)
                          : null,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserProfileScreen(
                                    username: username,
                                    userId: postData.userId,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              username,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryText,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (location.isNotEmpty) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.background.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.location_solid,
                                    color: AppColors.accent,
                                    size: 12,
                                  ),
                                  SizedBox(width: 2),
                                  Flexible(
                                    child: Text(
                                      location,
                                      style: TextStyle(
                                        color: AppColors.secondaryText,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 4),
                      _buildPopularityScore(),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(CupertinoIcons.ellipsis_vertical,
                      color: AppColors.primaryText),
                  onPressed: () {
                    _showPostOptionsMenu(context);
                  },
                ),
              ],
            ),
          ),
          // Medya içeriği
          _buildMediaContent(),
          // Etkileşim butonları - daha modern görünüm
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    LikeButton(
                      size: 26,
                      isLiked: isLiked,
                      likeCount: likeCount,
                      countBuilder: (count, isLiked, text) {
                        return Text(
                          count != null && count > 0 ? text : '',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                      likeBuilder: (isLiked) {
                        return Icon(
                          isLiked
                              ? CupertinoIcons.heart_fill
                              : CupertinoIcons.heart,
                          color:
                              isLiked ? AppColors.error : AppColors.primaryText,
                          size: 26,
                        );
                      },
                      onTap: (isLiked) async {
                        HapticFeedback.lightImpact();
                        _toggleLike(); // Call the toggleLike method
                        return !isLiked;
                      },
                    ),
                    SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _showCommentsModal(context),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.chat_bubble,
                            color: AppColors.primaryText,
                            size: 22,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '$commentCount',
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(
                      CupertinoIcons.share,
                      color: AppColors.primaryText,
                      size: 22,
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _toggleSave,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isRecorded
                          ? AppColors.accent.withOpacity(0.1)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isRecorded
                          ? CupertinoIcons.bookmark_fill
                          : CupertinoIcons.bookmark,
                      color:
                          isRecorded ? AppColors.accent : AppColors.primaryText,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Gönderi açıklaması
          if (postData.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
              child: GestureDetector(
                onTap: () {
                  // Post detay sayfasına yönlendirme kaldırıldı
                },
                child: RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${postData.username} ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                          fontSize: 15,
                        ),
                      ),
                      TextSpan(
                        text: postData.description,
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Etiketler
          if (taggedPeople.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: taggedPeople
                    .map<Widget>((username) => GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserProfileScreen(
                                  username: username,
                                  userId: postData.userId,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.accent.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              '@$username',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildMediaContent() {
    if (!hasValidContent) {
      return Container(
        height: 200,
        color: AppColors.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.photo_fill_on_rectangle_fill,
                  color: AppColors.primaryText, size: 48),
              SizedBox(height: 16),
              Text(
                'Geçerli medya içeriği bulunamadı',
                style: TextStyle(color: AppColors.primaryText, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Bu gönderi görüntülenemiyor',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Tüm medya URL'lerini al, boş veya null olanları filtreleyerek temizle
    List<String> allMediaUrls = [];

    for (var url in postData.content) {
      if (url != null && url.isNotEmpty) {
        print('İşlenen URL: $url');
        allMediaUrls.add(url);
      }
    }

    print('Toplam URL sayısı: ${allMediaUrls.length}');

    if (allMediaUrls.isEmpty) {
      print('İçerik listesi boş, gönderi gösterilemiyor');
      return SizedBox.shrink();
    }

    return Stack(
      children: [
        // Ana PageView Container - Fotoğraflar
        Container(
          height: 400,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                currentPage = index;
                print('Sayfa değişti: $index (URL: ${allMediaUrls[index]})');
              });
            },
            physics:
                const BouncingScrollPhysics(), // İOS tarzı elastik kaydırma
            itemCount: allMediaUrls.length,
            itemBuilder: (context, index) {
              final String url = allMediaUrls[index];
              print(
                  'Medya oluşturuluyor: $url (${index + 1}/${allMediaUrls.length})');

              // Geçiş animasyonu için değerler hesapla
              double value = 0.0;
              if (_pageController.position.haveDimensions) {
                value = index.toDouble() - (_currentPageValue);
                // Scale değerini hesapla (0.85 to 1.0)
                value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
              }

              return Transform.scale(
                scale: value,
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: 350),
                  opacity: currentPage == index ? 1.0 : 0.8,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 2), // Hafif aralık
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.background.withOpacity(0.2),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GestureDetector(
                        onDoubleTap: _handleDoubleTap,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Video veya resim içeriği
                            if (_isVideoUrl(url))
                              VisibilityDetector(
                                key: Key('video-${url.hashCode}'),
                                onVisibilityChanged: (info) {
                                  if (info.visibleFraction > 0.6) {
                                    // Video görünür durumda
                                    print('Video görünür: $url');
                                  }
                                },
                                child: VideoPlayerWidget(
                                  videoUrl: url,
                                  isInFeed: true,
                                  autoPlay: true,
                                  looping: true,
                                  muted: true,
                                  showControls: false,
                                ),
                              )
                            else
                              GestureDetector(
                                onTap: () {
                                  // Post detaylarına yönlendirme kaldırıldı
                                },
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                        color: AppColors.primaryText,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Resim yükleme hatası: $error');
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                              CupertinoIcons
                                                  .exclamationmark_circle,
                                              color: AppColors.primaryText,
                                              size: 40),
                                          SizedBox(height: 10),
                                          Text(
                                            'Resim yüklenemedi',
                                            style: TextStyle(
                                                color: AppColors.primaryText),
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),

                            // Video etiketini göster
                            if (_isVideoUrl(url))
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.background.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(CupertinoIcons.videocam_fill,
                                          color: AppColors.primaryText,
                                          size: 18),
                                      SizedBox(width: 4),
                                      Text('Video',
                                          style: TextStyle(
                                              color: AppColors.primaryText,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),

                            // Beğeni animasyonu
                            if (_showLikeAnimation && currentPage == index)
                              Center(
                                child: AnimatedOpacity(
                                  opacity: _showLikeAnimation ? 1.0 : 0.0,
                                  duration: Duration(milliseconds: 200),
                                  child: ScaleTransition(
                                    scale: _likeAnimation,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Arka parlama efekti
                                        Icon(
                                          CupertinoIcons.heart_fill,
                                          color: AppColors.primaryText
                                              .withOpacity(0.8),
                                          size: 110,
                                        ),
                                        // Ana kalp
                                        Icon(
                                          CupertinoIcons.heart_fill,
                                          color: AppColors.error,
                                          size: 100,
                                        ),
                                        // Parıltı efekti
                                        Icon(
                                          CupertinoIcons.heart_fill,
                                          color: AppColors.primaryText
                                              .withOpacity(0.5),
                                          size: 120,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Sayfa indikatörleri (noktalar) - en altta
        if (allMediaUrls.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  allMediaUrls.length,
                  (index) => AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    width: currentPage == index ? 12 : 8,
                    height: 6,
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: currentPage == index
                          ? AppColors.primaryText
                          : AppColors.primaryText.withOpacity(0.5),
                      boxShadow: currentPage == index
                          ? [
                              BoxShadow(
                                color: AppColors.background.withOpacity(0.3),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              )
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Sayfa sayacı - sağ üst köşe
        if (allMediaUrls.length > 1)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: AppColors.primaryText.withOpacity(0.2)),
              ),
              child: Text(
                '${currentPage + 1}/${allMediaUrls.length}',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),

        // Dokunma alanları (öncelikli, fotoğraf geçişi için)
        if (allMediaUrls.length > 1)
          Positioned.fill(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                // Sağa veya sola kaydırma hızına göre geçiş yapma
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! < 0) {
                    // Sola kaydırma (sonraki)
                    if (currentPage < allMediaUrls.length - 1) {
                      _pageController.animateToPage(
                        currentPage + 1,
                        duration: Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  } else if (details.primaryVelocity! > 0) {
                    // Sağa kaydırma (önceki)
                    if (currentPage > 0) {
                      _pageController.animateToPage(
                        currentPage - 1,
                        duration: Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  }
                }
              },
              child: Row(
                children: [
                  // Sol alan - önceki
                  if (currentPage > 0)
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            currentPage - 1,
                            duration: Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                          );
                          HapticFeedback.lightImpact();
                        },
                        behavior: HitTestBehavior.translucent,
                        child: Container(),
                      ),
                    ),

                  // Orta alan - çift tıklama için
                  Expanded(
                    flex: 14,
                    child: Container(),
                  ),

                  // Sağ alan - sonraki
                  if (currentPage < allMediaUrls.length - 1)
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            currentPage + 1,
                            duration: Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                          );
                          HapticFeedback.lightImpact();
                        },
                        behavior: HitTestBehavior.translucent,
                        child: Container(),
                      ),
                    ),
                ],
              ),
            ),
          ),

        // Geçiş butonları (daha küçük ve zarif)
        if (allMediaUrls.length > 1)
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Önceki düğmesi
                if (currentPage > 0)
                  Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          currentPage - 1,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.background.withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryText.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          CupertinoIcons.chevron_back,
                          color: AppColors.primaryText,
                          size: 18,
                        ),
                      ),
                    ),
                  ),

                // Sonraki düğmesi
                if (currentPage < allMediaUrls.length - 1)
                  Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          currentPage + 1,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.background.withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryText.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          CupertinoIcons.chevron_forward,
                          color: AppColors.primaryText,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPopularityScore() {
    // Popülerlik seviyesini görsel olarak belirt
    Color scoreColor;
    String scoreText;
    IconData scoreIcon;

    if (postData.popularityScore >= 90) {
      scoreColor = AppColors.link;
      scoreText = 'Trend';
      scoreIcon = CupertinoIcons.flame_fill;
    } else if (postData.popularityScore >= 70) {
      scoreColor = AppColors.error;
      scoreText = 'Popüler';
      scoreIcon = CupertinoIcons.chart_bar_fill;
    } else if (postData.popularityScore >= 50) {
      scoreColor = AppColors.warning;
      scoreText = 'Yükseliyor';
      scoreIcon = CupertinoIcons.arrow_up_right;
    } else {
      scoreColor = AppColors.accent;
      scoreText = 'Normal';
      scoreIcon = CupertinoIcons.graph_circle;
    }

    return Container(
      margin: EdgeInsets.only(top: 4),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scoreColor.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withOpacity(0.2),
            blurRadius: 4,
            spreadRadius: 1,
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            scoreIcon,
            color: scoreColor,
            size: 16,
          ),
          SizedBox(width: 4),
          Text(
            '$scoreText: ${postData.popularityScore}',
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentsModal(BuildContext context) {
    // Fetch latest comments before showing the modal
    _fetchComments();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    children: [
                      // Header with drag handle
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            // Drag handle
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.primaryText.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Yorumlar (${postData.comment})',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(color: AppColors.primaryText.withOpacity(0.1)),

                      // Comments list
                      Expanded(
                        child: comments.isEmpty && !isLoadingComments
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.chat_bubble_text,
                                      size: 50,
                                      color: AppColors.primaryText
                                          .withOpacity(0.5),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Henüz yorum yok',
                                      style: TextStyle(
                                        color: AppColors.primaryText,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'İlk yorumu sen yap!',
                                      style: TextStyle(
                                        color: AppColors.secondaryText,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: comments.length +
                                    (isLoadingComments ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == comments.length) {
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(
                                          color: AppColors.accent,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  }

                                  final comment = comments[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: comment
                                              .profilePhoto.isNotEmpty
                                          ? NetworkImage(comment.profilePhoto)
                                          : null,
                                      backgroundColor: AppColors.cardBackground,
                                      child: comment.profilePhoto.isEmpty
                                          ? Icon(CupertinoIcons.person_fill,
                                              color: AppColors.primaryText)
                                          : null,
                                    ),
                                    title: Row(
                                      children: [
                                        Text(
                                          comment.username,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryText,
                                            fontSize: 15,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          comment.howManyMinutesAgo,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        comment.content,
                                        style: TextStyle(
                                          color: AppColors.primaryText,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                  );
                                },
                              ),
                      ),

                      // Comment input field
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 3,
                              offset: Offset(0, -1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.cardBackground,
                              child: Icon(CupertinoIcons.person_fill,
                                  color: AppColors.primaryText),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                style: TextStyle(color: AppColors.primaryText),
                                decoration: InputDecoration(
                                  hintText: 'Yorum yaz...',
                                  hintStyle:
                                      TextStyle(color: AppColors.secondaryText),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.background,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                ),
                                textInputAction: TextInputAction.send,
                                onSubmitted: (value) {
                                  if (value.trim().isNotEmpty) {
                                    _addComment().then((_) {
                                      // Update the StatefulBuilder state to refresh the comments list
                                      setState(() {});
                                    });
                                  }
                                },
                              ),
                            ),
                            SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                if (_commentController.text.trim().isNotEmpty) {
                                  _addComment().then((_) {
                                    // Update the StatefulBuilder state to refresh the comments list
                                    setState(() {});
                                  });
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  CupertinoIcons.arrow_up,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      isLoadingComments = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';
    final postId = postData.postId;
    final commentContent = _commentController.text.trim();

    // Save the comment text before clearing the input field
    final String commentText = _commentController.text.trim();
    _commentController.clear();

    try {
      // Immediately add a temporary comment to the UI
      final tempComment = CommentDTO(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        username:
            'Siz', // This will be replaced with the actual username from API
        profilePhoto:
            '', // This will be replaced with the actual profile photo from API
        content: commentText,
        howManyMinutesAgo: 'Şimdi',
      );

      setState(() {
        // Add the temporary comment to the beginning of the list
        comments.insert(0, tempComment);
        // Update post comment count
        postData = PostDTO.fromJson({
          ...postData.toMap(),
          'comment': postData.comment + 1,
        });
      });

      // Directly use http to send the comment
      final response = await http.post(
        Uri.parse(
            'http://192.168.89.61:8080/v1/api/comments/post/$postId?content=$commentContent'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      print('Yorum gönderme yanıtı: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Haptic feedback ekleyelim
        HapticFeedback.mediumImpact();

        // Başarı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Yorum başarıyla eklendi',
              style: TextStyle(color: AppColors.primaryText),
            ),
            backgroundColor: AppColors.cardBackground,
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Refresh comments to get the actual comment data
        await _fetchComments();
      } else {
        // Remove the temporary comment if the request failed
        setState(() {
          comments.removeWhere((comment) => comment.id == tempComment.id);
          postData = PostDTO.fromJson({
            ...postData.toMap(),
            'comment': postData.comment - 1,
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yorum eklenirken bir hata oluştu'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Yorum eklenirken hata: $e');

      // Remove the temporary comment if an error occurred
      setState(() {
        comments.removeWhere((comment) => comment.id.startsWith('temp_'));
        postData = PostDTO.fromJson({
          ...postData.toMap(),
          'comment': postData.comment - 1,
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yorum eklenirken bir hata oluştu: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        isLoadingComments = false;
      });
    }
  }

  void _navigateToPostDetails(BuildContext context) {
    // Bu fonksiyon kaldırıldı - gönderi detay sayfası yönlendirmeleri için kullanılmayacak
  }

  Future<void> _toggleSave() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';
    final postId = postData.postId;

    try {
      http.Response response;

      if (!isRecorded) {
        // POST isteği ile gönderiyi kaydet
        print('Gönderi kaydediliyor: $postId');
        response = await http.post(
          Uri.parse('http://192.168.89.61:8080/v1/api/post/recorded/$postId'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        );
        print('Kaydetme yanıtı: ${response.statusCode} - ${response.body}');
      } else {
        // DELETE isteği ile gönderi kaydını kaldır
        print('Gönderi kaydı kaldırılıyor: $postId');
        response = await http.delete(
          Uri.parse('http://192.168.89.61:8080/v1/api/post/recorded/$postId'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        );
        print(
            'Kayıt kaldırma yanıtı: ${response.statusCode} - ${response.body}');
      }

      if (response.statusCode == 200) {
        // API yanıtını işle
        final responseData = json.decode(response.body);
        final bool success = responseData['success'] ?? false;

        if (success) {
          setState(() {
            isRecorded = !isRecorded;
          });

          // Haptic feedback ekleyelim
          HapticFeedback.mediumImpact();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isRecorded
                    ? 'Gönderi kaydedildi'
                    : 'Gönderi kaydedilenlerden çıkarıldı',
                style: TextStyle(color: AppColors.primaryText),
              ),
              backgroundColor: AppColors.cardBackground,
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          print('Kaydetme işlemi başarısız: ${responseData['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Kaydetme işlemi başarısız oldu: ${responseData['message'] ?? ''}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        print('Kaydetme işlemi başarısız: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Kaydetme işlemi başarısız oldu: Hata ${response.statusCode}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Kaydetme işlemi sırasında hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kaydetme işlemi sırasında bir hata oluştu'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  // URL'nin geçerli bir medya dosyası olup olmadığını kontrol eder
  bool _isValidMediaUrl(String url) {
    if (url == null || url.isEmpty) return false;

    // URL'yi küçük harflere çevir ve uzantıyı kontrol et
    String lowercaseUrl = url.toLowerCase();
    return _isImageUrl(lowercaseUrl) || _isVideoUrl(lowercaseUrl);
  }

  // URL'nin bir resim olup olmadığını kontrol eder
  bool _isImageUrl(String url) {
    List<String> imageExtensions = [
      '.jpg',
      '.jpeg',
      '.png',
      '.webp',
      '.gif',
      '.bmp'
    ];
    return imageExtensions.any((ext) => url.endsWith(ext));
  }

  // URL'nin bir video olup olmadığını kontrol eder
  bool _isVideoUrl(String url) {
    return VideoHelper.isVideoFile(url);
  }

  // Post seçenekleri menüsünü göster
  void _showPostOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Kaydırma çubuğu
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryText.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Seçenekler
            ListTile(
              leading: Icon(CupertinoIcons.flag, color: AppColors.primaryText),
              title: Text('Şikayet Et',
                  style: TextStyle(color: AppColors.primaryText)),
              onTap: () {
                Navigator.pop(context);
                // Şikayet işlemleri
              },
            ),
            ListTile(
              leading: Icon(CupertinoIcons.share, color: AppColors.primaryText),
              title: Text('Paylaş',
                  style: TextStyle(color: AppColors.primaryText)),
              onTap: () {
                Navigator.pop(context);
                // Paylaşma işlemleri
              },
            ),
            ListTile(
              leading: Icon(CupertinoIcons.link, color: AppColors.primaryText),
              title: Text('Bağlantıyı Kopyala',
                  style: TextStyle(color: AppColors.primaryText)),
              onTap: () {
                Navigator.pop(context);
                // Bağlantı kopyalama işlemleri
              },
            ),
            ListTile(
              leading: Icon(CupertinoIcons.info_circle,
                  color: AppColors.primaryText),
              title: Text('Gönderi Hakkında',
                  style: TextStyle(color: AppColors.primaryText)),
              onTap: () {
                Navigator.pop(context);
                // _navigateToPostDetails(context);
              },
            ),
            SizedBox(height: 10),
          ],
        );
      },
    );
  }
}

// Using the custom VideoPlayerWidget from widgets/video_player_widget.dart

class CommentDTO {
  final String id;
  final String username;
  final String profilePhoto;
  final String content;
  final String howManyMinutesAgo;

  CommentDTO({
    required this.id,
    required this.username,
    required this.profilePhoto,
    required this.content,
    required this.howManyMinutesAgo,
  });

  factory CommentDTO.fromJson(Map<String, dynamic> json) {
    return CommentDTO(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      profilePhoto: json['profilePhoto'] ?? '',
      content: json['content'] ?? '',
      howManyMinutesAgo: json['howManyMinutesAgo'] ?? '',
    );
  }
}

class PostDTO {
  final String postId;
  final int userId;
  final String username;
  final List<String> content;
  final String profilePhoto;
  final String description;
  final List<String> tagAPerson;
  final String location;
  final DateTime createdAt;
  final String howMoneyMinutesAgo;
  final int like;
  final int comment;
  final int popularityScore;
  bool isLiked;

  PostDTO({
    required this.postId,
    required this.userId,
    required this.username,
    required this.content,
    required this.profilePhoto,
    required this.description,
    required this.tagAPerson,
    required this.location,
    required this.createdAt,
    required this.howMoneyMinutesAgo,
    required this.like,
    required this.comment,
    required this.popularityScore,
    this.isLiked = false,
  });

  factory PostDTO.fromJson(Map<String, dynamic> json) {
    return PostDTO(
      postId: json['postId'] ?? '',
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      content: List<String>.from(json['content'] ?? [])
          .where((url) => url != null && url.isNotEmpty)
          .toList(),
      profilePhoto: json['profilePhoto'] ?? '',
      description: _safeDecodeUtf8(json['description'] ?? ''),
      tagAPerson: List<String>.from(json['tagAPerson'] ?? []),
      location: json['location'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      howMoneyMinutesAgo: json['howMoneyMinutesAgo'] ?? '',
      like: json['like'] ?? 0,
      comment: json['comment'] ?? 0,
      popularityScore: json['popularityScore'] ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
    );
  }

  static String _safeDecodeUtf8(String text) {
    try {
      return text;
    } catch (e) {
      return 'İçerik gösterilemiyor';
    }
  }

  // Gerekli bilgileri içeren işlevsel bir map
  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'username': username,
      'content': content,
      'profilePhoto': profilePhoto,
      'description': description,
      'tagAPerson': tagAPerson,
      'location': location,
      'createdAt': createdAt.toString(),
      'howMoneyMinutesAgo': howMoneyMinutesAgo,
      'like': like,
      'comment': comment,
      'popularityScore': popularityScore,
      'isLiked': isLiked,
    };
  }

  // Post içeriğinin doğrulanması
  bool hasValidContent() {
    return content.isNotEmpty &&
        content.any((url) =>
            url.isNotEmpty &&
            (url.toLowerCase().endsWith('.jpg') ||
                url.toLowerCase().endsWith('.jpeg') ||
                url.toLowerCase().endsWith('.png') ||
                url.toLowerCase().endsWith('.webp') ||
                VideoHelper.isVideoFile(url)));
  }

  // Add copyWith method for creating a new instance with modified properties
  PostDTO copyWith({
    String? postId,
    int? userId,
    String? username,
    List<String>? content,
    String? profilePhoto,
    String? description,
    List<String>? tagAPerson,
    String? location,
    DateTime? createdAt,
    String? howMoneyMinutesAgo,
    int? like,
    int? comment,
    int? popularityScore,
    bool? isLiked,
  }) {
    return PostDTO(
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      content: content ?? this.content,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      description: description ?? this.description,
      tagAPerson: tagAPerson ?? this.tagAPerson,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      howMoneyMinutesAgo: howMoneyMinutesAgo ?? this.howMoneyMinutesAgo,
      like: like ?? this.like,
      comment: comment ?? this.comment,
      popularityScore: popularityScore ?? this.popularityScore,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
