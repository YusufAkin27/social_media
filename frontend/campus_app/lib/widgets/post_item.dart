import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async'; // Timeout işlemleri için gerekli
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media/services/likeService.dart'; // Ensure this path is correct
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:social_media/screens/profile_screen.dart';
import 'package:like_button/like_button.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart'; // Import Dio
import 'package:social_media/services/commentService.dart'; // Import the CommentService
import 'package:visibility_detector/visibility_detector.dart'; // Görünürlük kontrolü için

class PostItem extends StatefulWidget {
  final Map<String, dynamic> post;
  final bool skipInvalidContent;

  const PostItem({
    Key? key,
    required this.post,
    this.skipInvalidContent = false,
  }) : super(key: key);

  @override
  _PostItemState createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> with SingleTickerProviderStateMixin {
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
  final LikeService _likeService = LikeService(); // Create an instance of LikeService
  final CommentService _commentService = CommentService(Dio()); // Create an instance of CommentService
  bool _showLikeAnimation = false;
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;

  // Fotoğraf geçiş animasyonu kontrolcüsü
  final PageController _mediaPageController = PageController();
  double _currentPageValue = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0, viewportFraction: 0.999); // Hafif bir örtüşme efekti için
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
      );
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreComments();
    }
  }

  void _checkIfLiked() async {
    // Backend'den beğeni durumu kontrol edilecek
    final postId = postData.postId;
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';

    try {
      final liked = await _likeService.checkPostLike(accessToken, postId);
      setState(() {
        isLiked = liked;
      });
    } catch (e) {
      print('Beğeni durumu kontrol edilirken hata: $e');
      setState(() {
        isLiked = false; // Default to false on error
      });
    }
  }

  void _checkIfRecorded() {
    // Backend'den kaydetme durumu kontrol edilecek
    setState(() {
      isRecorded = false; // Başlangıçta kaydedilmemiş olarak kabul edilir
    });
  }

  Future<void> _fetchComments() async {
    if (isLoadingComments) return;

    setState(() {
      isLoadingComments = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';
    final postId = postData.postId;

    // Create an instance of CommentService
    final commentService = CommentService(dioInstance); // Pass the Dio instance

    try {
      // Use the CommentService to get comments
      final response = await commentService.getPostComments(accessToken, postId, currentPage);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['data'] is List) {
          final List<CommentDTO> newComments = (data['data'] as List<dynamic>).map((x) {
            return CommentDTO.fromJson(x);
          }).toList();

          setState(() {
            if (currentPage == 0) {
              comments = newComments; // Reset comments on first page
            } else {
              comments.addAll(newComments); // Append new comments
            }
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

  Future<void> _loadMoreComments() {
    currentPage++;
    return _fetchComments();
  }

  Future<void> _toggleLike() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';
    final postId = postData.postId;

    try {
      bool success = false;
      
      if (!isLiked) {
        // Beğenme işlemi için doğrudan likePost kullanılır
        print('Gönderi beğeniliyor: $postId');
        final response = await _likeService.likePost(accessToken, postId);
        success = response != null && response.isSuccess == true;
      } else {
        // Beğeni kaldırma işlemi için API'deki uygun fonksiyonu çağır
        print('Gönderi beğenisi kaldırılıyor: $postId');
        
        // LikeService'de unlikePost metodu var mı kontrol et - burada doğrudan likePost kullanıyoruz
        final response = await _likeService.likePost(accessToken, postId);
        success = response != null && response.isSuccess == true;
      }
      
      if (success) {
        setState(() {
          isLiked = !isLiked;
          likeCount = isLiked ? likeCount + 1 : likeCount - 1;
          if (likeCount < 0) likeCount = 0;
        });
        
        // Haptic feedback ekleyelim
        HapticFeedback.mediumImpact();
        
        // Başarı mesajı
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isLiked ? 'Gönderi beğenildi' : 'Gönderi beğenisi kaldırıldı',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.black87,
            duration: Duration(milliseconds: 800),
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
          backgroundColor: Colors.red,
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
      margin: EdgeInsets.all(8.0),
      color: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      elevation: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                      username: username,
                    ),
                  ),
                );
              },
              child: CircleAvatar(
                backgroundImage: profilePhoto.isNotEmpty ?
                  NetworkImage(profilePhoto) : null,
                backgroundColor: Colors.grey[900],
                child: profilePhoto.isEmpty ?
                  Icon(Icons.person, color: Colors.white) : null,
              ),
            ),
            title: Text(
              username,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (location.isNotEmpty)
                  Text(
                    location,
                    style: TextStyle(color: Colors.white70),
                  ),
                _buildPopularityScore(),
              ],
            ),
            trailing: PopupMenuButton(
              icon: Icon(Icons.more_vert, color: Colors.white),
              color: Colors.black,
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Text('Şikayet Et', style: TextStyle(color: Colors.white)),
                  value: 'report',
                ),
                PopupMenuItem(
                  child: Text('Paylaş', style: TextStyle(color: Colors.white)),
                  value: 'share',
                ),
              ],
              onSelected: (value) {
                // Menü işlemleri
              },
            ),
          ),
          _buildMediaContent(),
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                description,
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          if (taggedPeople.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Wrap(
                spacing: 4,
                children: taggedPeople
                    .map<Widget>((username) => GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen(
                                  username: username,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            '@$username',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        );
                      },
                      likeBuilder: (isLiked) {
                        return Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.white,
                          size: 26,
                        );
                      },
                      onTap: (isLiked) async {
                        HapticFeedback.lightImpact();
                        _toggleLike(); // Call the toggleLike method
                        return !isLiked;
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.comment_outlined, color: Colors.white),
                      onPressed: () => _showCommentsModal(context),
                    ),
                    Text(
                      '$commentCount',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    isRecorded ? Icons.bookmark : Icons.bookmark_border,
                    color: Colors.white,
                  ),
                  onPressed: _toggleSave,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent() {
    if (!hasValidContent) {
      return Container(
        height: 200,
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: Colors.white, size: 48),
              SizedBox(height: 16),
              Text(
                'Geçerli medya içeriği bulunamadı',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Bu gönderi görüntülenemiyor',
                style: TextStyle(color: Colors.white70, fontSize: 14),
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
            physics: const BouncingScrollPhysics(), // İOS tarzı elastik kaydırma
            itemCount: allMediaUrls.length,
            itemBuilder: (context, index) {
              final String url = allMediaUrls[index];
              print('Medya oluşturuluyor: $url (${index+1}/${allMediaUrls.length})');
              
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
                          color: Colors.black.withOpacity(0.2),
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
                                onVisibilityChanged: (visibilityInfo) {
                                  // Görünürlük %60'dan fazla ise videoyu otomatik başlat
                                  if (visibilityInfo.visibleFraction > 0.6 && currentPage == index) {
                                    // Video görünür durumda
                                    print('Video görünür: $url');
                                  }
                                },
                                child: VideoPlayerWidget(videoUrl: url),
                              )
                            else
                              Image.network(
                                url,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / 
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  print('Resim yükleme hatası: $error');
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.error, color: Colors.white, size: 40),
                                        SizedBox(height: 10),
                                        Text(
                                          'Resim yüklenemedi',
                                          style: TextStyle(color: Colors.white),
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                            
                            // Video etiketini göster
                            if (_isVideoUrl(url))
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.videocam, color: Colors.white, size: 18),
                                      SizedBox(width: 4),
                                      Text('Video', style: TextStyle(color: Colors.white, fontSize: 12)),
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
                                          Icons.favorite,
                                          color: Colors.white.withOpacity(0.8),
                                          size: 110,
                                        ),
                                        // Ana kalp
                                        Icon(
                                          Icons.favorite,
                                          color: Colors.red,
                                          size: 100,
                                        ),
                                        // Parıltı efekti
                                        Icon(
                                          Icons.favorite,
                                          color: Colors.white.withOpacity(0.5),
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
                          ? Colors.white 
                          : Colors.white.withOpacity(0.5),
                      boxShadow: currentPage == index
                          ? [BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            )]
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
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                '${currentPage + 1}/${allMediaUrls.length}',
                style: TextStyle(
                  color: Colors.white,
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
                  if (details.primaryVelocity! < 0) { // Sola kaydırma (sonraki)
                    if (currentPage < allMediaUrls.length - 1) {
                      _pageController.animateToPage(
                        currentPage + 1,
                        duration: Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  } else if (details.primaryVelocity! > 0) { // Sağa kaydırma (önceki)
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
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  
                  // Orta alan - çift tıklama için
                  Expanded(
                    flex: 14,
                    child: Container(color: Colors.transparent),
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
                        child: Container(color: Colors.transparent),
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
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
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
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
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
    
    if (postData.popularityScore >= 90) {
      scoreColor = Colors.purple;
      scoreText = 'Trend';
    } else if (postData.popularityScore >= 70) {
      scoreColor = Colors.red;
      scoreText = 'Popüler';
    } else if (postData.popularityScore >= 50) {
      scoreColor = Colors.orange;
      scoreText = 'Yükseliyor';
    } else {
      scoreColor = Colors.blue;
      scoreText = 'Normal';
    }
    
    return Container(
      margin: EdgeInsets.only(top: 4),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black,
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
            Icons.trending_up,
            color: scoreColor,
            size: 16,
          ),
          SizedBox(width: 4),
          Text(
            '$scoreText: ${postData.popularityScore}',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentsModal(BuildContext context) {
    // Yorumları sıfırla ve ilk sayfayı yükle
    currentPage = 0;
    _fetchComments();
    
    // Modal için yeni bir ScrollController
    final ScrollController modalScrollController = ScrollController();
    
    // Scroll olayını dinle
    modalScrollController.addListener(() {
      if (modalScrollController.position.pixels >= modalScrollController.position.maxScrollExtent - 200) {
        _loadMoreComments();
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85, // Modal daha büyük olsun
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Sürüklenebilir çubuk
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Başlık
                  Row(
                    children: [
                      Text(
                        'Yorumlar (${comments.length})',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Divider(color: Colors.white.withOpacity(0.1)),
                  // Yorum listesi
                  Expanded(
                    child: comments.isNotEmpty
                        ? ListView.builder(
                            controller: modalScrollController,
                            itemCount: comments.length + (isLoadingComments ? 1 : 0),
                            itemBuilder: (context, index) {
                              // Yükleme göstergesi
                              if (index == comments.length) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }
                              
                              // Yorumları ters sırada göster (en yeni en üstte)
                              final comment = comments[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(comment.profilePhoto),
                                ),
                                title: Row(
                                  children: [
                                    Text(comment.username, 
                                        style: TextStyle(color: Colors.white)),
                                    SizedBox(width: 8),
                                    Text(
                                      '• ${comment.howManyMinutesAgo}',
                                      style: TextStyle(
                                        color: Colors.white70, 
                                        fontSize: 12
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  comment.content, 
                                  style: TextStyle(color: Colors.white70)
                                ),
                              );
                            },
                          )
                        : Center(
                            child: isLoadingComments 
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    'Henüz yorum yok.',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                          ),
                  ),
                  // Yorum giriş alanı
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey[800],
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Yorum yaz...',
                              hintStyle: TextStyle(color: Colors.white70),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.send, color: Colors.white),
                          onPressed: () {
                            _addComment();
                            setState(() {}); // Durumu güncellemek için StatefulBuilder ile
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
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

    // Create an instance of CommentService with the Dio instance
    final commentService = CommentService(dioInstance); // Pass the Dio instance

    try {
      // Use the CommentService to add a comment
      final response = await commentService.addCommentToPost(accessToken, postId, _commentController.text.trim());

      if (response.statusCode == 200 || response.statusCode == 201) {
        _commentController.clear();
        // Yorumları yeniden yükle
        currentPage = 0; // Reset to the first page
        await _fetchComments(); // Refresh comments to include the new one
        
        // Yorum sayısını güncelle
        setState(() {
          postData = PostDTO.fromJson({
            ...postData.toMap(),
            'comment': postData.comment + 1,
          });
        });
        
        // Başarı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Yorum başarıyla eklendi',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.black,
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yorum eklenirken bir hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yorum eklenirken bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoadingComments = false;
      });
    }
  }

  Future<void> _toggleSave() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';
    final postId = postData.postId;

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/v1/api/post/record/$postId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          isRecorded = !isRecorded;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRecorded ? 'Gönderi kaydedildi' : 'Gönderi kaydedilenlerden çıkarıldı',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.black,
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kaydetme işlemi sırasında bir hata oluştu'),
          backgroundColor: Colors.red,
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
    List<String> imageExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'];
    return imageExtensions.any((ext) => url.endsWith(ext));
  }
  
  // URL'nin bir video olup olmadığını kontrol eder
  bool _isVideoUrl(String url) {
    List<String> videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];
    return videoExtensions.any((ext) => url.endsWith(ext));
  }
}

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
  });

  factory PostDTO.fromJson(Map<String, dynamic> json) {
    return PostDTO(
      postId: json['postId'] ?? '',
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      content: List<String>.from(json['content'] ?? []).where((url) => 
          url != null && url.isNotEmpty).toList(),
      profilePhoto: json['profilePhoto'] ?? '',
      description: _safeDecodeUtf8(json['description'] ?? ''),
      tagAPerson: List<String>.from(json['tagAPerson'] ?? []),
      location: json['location'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      howMoneyMinutesAgo: json['howMoneyMinutesAgo'] ?? '',
      like: json['like'] ?? 0,
      comment: json['comment'] ?? 0,
      popularityScore: json['popularityScore'] ?? 0,
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
    };
  }
  
  // Post içeriğinin doğrulanması
  bool hasValidContent() {
    return content.isNotEmpty && content.any((url) => 
      url.isNotEmpty && 
      (url.toLowerCase().endsWith('.jpg') || 
      url.toLowerCase().endsWith('.jpeg') || 
      url.toLowerCase().endsWith('.png') || 
      url.toLowerCase().endsWith('.webp')));
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  late Timer _loadingTimeout;
  bool _isPlaying = false;
  bool _isControlVisible = false;
  late String videoId;

  @override
  void initState() {
    super.initState();
    // Her video için benzersiz bir ID oluştur
    videoId = DateTime.now().millisecondsSinceEpoch.toString();
    _initializePlayer();
    
    // Video yüklemesi için zaman aşımı kontrolü
    _loadingTimeout = Timer(Duration(seconds: 15), () {
      if (!_isInitialized && mounted) {
        setState(() {
          _hasError = true;
        });
      }
    });
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
      
      await _videoPlayerController.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,  // Otomatik başlat
        autoInitialize: true,
        looping: true,   // Sürekli döngü
        aspectRatio: _videoPlayerController.value.aspectRatio,
        showControls: false, // Kendi kontrollerimizi kullanacağız
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 30),
                SizedBox(height: 8),
                Text(
                  'Video oynatılamıyor',
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(
                  errorMessage,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
        placeholder: Container(
          color: Colors.black,
          child: Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3.0,
            ),
          ),
        ),
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.white,
          handleColor: Colors.white,
          backgroundColor: Colors.white.withOpacity(0.2),
          bufferedColor: Colors.white.withOpacity(0.5),
        ),
      );
      
      _videoPlayerController.play(); // Otomatik başlat
      setState(() {
        _isInitialized = true;
        _isPlaying = true;
      });
    } catch (e) {
      print('Video oynatıcı başlatılırken hata: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _videoPlayerController.pause();
    } else {
      _videoPlayerController.play();
    }
    
    setState(() {
      _isPlaying = !_isPlaying;
      _isControlVisible = true;
    });
    
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    // Kontrol butonunu 2 saniye sonra gizle
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isControlVisible = false;
        });
      }
    });
  }
  
  // Görünürlüğünü kaybedince videoyu durdur, görünür olunca oynat
  void handleVisibilityChanged(bool isVisible) {
    if (_isInitialized) {
      if (isVisible) {
        _videoPlayerController.play();
        setState(() {
          _isPlaying = true;
        });
      } else {
        _videoPlayerController.pause();
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _loadingTimeout.cancel();
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.white60, size: 40),
              SizedBox(height: 8),
              Text(
                'Video yüklenemedi',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 4),
              Text(
                'Desteklenen format: mp4',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
    
    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3.0,
              ),
              SizedBox(height: 12),
              Text(
                'Video yükleniyor...',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.black,
            child: Chewie(controller: _chewieController!),
          ),
          
          // Oynatma/Duraklatma göstergesi - sadece durum değiştiğinde görünür
          if (_isControlVisible)
            AnimatedOpacity(
              opacity: _isControlVisible ? 1.0 : 0.0,
              duration: Duration(milliseconds: 300),
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
            
          // Video ilerleme çubuğu alt kısımda
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder(
              valueListenable: _videoPlayerController,
              builder: (context, VideoPlayerValue value, child) {
                // Video süresini ve ilerlemeyi göster
                final duration = value.duration;
                final position = value.position;
                
                // İlerleme yüzdesi
                final double progress = position.inMilliseconds / 
                    (duration.inMilliseconds == 0 ? 1 : duration.inMilliseconds);
                
                return Container(
                  height: 20,
                  padding: EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // İlerleme arka planı
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        height: 3,
                      ),
                      // İlerleme çubuğu
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          height: 3,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 