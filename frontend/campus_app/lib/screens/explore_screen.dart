import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:line_icons/line_icons.dart';
import 'package:social_media/services/studentService.dart';
import 'package:social_media/models/search_account_dto.dart';
import 'package:social_media/models/best_popularity_account.dart';
import 'package:social_media/models/response_message.dart';
import 'package:flutter/widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import 'package:dio/dio.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingUsers = false;
  bool _isLoadingPosts = false;
  bool _isLoadingStories = false;
  List<BestPopularityAccount> _trendingUsers = [];
  List<dynamic> _trendingPosts = [];
  List<dynamic> _trendingStories = [];
  List<SearchAccountDTO> _searchResults = [];
  bool _isSearching = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final StudentService _studentService = StudentService();
  final Dio _dio = Dio();
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    _loadAllData();
    _searchController.addListener(_onSearchChanged);
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
    } else if (query.length >= 2) {
      _performSearch(query);
    }
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadTrendingUsers(),
      _loadTrendingPosts(),
      _loadTrendingStories(),
    ]);
  }

  Future<void> _loadTrendingUsers() async {
    setState(() {
      _isLoadingUsers = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';
      
      final response = await _studentService.getBestPopularity(accessToken);

      final isSuccess = response.isSuccess ?? false;
      
      if (isSuccess) {
        setState(() {
          _trendingUsers = response.data ?? [];
          _isLoadingUsers = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Popüler kullanıcılar yüklenirken hata: ${response.message}';
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Kullanıcı verisi yüklenirken hata: $e';
        _isLoadingUsers = false;
        print('Profil verileri yüklenirken hata detayı: $e');
      });
    }
  }

  Future<void> _loadTrendingPosts() async {
    setState(() {
      _isLoadingPosts = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';
      
      final response = await _dio.get(
        'https://api.yourserver.com/post/getPopularity',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null) {
          setState(() {
            _trendingPosts = data['data'] ?? [];
            _isLoadingPosts = false;
          });
        } else {
          setState(() {
            _isLoadingPosts = false;
          });
        }
      } else {
        setState(() {
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      setState(() {
        print('Gönderi verisi yüklenirken hata: $e');
        _isLoadingPosts = false;
      });
    }
  }

  Future<void> _loadTrendingStories() async {
    setState(() {
      _isLoadingStories = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';
      
      final response = await _dio.get(
        'https://api.yourserver.com/story/popular',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null) {
          setState(() {
            _trendingStories = data['data'] ?? [];
            _isLoadingStories = false;
          });
        } else {
          setState(() {
            _isLoadingStories = false;
          });
        }
      } else {
        setState(() {
          _isLoadingStories = false;
        });
      }
    } catch (e) {
      setState(() {
        print('Hikaye verisi yüklenirken hata: $e');
        _isLoadingStories = false;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';
      
      final response = await _studentService.search(accessToken, query, 1);
      
      final isSuccess = response.isSuccess ?? false;
      
      if (isSuccess) {
        setState(() {
          _searchResults = response.data ?? [];
          _isSearching = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Arama yapılırken hata: ${response.message}';
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Bağlantı hatası: $e';
        _isSearching = false;
        print('Arama yapılırken hata detayı: $e');
      });
    }
  }

  bool _isAllContentLoading() {
    return _isLoadingUsers || _isLoadingPosts || _isLoadingStories;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: _buildSearchField(),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.qrcode_viewfinder, color: Colors.white),
            onPressed: () {
              // QR kod okuyucu özelliği
            },
          ),
        ],
      ),
      body: _isAllContentLoading()
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _errorMessage != null
              ? _buildErrorWidget()
              : Stack(
                  children: [
                    // Trend içerik her zaman arka planda
                    _buildExploreContent(),
                    
                    // Arama sonuçları üstte ve arama yapılırken görünür
                    if (_isSearching || _searchController.text.isNotEmpty)
                      _buildBlurredSearchResults(),
                  ],
                ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Ara...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(CupertinoIcons.search, color: Colors.grey[400], size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
        onSubmitted: _performSearch,
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
          SizedBox(height: 16),
          Text(
            'Hata',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _errorMessage ?? 'Bilinmeyen bir hata oluştu',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadAllData,
            icon: Icon(Icons.refresh),
            label: Text('Tekrar Dene'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurredSearchResults() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withOpacity(0.7),
              child: _buildSearchResults(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.search, size: 60, color: Colors.white54),
            SizedBox(height: 16),
            Text(
              'Sonuç bulunamadı',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              'Farklı bir arama terimi deneyin',
              style: TextStyle(color: Colors.white60),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserListItem(user);
      },
    );
  }

  Widget _buildUserListItem(SearchAccountDTO user) {
    // Null güvenliği ekleyelim
    final bool isPrivate = user.isPrivate ?? false;
    final bool isFollow = user.isFollow ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 2,
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: user.profilePhoto.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: user.profilePhoto,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[800],
                      child: Icon(Icons.person, color: Colors.white30),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[800],
                      child: Icon(Icons.error, color: Colors.white30),
                    ),
                  )
                : Container(
                    color: Colors.grey[800],
                    child: Center(
                      child: Text(
                        user.username[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        title: Text(
          user.fullName ?? user.username,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Text(
              '@${user.username}',
              style: TextStyle(color: Colors.grey[400]),
            ),
            if (isPrivate)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(Icons.lock, color: Colors.grey[400], size: 14),
              ),
          ],
        ),
        trailing: ElevatedButton(
          child: Text(isFollow ? 'Takip Ediliyor' : 'Takip Et'),
          onPressed: () {
            // Takip etme işlevi
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isFollow ? Colors.grey[800] : Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
        onTap: () {
          // Kullanıcı profiline git
          Navigator.pushNamed(context, '/user-profile', arguments: {'userId': user.id});
        },
      ),
    );
  }

  Widget _buildExploreContent() {
    if (_trendingUsers.isEmpty && _trendingPosts.isEmpty && _trendingStories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LineIcons.fire, size: 60, color: Colors.white54),
            SizedBox(height: 16),
            Text(
              'Henüz trend içerik yok',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // BÖLÜM 1: EN POPÜLER KULLANICILAR
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Popüler Kullanıcılar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Tümünü göster
                  },
                  child: Text(
                    'Tümünü Gör',
                    style: TextStyle(color: Colors.blue),
                  ),
                )
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _isLoadingUsers
              ? Center(child: CircularProgressIndicator())
              : Container(
                  height: 200,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _trendingUsers.length > 10 ? 10 : _trendingUsers.length,
                    itemBuilder: (context, index) {
                      final user = _trendingUsers[index];
                      return _buildPopularUserCard(user);
                    },
                  ),
                ),
        ),
        
        // BÖLÜM 2: EN POPÜLER GÖNDERİLER
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 32, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Popüler Gönderiler',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Tümünü göster
                  },
                  child: Text(
                    'Tümünü Gör',
                    style: TextStyle(color: Colors.blue),
                  ),
                )
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _isLoadingPosts
              ? Center(child: CircularProgressIndicator())
              : _trendingPosts.isEmpty
                  ? _buildEmptySection('Henüz popüler gönderi bulunmuyor')
                  : Container(
                      height: 250,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: _trendingPosts.length > 10 ? 10 : _trendingPosts.length,
                        itemBuilder: (context, index) {
                          final post = _trendingPosts[index];
                          return _buildPopularPostCard(post);
                        },
                      ),
                    ),
        ),
        
        // BÖLÜM 3: EN POPÜLER HİKAYELER
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 32, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Popüler Hikayeler',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Tümünü göster
                  },
                  child: Text(
                    'Tümünü Gör',
                    style: TextStyle(color: Colors.blue),
                  ),
                )
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _isLoadingStories
              ? Center(child: CircularProgressIndicator())
              : _trendingStories.isEmpty
                  ? _buildEmptySection('Henüz popüler hikaye bulunmuyor')
                  : Container(
                      height: 180,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: _trendingStories.length > 10 ? 10 : _trendingStories.length,
                        itemBuilder: (context, index) {
                          final story = _trendingStories[index];
                          return _buildPopularStoryCard(story);
                        },
                      ),
                    ),
        ),
        
        // Alttan padding
        SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }
  
  Widget _buildEmptySection(String message) {
    return Container(
      height: 150,
      alignment: Alignment.center,
      child: Text(
        message,
        style: TextStyle(
          color: Colors.white60,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildPopularUserCard(BestPopularityAccount user) {
    final bool isPrivate = user.isPrivate ?? false;
    final int followerCount = user.followerCount ?? 0;
    final int popularityScore = user.popularityScore ?? 0;
    
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/user-profile', arguments: {'userId': user.userId});
      },
      child: Container(
        width: 140,
        margin: EdgeInsets.only(right: 12, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Profil resmi
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  image: DecorationImage(
                    image: user.profilePhoto.isNotEmpty
                        ? CachedNetworkImageProvider(user.profilePhoto)
                        : AssetImage('assets/images/default_profile.png') as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    // Özel hesap işareti
                    if (isPrivate)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock, 
                            color: Colors.white, 
                            size: 16
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Kullanıcı bilgileri
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        LineIcons.fire,
                        color: Colors.orange,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '$popularityScore',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '$followerCount',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        LineIcons.userFriends,
                        color: Colors.white70,
                        size: 14,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPopularPostCard(dynamic post) {
    final String username = post['username'] ?? 'Kullanıcı';
    final String? profilePhoto = post['profilePhoto'];
    final String? content = post['content'];
    final String? text = post['text'];
    final int likeCount = post['likeCount'] ?? 0;
    final String createdAt = post['createdAt'] ?? '';
    
    return Container(
      width: 300,
      margin: EdgeInsets.only(right: 12, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kullanıcı bilgisi satırı
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: profilePhoto != null && profilePhoto.isNotEmpty
                      ? CachedNetworkImageProvider(profilePhoto)
                      : null,
                  backgroundColor: Colors.grey[800],
                  child: profilePhoto == null || profilePhoto.isEmpty
                      ? Icon(Icons.person, size: 16, color: Colors.white)
                      : null,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        createdAt,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LineIcons.heart,
                  color: Colors.red,
                  size: 22,
                ),
                SizedBox(width: 4),
                Text(
                  '$likeCount',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Gönderi içeriği
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                image: content != null && content.isNotEmpty
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(content),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: content == null || content.isEmpty
                  ? Center(
                      child: Text(
                        text ?? '',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : null,
            ),
          ),
          
          // Alt bilgiler
          Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              text ?? 'Gönderi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPopularStoryCard(dynamic story) {
    // Dinamik veri için güvenli erişim
    final String username = story['username'] ?? 'Kullanıcı';
    final String? profilePhoto = story['profilePhoto'];
    final String? content = story['content'];
    final int viewCount = story['viewCount'] ?? 0;
    
    return Container(
      width: 110,
      margin: EdgeInsets.only(right: 12, top: 8, bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple,
            Colors.pink,
            Colors.orange,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(2), // Gradient için kenarlık
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            // Story içeriği
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: content != null && content.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: content,
                      fit: BoxFit.cover,
                      height: double.infinity,
                      width: double.infinity,
                    )
                  : Container(
                      color: Colors.grey[800],
                      child: Center(
                        child: Icon(
                          LineIcons.book,
                          color: Colors.white54,
                          size: 30,
                        ),
                      ),
                    ),
            ),
            
            // Kullanıcı bilgisi
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(10),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: profilePhoto != null && profilePhoto.isNotEmpty
                              ? CachedNetworkImageProvider(profilePhoto)
                              : null,
                          backgroundColor: Colors.grey[800],
                          child: profilePhoto == null || profilePhoto.isEmpty
                              ? Text(
                                  username.isNotEmpty ? username[0].toUpperCase() : '',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            username,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Görüntüleme sayısı
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LineIcons.eye, color: Colors.white, size: 12),
                    SizedBox(width: 2),
                    Text(
                      '$viewCount',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}d';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}s';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}g';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
} 