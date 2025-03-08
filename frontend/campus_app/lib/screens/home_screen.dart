import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media/widgets/story_item.dart' hide PostDTO;
import 'package:social_media/widgets/post_item.dart';
import 'package:social_media/screens/user_profile_screen.dart' as userProfile;
import 'package:line_icons/line_icons.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:social_media/screens/add_story_screen.dart';
import 'package:social_media/services/studentService.dart';
import 'package:social_media/services/storyService.dart';
import 'package:dio/dio.dart';
import 'package:social_media/widgets/sidebar.dart';
import 'package:social_media/models/student_dto.dart';
import 'package:social_media/models/home_story_dto.dart';
import 'package:social_media/models/post_dto.dart' as model;
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<HomeStoryDTO> stories = [];
  List<model.PostDTO> posts = [];
  List<dynamic> suggestedUsers = [];
  bool isDarkTheme = true;
  bool isLoadingStories = true;
  bool isLoadingPosts = true;
  bool isRefreshing = false;
  bool hasMorePosts = true;
  bool isLoadingMorePosts = false;
  bool isLoadingSuggestions = true;
  bool isLoadingUserStories = true;
  
  late ScrollController _scrollController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final StudentService _studentService = StudentService();
  int _currentPage = 0;
  List<dynamic> userStories = [];
  StudentDTO? profileData;
  final StoryService _storyService = StoryService(Dio());

  // Renk paleti
  final Color primaryColor = Colors.black;
  final Color accentColor = Colors.blue[700] ?? Colors.blue;
  final Color cardColor = Color(0xFF1E1E1E);
  final Color textColor = Colors.white;
  final Color textMutedColor = Colors.white70;
  final Color dividerColor = Colors.white24;
  final Color shimmerBaseColor = Color(0xFF1F1F1F);
  final Color shimmerHighlightColor = Color(0xFF3A3A3A);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _loadThemePreference();
    _loadData();
    _fetchSuggestedUsers();
    _fetchUserStories();
    _fetchProfileData();

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 500 && 
        !isLoadingMorePosts && 
        hasMorePosts) {
      _loadMorePosts();
    }
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkTheme = prefs.getBool('isDarkTheme') ?? true;
    });
  }

  Future<void> _loadData() async {
    setState(() { 
      isRefreshing = true;
      isLoadingStories = true;
      isLoadingPosts = true;
      _currentPage = 0;
    });
    
    await Future.wait([
      _fetchStories(),
      _fetchPosts(),
    ]);
    
    _animationController.forward(from: 0.0);
    
    setState(() {
      isRefreshing = false;
      isLoadingStories = false;
      isLoadingPosts = false;
    });
  }

  Future<void> _fetchStories() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';

    try {
      final response = await _studentService.getHomeStories(accessToken, 0);
      
      if (response.isSuccess && response.data != null) {
        setState(() {
          stories = response.data!;
          print('Hikayeler yüklendi: ${stories.length}');
          isLoadingStories = false;
        });
      } else {
        print('Hikayeler yüklenirken hata: ${response.message}');
        setState(() {
          isLoadingStories = false;
        });
      }
    } catch (e) {
      print('Hikayeler yüklenirken hata: $e');
      setState(() {
        isLoadingStories = false;
      });
    }
  }

  Future<void> _fetchPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';

    try {
      print('Gönderiler için API isteği yapılıyor...');
      final response = await _studentService.getHomePosts(accessToken, _currentPage);
      
      if (response.isSuccess && response.data != null) {
        print('API yanıtı başarılı, gelen gönderi sayısı: ${response.data!.length}');
        
        setState(() {
          posts = response.data!;
          hasMorePosts = response.data!.length >= 10; // Sayfa başına 10 gönderi varsayımı
          _currentPage++;
          isLoadingPosts = false;
          
          // Gelen verilerin kontrolü
          if (posts.isEmpty) {
            print('Hiç gönderi bulunamadı!');
          } else {
            print('Gönderiler başarıyla yüklendi, toplam ${posts.length} gönderi var');
            
            // Daha detaylı debug bilgisi için gönderi içeriklerini kontrol et
            for (var post in posts) {
              print('---------------------------');
              print('Gönderi ID: ${post.postId}');
              print('Kullanıcı adı: ${post.username}');
              print('İçerik sayısı: ${post.content.length}');
              if (post.content.isNotEmpty) {
                print('İlk medya URL: ${post.content.first}');
              } else {
                print('Gönderi medya içeriği boş!');
              }
            }
          }
        });
      } else {
        print('Gönderiler yüklenirken hata mesajı: ${response.message}');
        setState(() {
          isLoadingPosts = false;
        });
      }
    } catch (e) {
      print('Gönderiler yüklenirken istisna oluştu: $e');
      setState(() {
        isLoadingPosts = false;
      });
    }
  }

  Future<void> _fetchSuggestedUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';

    try {
      final response = await _studentService.getSuggestedConnections(accessToken);
      if (response.isSuccess && response.data != null) {
        setState(() {
          suggestedUsers = response.data!;
          isLoadingSuggestions = false;
        });
      } else {
        print('Önerilen kullanıcılar yüklenirken hata: ${response.message}');
      }
    } catch (e) {
      print('Önerilen kullanıcılar yüklenirken hata: $e');
    }
  }

  Future<void> _loadMorePosts() async {
    if (isLoadingMorePosts) return;
    
    setState(() {
      isLoadingMorePosts = true;
    });
    
    _currentPage++;
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';

    try {
      final response = await _studentService.getHomePosts(accessToken, _currentPage);
      
      if (response.isSuccess && response.data != null) {
        setState(() {
          posts.addAll(response.data!);
          hasMorePosts = response.data!.length >= 10; // Sayfa başına 10 gönderi varsayımı
          isLoadingMorePosts = false;
        });
      } else {
        setState(() {
          isLoadingMorePosts = false;
          hasMorePosts = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingMorePosts = false;
      });
      print('Daha fazla gönderi yüklenirken hata: $e');
    }
  }

  Future<void> _fetchUserStories() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';

    try {
      final response = await _storyService.getStories(accessToken, 0);
      if (response.isSuccess && response.data != null) {
        setState(() {
          userStories = response.data!;
          isLoadingUserStories = false;
        });
      } else {
        print('Kullanıcı hikayeleri yüklenirken hata: ${response.message}');
      }
    } catch (e) {
      print('Kullanıcı hikayeleri yüklenirken hata: $e');
    }
  }

  Future<void> _fetchProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';

    try {
      final response = await _studentService.getProfile(accessToken);
      if (response.isSuccess) {
        setState(() {
          profileData = response.data;
        });
      } else {
        print('Profil verileri yüklenirken hata: ${response.message}');
      }
    } catch (e) {
      print('Profil verileri yüklenirken hata: $e');
    }
  }

  void _showDevelopmentMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Geliştirme aşamasındayız, bunun için üzgünüz.'),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.white, width: 1),
        ),
        duration: Duration(seconds: 2),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkTheme = !isDarkTheme;
      prefs.setBool('isDarkTheme', isDarkTheme);
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    
    return Scaffold(
      backgroundColor: primaryColor,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: accentColor,
        backgroundColor: cardColor,
        strokeWidth: 2.5,
        displacement: 120,
        edgeOffset: 20,
        child: CustomScrollView(
          controller: _scrollController,
          physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // Logo ve uygulama başlığı
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/logo.png', // Logo assets içinde olmalı
                      height: 36,
                      width: 36,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Campus App',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: textColor,
                      ),
                    ),
                    Spacer(),
                  ],
                ),
              ),
            ),
            
            // Hikayeler
            SliverToBoxAdapter(
              child: _buildStoriesSection(),
            ),
            
            // Ayırıcı
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Divider(
                  color: dividerColor,
                  height: 1,
                  thickness: 0.5,
                ),
              ),
            ),
            
            // Önerilen kişiler (yeterli sayıda varsa)
            if (suggestedUsers.length > 2)
              _buildSuggestedUsersSection(),
              
            // Gönderiler
            isLoadingPosts && !isRefreshing ? 
              _buildPostsLoadingShimmer() : 
              _buildPostsSection(),
              
            // Yükleniyor indikatörü
            if (isLoadingMorePosts)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(
                      color: accentColor,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
              
            // Alt boşluk
            SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Sidebar(
        profilePhotoUrl: profileData?.profilePhoto ?? 'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg'
      ),
    );
  }
  
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.2),
      elevation: 0,
      toolbarHeight: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    );
  }

  Widget _buildStoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text(
            'Hikayeler',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          height: 110,
          child: isLoadingStories && !isRefreshing ? 
            _buildStoriesLoadingShimmer() :
            FadeTransition(
              opacity: _fadeAnimation,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 12),
                itemCount: _buildStoryItemCount(),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildAddStoryItem();
                  }
                  
                  // Kullanıcının kendi hikayeleri
                  if (userStories.isNotEmpty && index <= userStories.length) {
                    return _buildEnhancedStoryItem(
                      userStories[index - 1], 
                      isUserStory: true
                    );
                  }
                  
                  // Diğer kullanıcıların hikayeleri
                  final int storyIndex = index - 1 - (userStories.isEmpty ? 0 : userStories.length);
                  if (stories.isNotEmpty && storyIndex < stories.length) {
                    return _buildEnhancedStoryItem(
                      stories[storyIndex],
                      isUserStory: false
                    );
                  }
                  
                  return Container();
                },
              ),
            ),
        ),
      ],
    );
  }
  
  Widget _buildStoriesLoadingShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 12),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: shimmerBaseColor,
          highlightColor: shimmerHighlightColor,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: shimmerBaseColor,
                    border: Border.all(
                      color: Colors.white24,
                      width: 2,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: shimmerBaseColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildEnhancedStoryItem(dynamic story, {required bool isUserStory}) {
    // Bu fonksiyon StoryItem widget'ını çağırabilir veya tamamen özelleştirilmiş bir hikaye öğesi oluşturabilir
    String name = '';
    String profilePhoto = '';
    String storyContent = '';
    bool isViewed = false;
    
    // Tür kontrolü ve veri çıkarma
    if (story is HomeStoryDTO) {
      name = story.username;
      profilePhoto = story.profilePhoto;
      storyContent = story.photos.isNotEmpty ? story.photos.first : '';
      isViewed = story.isVisited;
    } else {
      // Diğer türdeki hikaye nesnelerini işleyin (örneğin userStories)
      name = story['username'] ?? 'Kullanıcı';
      profilePhoto = story['profilePhoto'] ?? '';
      storyContent = story['photos'] != null && story['photos'].isNotEmpty ? story['photos'][0] : '';
      isViewed = story['isVisited'] ?? false;
    }
    
    return GestureDetector(
      onTap: () {
        // Hikaye görüntüleme ekranına git
        _showDevelopmentMessage();
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 75,
                  height: 75,
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isViewed ? null : LinearGradient(
                      colors: [
                        Colors.purple,
                        Colors.pink,
                        Colors.orange,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: profilePhoto.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: profilePhoto,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[900],
                                child: Icon(
                                  LineIcons.user,
                                  color: Colors.white54,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[900],
                                child: Icon(
                                  LineIcons.exclamationCircle,
                                  color: Colors.white54,
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey[900],
                              child: Icon(
                                LineIcons.user,
                                color: Colors.white54,
                              ),
                            ),
                    ),
                  ),
                ),
                if (isUserStory)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor,
                        border: Border.all(
                          color: primaryColor,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              name,
              style: TextStyle(
                color: isViewed ? textMutedColor : textColor,
                fontSize: 12,
                fontWeight: isViewed ? FontWeight.normal : FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddStoryItem() {
    return GestureDetector(
      onTap: () async {
        final refreshNeeded = await Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => AddStoryScreen())
        );
        
        if (refreshNeeded == true) {
          _loadData();
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withOpacity(0.8),
                        accentColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(2),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor,
                      ),
                      child: Center(
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accentColor,
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              'Hikaye Ekle',
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _buildStoryItemCount() {
    if (userStories.isEmpty && stories.isEmpty) {
      return 1;
    }
    
    return 1 + (userStories.isEmpty ? 0 : userStories.length) + stories.length;
  }
  
  Widget _buildSuggestedUsersSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Senin İçin Öneriler',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Tümünü gör
                      _showDevelopmentMessage();
                    },
                    child: Text(
                      'Tümünü Gör',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      minimumSize: Size(0, 0),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 12),
                itemCount: suggestedUsers.length,
                itemBuilder: (context, index) {
                  final user = suggestedUsers[index];
                  return _buildSuggestedUserCard(user);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSuggestedUserCard(dynamic user) {
    // Gerçek uygulamada, kullanıcı verileri modelden alınır
    final String username = user['username'] ?? 'Kullanıcı';
    final String fullName = user['fullName'] ?? 'İsim Belirtilmedi';
    final String profilePhoto = user['profilePhoto'] ?? '';
    final bool isVerified = user['isVerified'] ?? false;
    
    return Container(
      width: 160,
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dividerColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Profil fotoğrafı
          Container(
            padding: EdgeInsets.all(16),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: dividerColor,
              backgroundImage: profilePhoto.isNotEmpty
                  ? NetworkImage(profilePhoto)
                  : null,
              child: profilePhoto.isEmpty
                  ? Text(
                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          
          // Kullanıcı bilgileri
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        username,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (isVerified)
                      Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.verified,
                          color: accentColor,
                          size: 16,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  fullName,
                  style: TextStyle(
                    color: textMutedColor,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Takip et butonu
          Spacer(),
          Padding(
            padding: EdgeInsets.all(12),
            child: ElevatedButton(
              onPressed: () {
                // Takip et
                _showDevelopmentMessage();
              },
              child: Text('Takip Et'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: Size(double.infinity, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPostsLoadingShimmer() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Shimmer.fromColors(
            baseColor: shimmerBaseColor,
            highlightColor: shimmerHighlightColor,
            child: Container(
              margin: EdgeInsets.fromLTRB(16, 0, 16, 24),
              height: 400,
              decoration: BoxDecoration(
                color: shimmerBaseColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kullanıcı bilgisi
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white24,
                          ),
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 120,
                              height: 14,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(7),
                                color: Colors.white24,
                              ),
                            ),
                            SizedBox(height: 6),
                            Container(
                              width: 80,
                              height: 10,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: Colors.white24,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // İçerik
                  Expanded(
                    child: Container(
                      color: Colors.white24,
                    ),
                  ),
                  
                  // Alt bilgiler
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 100,
                              height: 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white24,
                              ),
                            ),
                            Spacer(),
                            Container(
                              width: 60,
                              height: 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white24,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          height: 16,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white24,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.7,
                          height: 16,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        childCount: 3,
      ),
    );
  }

  Widget _buildPostsSection() {
    if (posts.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 50.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.white60,
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'Henüz gönderi yok',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Takip ettikleriniz bir şeyler paylaştığında burada görünecek',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    print('Toplam ${posts.length} gönderi görüntüleniyor');
    
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final post = posts[index];
          print('Gönderi yapılandırılıyor: #$index, ID: ${post.postId}');
          
          try {
            // JSON verilerini hazırlayalım
            final Map<String, dynamic> postData = {
              'postId': post.postId,
              'userId': post.userId,
              'username': post.username,
              'content': post.content,
              'profilePhoto': post.profilePhoto,
              'description': post.description,
              'tagAPerson': post.tagAPerson,
              'location': post.location,
              'createdAt': post.createdAt.toString(),
              'howMoneyMinutesAgo': post.howMoneyMinutesAgo,
              'like': post.like,
              'comment': post.comment,
              'popularityScore': post.popularityScore,
            };
            
            // PostItem'a gönderilecek verileri kontrol et
            print('PostItem için hazırlanan veri: ${postData.keys.join(", ")}');
            if (postData['content'] is List) {
              print('Content listesi uzunluğu: ${(postData['content'] as List).length}');
            } else {
              print('Content listesi değil! Tipi: ${postData['content'].runtimeType}');
            }
            
            return FadeTransition(
              opacity: _fadeAnimation,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 500),
                builder: (context, double value, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      // Gönderi detaylarına git
                      _showDevelopmentMessage();
                    },
                    child: PostItem(
                      post: postData,
                      skipInvalidContent: false,
                    ),
                  ),
                ),
              ),
            );
          } catch (e) {
            print('Gönderi #$index oluşturulurken hata: $e');
            return Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gönderi yüklenirken hata',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    e.toString(),
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }
        },
        childCount: posts.length,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
