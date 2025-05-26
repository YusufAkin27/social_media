import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media/widgets/story_item.dart' hide PostDTO;
import 'package:social_media/widgets/post_item.dart';
import 'package:social_media/screens/user_profile_screen.dart' as userProfile;
import 'package:line_icons/line_icons.dart';
import 'package:social_media/screens/add_story_screen.dart';
import 'package:social_media/services/studentService.dart';
import 'package:social_media/services/storyService.dart';
import 'package:dio/dio.dart';
import 'package:social_media/widgets/sidebar.dart';
import 'package:social_media/widgets/header.dart';
import 'package:social_media/models/student_dto.dart';
import 'package:social_media/models/home_story_dto.dart';
import 'package:social_media/models/post_dto.dart' as model;
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import 'package:social_media/screens/messages_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:social_media/screens/story_viewer_screen.dart';
import 'package:social_media/screens/no_story_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:social_media/screens/chatbot_screen.dart';
import 'package:social_media/theme/app_theme.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:social_media/utils/video_helper.dart';
import 'package:provider/provider.dart';
import 'package:social_media/theme/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<HomeStoryDTO> stories = [];
  List<model.PostDTO> posts = [];
  List<dynamic> suggestedUsers = [];
  List<String> _suggestedUsernames = [];
  bool isLoadingStories = true;
  bool isLoadingPosts = true;
  bool isRefreshing = false;
  bool hasMorePosts = true;
  bool isLoadingMorePosts = false;
  bool isLoadingSuggestions = true;
  bool isLoadingUserStories = true;
  bool _isSuggestedUsersLoading = true;
  String? _suggestedError;

  // Bildirim ve mesaj sayıları
  int notificationCount = 5; // Örnek değer
  int messageCount = 3; // Örnek değer

  late ScrollController _scrollController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final StudentService _studentService = StudentService();
  int _currentPage = 0;
  List<dynamic> userStories = [];
  StudentDTO? profileData;
  final StoryService _storyService = StoryService(Dio());

  // Mesajlar sayfasına geçiş için page controller
  final PageController _pageController = PageController(initialPage: 1);

  // Key for header to reload it when state changes
  final GlobalKey _headerKey = GlobalKey();

  // Chatbot için değişkenler
  bool _isChatbotVisible = true;
  bool _isChatbotExpanded = false;
  final GlobalKey _chatbotKey = GlobalKey();

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

    // İlk hikaye ve gönderi yüklemesi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Frame çizimleri tamamlandıktan sonra verileri yükle
      _loadStories(); // Yeni doğrudan çağrı
      _fetchUserStories();
      _loadPosts();
      _fetchSuggestedUsers();
      _fetchProfileData();
    });

    _scrollController.addListener(_onScroll);
    _animationController.forward();

    // Chatbot'u 2 saniye sonra göster
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isChatbotVisible = true;
        });
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
            _scrollController.position.maxScrollExtent - 500 &&
        !isLoadingMorePosts &&
        hasMorePosts) {
      _loadMorePosts();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      isRefreshing = true;
      isLoadingStories = true;
      isLoadingPosts = true;
      _currentPage = 0;
    });

    print("Starting to load data - stories and posts");

    try {
      // Just call each method directly since we'll handle errors in each one
      await _loadStories();
      await _loadPosts();
      await _fetchSuggestedUsers();

      print("Data loading completed successfully");

      // After loading, check story data
      if (stories.isEmpty) {
        print("WARNING: Stories list is empty after loading");
      } else {
        print("SUCCESS: Loaded ${stories.length} stories");
      }
    } catch (e) {
      print("ERROR in _loadData: $e");
    }

    _animationController.forward(from: 0.0);

    setState(() {
      isRefreshing = false;
      isLoadingStories = false;
      isLoadingPosts = false;
    });
  }

  Future<void> _loadStories() async {
    print("=== LOADING STORIES - START ===");
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null || accessToken.isEmpty) {
      print("ERROR: Access token is null or empty");
      setState(() {
        isLoadingStories = false;
      });
      return;
    }

    print(
        "Calling getHomeStories with access token: ${accessToken.substring(0, math.min(10, accessToken.length))}...");

    try {
      // Replace with direct URL call to see if issue is with service
      final response = await http.get(
        Uri.parse('http://192.168.89.61:8080/v1/api/student/home/stories'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      print("API Raw Response: ${response.statusCode}");
      print("API Raw Body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final storyData = jsonResponse['data'] as List<dynamic>;
          print("Stories data loaded, count: ${storyData.length}");

          final List<HomeStoryDTO> parsedStories = [];

          for (int i = 0; i < storyData.length; i++) {
            final story = storyData[i];
            print(
                "Story $i - User: ${story['username']}, Photos: ${story['photos']?.length}, StoryIds: ${story['storyId']?.length}");

            try {
              // Convert the dynamic data to HomeStoryDTO - safely handle null values
              bool isVisited = false;

              // Safely parse visited value which could be null
              if (story['visited'] != null) {
                isVisited = story['visited'] as bool;
              }

              parsedStories.add(HomeStoryDTO(
                storyId: List<String>.from(story['storyId'] ?? []),
                studentId: story['studentId'] ?? 0,
                username: story['username'] ?? '',
                photos: List<String>.from(story['photos'] ?? []),
                profilePhoto: story['profilePhoto'] ?? '',
                isVisited: isVisited,
              ));

              print("Successfully parsed story for user: ${story['username']}");
            } catch (e) {
              print("Error parsing story at index $i: $e");
            }
          }

          print(
              "Successfully parsed ${parsedStories.length} stories out of ${storyData.length}");

          setState(() {
            stories = parsedStories;
            isLoadingStories = false;
          });

          print(
              "setState called, stories updated in UI: ${stories.length} stories");
        } else {
          print("API error or empty data: ${jsonResponse['message']}");
          setState(() {
            isLoadingStories = false;
            stories = []; // Boş liste ata
          });
        }
      } else {
        print("API error status code: ${response.statusCode}");
        setState(() {
          isLoadingStories = false;
          stories = []; // Hata durumunda boş liste ata
        });
      }
    } catch (e) {
      print("Exception loading stories: $e");
      setState(() {
        isLoadingStories = false;
        stories = []; // Hata durumunda boş liste ata
      });
    }

    print("=== LOADING STORIES - END ===");
  }

  Future<void> _loadPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    try {
      print('Gönderiler için API isteği yapılıyor...');
      final response =
          await _studentService.fetchHomePosts(accessToken, _currentPage);

      if (response.isSuccess && response.data != null) {
        print(
            'API yanıtı başarılı, gelen gönderi sayısı: ${response.data!.length}');

        setState(() {
          posts = response.data!;
          hasMorePosts =
              response.data!.length >= 10; // Sayfa başına 10 gönderi varsayımı
          _currentPage++;
          isLoadingPosts = false;

          // Gelen verilerin kontrolü
          if (posts.isEmpty) {
            print('Hiç gönderi bulunamadı!');
          } else {
            print(
                'Gönderiler başarıyla yüklendi, toplam ${posts.length} gönderi var');

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
    setState(() {
      _isSuggestedUsersLoading = true;
      _suggestedError = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    try {
      // Direct API call to suggested connections endpoint
      final response = await http.get(
        Uri.parse(
            'http://192.168.89.61:8080/v1/api/student/suggested-connections'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      print("Suggested Connections API Response: ${response.statusCode}");

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print(
            "Suggested Connections API Body: ${response.body.substring(0, math.min(100, response.body.length))}...");

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final suggestionData = jsonResponse['data'] as List<dynamic>;

          if (suggestionData.isNotEmpty) {
            try {
              // Extract usernames for debug
              _suggestedUsernames = suggestionData
                  .where((item) => item['username'] != null)
                  .map((item) => item['username'] as String)
                  .toList();

              print(
                  "Suggested users loaded: ${_suggestedUsernames.join(', ')}");

              setState(() {
                suggestedUsers = suggestionData;
                _isSuggestedUsersLoading = false;
              });
            } catch (e) {
              print("Error processing suggested users: $e");
              setState(() {
                _isSuggestedUsersLoading = false;
                suggestedUsers = [];
              });
            }
          } else {
            print("No suggested users found");
            setState(() {
              _isSuggestedUsersLoading = false;
              suggestedUsers = [];
            });
          }
        } else {
          print("Suggested users API error: ${jsonResponse['message']}");
          setState(() {
            _isSuggestedUsersLoading = false;
            suggestedUsers = [];
            _suggestedError =
                jsonResponse['message'] ?? 'Önerilen kullanıcılar yüklenemedi';
          });
        }
      } else {
        print("Suggested users API error status: ${response.statusCode}");
        setState(() {
          _isSuggestedUsersLoading = false;
          suggestedUsers = [];
          _suggestedError = 'API yanıt kodu: ${response.statusCode}';
        });
      }
    } catch (e) {
      print("Exception in _fetchSuggestedUsers: $e");
      setState(() {
        _isSuggestedUsersLoading = false;
        suggestedUsers = [];
        _suggestedError = 'Bir hata oluştu: $e';
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (isLoadingMorePosts) return;

    setState(() {
      isLoadingMorePosts = true;
    });

    _currentPage++;
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    try {
      final response =
          await _studentService.fetchHomePosts(accessToken, _currentPage);

      if (response.isSuccess && response.data != null) {
        setState(() {
          posts.addAll(response.data!);
          hasMorePosts =
              response.data!.length >= 10; // Sayfa başına 10 gönderi varsayımı
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
    final accessToken = prefs.getString('accessToken');

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
    final accessToken = prefs.getString('accessToken');

    try {
      final response = await _studentService.fetchProfile(accessToken);
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

  void _showDevelopmentMessage(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: AppColors.buttonText,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: color ?? AppColors.cardBackground,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
              color: color?.withOpacity(0.5) ??
                  AppColors.primaryText.withOpacity(0.2),
              width: 1),
        ),
        duration: Duration(seconds: 2),
        margin: EdgeInsets.fromLTRB(
            16, 0, 16, 80), // Bottom margin for better visibility
        action: SnackBarAction(
          label: 'TAMAM',
          textColor: color ?? AppColors.accent,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Tema değiştirme methodu (Updated to use ThemeProvider)
  Future<void> _toggleTheme() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.toggleTheme();

    // Show theme change message
    _showDevelopmentMessage(
        themeProvider.isDarkMode
            ? 'Karanlık mod etkinleştirildi'
            : 'Aydınlık mod etkinleştirildi',
        color: themeProvider.isDarkMode
            ? AppColors.accent
            : AppColors.lightAccent);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Theme-aware color palette
    final Color primaryColor =
        isDarkMode ? AppColors.background : AppColors.lightBackground;
    final Color accentColor =
        isDarkMode ? AppColors.accent : AppColors.lightAccent;
    final Color secondaryAccentColor =
        isDarkMode ? AppColors.success : AppColors.lightSuccess;
    final Color cardColor =
        isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;
    final Color textColor =
        isDarkMode ? AppColors.primaryText : AppColors.lightPrimaryText;
    final Color textMutedColor =
        isDarkMode ? AppColors.secondaryText : AppColors.lightSecondaryText;
    final Color dividerColor = isDarkMode
        ? AppColors.secondaryText.withOpacity(0.24)
        : AppColors.lightSecondaryText.withOpacity(0.24);
    final Color shimmerBaseColor =
        isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;
    final Color shimmerHighlightColor = isDarkMode
        ? Color(0xFF3A3A3A)
        : AppColors.lightSecondaryText.withOpacity(0.3);
    final Color chatbotGradientStart =
        isDarkMode ? AppColors.accent : AppColors.lightAccent;
    final Color chatbotGradientEnd =
        isDarkMode ? Color(0xFF9C27B0) : Color(0xFF673AB7);
    final Color chatbotButtonColor =
        isDarkMode ? AppColors.accent : AppColors.lightAccent;

    // Sistemin UI kontrollerini ayarla
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          isDarkMode ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: primaryColor,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background efekti - geliştirilmiş
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.accent.withOpacity(0.15),
                    primaryColor,
                  ],
                  stops: const [0.0, 0.3],
                ),
              ),
              child: Stack(
                children: [
                  // Dekoratif arka plan elementleri
                  Positioned(
                    top: -screenSize.width * 0.2,
                    right: -screenSize.width * 0.2,
                    child: Container(
                      width: screenSize.width * 0.5,
                      height: screenSize.width * 0.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor.withOpacity(0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    top: screenSize.height * 0.3,
                    left: -screenSize.width * 0.1,
                    child: Container(
                      width: screenSize.width * 0.3,
                      height: screenSize.width * 0.3,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: secondaryAccentColor.withOpacity(0.05),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Ana içerik
          PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            children: [
              // Mesajlar sayfası (sağa kaydırınca buraya gelir - index 0)
              MessagesScreen(),

              // Ana sayfa içeriği (varsayılan görünüm - index 1)
              RefreshIndicator(
                onRefresh: _loadData,
                color: accentColor,
                backgroundColor: cardColor,
                strokeWidth: 2.5,
                displacement: 140, // Header'a yer açmak için arttırıldı
                edgeOffset: 80, // Header'ın altından başlaması için
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    // Üst boşluk (Header'ın altında)
                    SliverToBoxAdapter(
                      child: SizedBox(height: safeArea.top + 80),
                    ),

                    // Hikayeler
                    SliverToBoxAdapter(
                      child: _buildStoriesSection()
                          .animate()
                          .fadeIn(duration: 500.ms, curve: Curves.easeOutQuint)
                          .slideY(
                              begin: 0.2,
                              end: 0,
                              duration: 600.ms,
                              curve: Curves.easeOutCubic),
                    ),

                    // Önerilen Kişiler - Yeni Bölüm
                    if (suggestedUsers.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _buildSuggestedConnectionsSection()
                            .animate()
                            .fadeIn(
                                duration: 500.ms,
                                delay: 200.ms,
                                curve: Curves.easeOutQuint),
                      ),

                    // Chatbot önerisi - geliştirilmiş tasarım
                    SliverToBoxAdapter(
                      child: _buildChatbotSuggestion().animate().fadeIn(
                          duration: 600.ms,
                          delay: 300.ms,
                          curve: Curves.easeOutQuint),
                    ),

                    // Ayırıcı
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: screenSize.width * 0.04,
                            vertical: screenSize.height * 0.015),
                        child: Divider(
                          color: dividerColor,
                          height: 1,
                          thickness: 0.5,
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                    ),

                    // Gönderiler
                    isLoadingPosts && !isRefreshing
                        ? _buildPostsLoadingShimmer()
                        : _buildPostsSection(),

                    // Yükleniyor indikatörü
                    if (isLoadingMorePosts)
                      SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(screenSize.width * 0.06),
                            child: CircularProgressIndicator(
                              color: accentColor,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),

                    // Alt boşluk
                    SliverToBoxAdapter(
                      child: SizedBox(height: screenSize.height * 0.1),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Header (appbar yerine) - Geliştirilmiş header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LayoutBuilder(builder: (context, constraints) {
              return Hero(
                tag: 'app_header',
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    width: constraints.maxWidth,
                    child: Header(
                      key: _headerKey,
                      title: 'BinGoo',
                      notificationCount: notificationCount,
                      messageCount: messageCount,
                      scrollController: _scrollController,
                      onTitleTap: () {
                        // Başa dön (smooth scroll)
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            0,
                            duration: Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                          );
                        }

                        // Konfeti efekti veya başka bir görsel geri bildirim ekleyebilirsiniz
                        _showDevelopmentMessage('Ana sayfaya hoş geldiniz!',
                            color: Colors.blue.shade700);
                      },
                    ),
                  ),
                ),
              );
            }),
          ),

          // Chatbot floating butonu - geliştirilmiş tasarım
          if (_isChatbotVisible)
            Positioned(
              bottom: screenSize.height * 0.1,
              right: screenSize.width * 0.04,
              child: _buildChatbotButton(),
            ),

          // İsteğe bağlı - Header üzerindeki ekstra efekt
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 2,
            child: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      chatbotGradientStart.withOpacity(0.0),
                      chatbotGradientStart.withOpacity(0.7),
                      chatbotGradientEnd.withOpacity(0.7),
                      AppColors.error.withOpacity(0.7),
                      AppColors.warning.withOpacity(0.0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: chatbotGradientStart.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 0.2,
                    )
                  ]),
            ),
          ),
        ],
      ),

      // Bottom Navigation
      bottomNavigationBar: Sidebar(
          profilePhotoUrl: profileData?.profilePhoto ??
              'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg'),
    );
  }

  Widget _buildStoriesSection() {
    final screenSize = MediaQuery.of(context).size;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final Color textColor =
        isDarkMode ? AppColors.primaryText : AppColors.lightPrimaryText;

    print('Building stories section with ${stories.length} stories');
    if (stories.isNotEmpty) {
      for (var story in stories) {
        print(
            'Story from user: ${story.username}, photos: ${story.photos.length}');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
              screenSize.width * 0.04,
              screenSize.height * 0.01,
              screenSize.width * 0.04,
              screenSize.height * 0.015),
          child: Row(
            children: [
              Text(
                'Hikayeler',
                style: TextStyle(
                  color: textColor,
                  fontSize: screenSize.width * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              if (stories.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    // Tüm hikayeleri göster
                    if (stories.isNotEmpty) {
                      _navigateToStoryViewer(stories[0], userStories: false);
                    }
                  },
                  child: Row(
                    children: [
                      Text(
                        'Tümünü Gör',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: screenSize.width * 0.035,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios,
                          size: 12, color: Colors.blue),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Container(
          height:
              105, // Sabit yükseklik - (Circle boyutu + text yüksekliği + padding)
          margin: EdgeInsets.only(bottom: 4), // Alt kısma ekstra boşluk
          child: isLoadingStories && !isRefreshing
              ? _buildStoriesLoadingShimmer()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    physics: BouncingScrollPhysics(), // Daha yumuşak kaydırma
                    itemCount: _buildStoryItemCount(),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildAddStoryItem();
                      }

                      // Kullanıcının kendi hikayeleri
                      if (userStories.isNotEmpty &&
                          index <= userStories.length) {
                        return _buildEnhancedStoryItem(userStories[index - 1],
                            isUserStory: true);
                      }

                      // Diğer kullanıcıların hikayeleri
                      final int storyIndex = index -
                          1 -
                          (userStories.isEmpty ? 0 : userStories.length);
                      if (stories.isNotEmpty && storyIndex < stories.length) {
                        return _buildEnhancedStoryItem(stories[storyIndex],
                            isUserStory: false);
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
    // Sabit boyutlar ekleyerek taşmaları önlüyoruz
    final double circleSize = 60;
    final double textHeight = 10;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final Color shimmerBaseColor =
        isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;
    final Color shimmerHighlightColor = isDarkMode
        ? Color(0xFF3A3A3A)
        : AppColors.lightSecondaryText.withOpacity(0.3);

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 8),
      physics: NeverScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: shimmerBaseColor,
          highlightColor: shimmerHighlightColor,
          child: Container(
            width: circleSize + 8,
            margin: EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: shimmerBaseColor,
                    border: Border.all(
                      color: AppColors.secondaryText.withOpacity(0.24),
                      width: 1,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  width: circleSize - 10,
                  height: textHeight,
                  decoration: BoxDecoration(
                    color: shimmerBaseColor,
                    borderRadius: BorderRadius.circular(4),
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
    final screenSize = MediaQuery.of(context).size;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final Color textColor =
        isDarkMode ? AppColors.primaryText : AppColors.lightPrimaryText;

    // Bu fonksiyon StoryItem widget'ını çağırabilir veya tamamen özelleştirilmiş bir hikaye öğesi oluşturabilir
    String name = '';
    String profilePhoto = '';
    String storyContent = '';
    bool isViewed = false;
    HomeStoryDTO? storyDTO;
    List<String> storyPhotos = [];

    // Tür kontrolü ve veri çıkarma
    if (story is HomeStoryDTO) {
      name = story.username;
      profilePhoto = story.profilePhoto;
      storyPhotos = story.photos;
      storyContent = story.photos.isNotEmpty ? story.photos.first : '';
      isViewed = story.isVisited;
      storyDTO = story;
    } else {
      // Diğer türdeki hikaye nesnelerini işleyin (örneğin userStories)
      try {
        name = story['username'] ?? 'Kullanıcı';
        profilePhoto = story['profilePhoto'] ?? '';

        if (story['photos'] != null) {
          if (story['photos'] is List) {
            storyPhotos = List<String>.from(story['photos']);
            storyContent = storyPhotos.isNotEmpty ? storyPhotos.first : '';
          }
        }

        isViewed =
            story['visited'] ?? false; // Changed from 'isVisited' to 'visited'
      } catch (e) {
        print("ERROR parsing story data: $e");
      }
    }

    // Only return a valid story item if we have photos
    if (name.isEmpty) {
      return Container(); // Boş container döndür
    }

    // Hikaye içeriği var mı?
    final bool hasValidStory = storyPhotos.isNotEmpty;

    // Daha küçük boyutlar kullanarak overflow hatalarını önle
    final double circleSize = screenSize.width * 0.16; // 0.18'den küçülttük
    final double iconSize = circleSize * 0.38; // İkon boyutunu ayarla
    final double badgeSize = circleSize * 0.3; // Rozet boyutunu ayarla

    return GestureDetector(
      onTap: () {
        if (hasValidStory) {
          // Eğer geçerli hikaye içeriği varsa, hikaye görüntüleyiciyi aç
          if (storyDTO != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StoryViewerScreen(
                  story: storyDTO!,
                  allStories: stories,
                  initialIndex: stories.indexOf(storyDTO!),
                ),
              ),
            );
          }
        } else {
          // Eğer hikaye içeriği yoksa, hata sayfasını göster
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoStoryScreen(
                message: isUserStory
                    ? 'Henüz Hikayen Yok'
                    : '$name Kullanıcısının Hikayesi Yok',
                subMessage: isUserStory
                    ? 'Yeni bir hikaye eklemek için "+" butonuna dokunabilirsin.'
                    : 'Bu kullanıcı henüz bir hikaye paylaşmamış veya hikayesi yüklenemedi.',
                isError: false,
                onRetry: () => _loadData(),
                onReturn: () => Navigator.pop(context),
              ),
            ),
          );
        }
      },
      child: Container(
        width: circleSize +
            8, // Sabit genişlik vererek taşma sorununun önüne geçiyoruz
        margin:
            EdgeInsets.symmetric(horizontal: 4), // Kenar boşluklarını azalttık
        child: Column(
          mainAxisSize: MainAxisSize.min, // Yükseklik taşmalarını önlemek için
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasValidStory
                        ? LinearGradient(
                            colors: isViewed
                                ? [
                                    AppColors.secondaryText.withOpacity(0.8),
                                    AppColors.secondaryText
                                  ]
                                : [
                                    AppColors.accent.withOpacity(0.8),
                                    AppColors.link,
                                    AppColors.warning
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    border: hasValidStory
                        ? null
                        : Border.all(color: AppColors.secondaryText, width: 2),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(2), // Padding'i sabit değer yaptık
                    child: CircleAvatar(
                      backgroundColor: AppColors.background,
                      backgroundImage: profilePhoto.isNotEmpty
                          ? CachedNetworkImageProvider(profilePhoto)
                          : null,
                      child: profilePhoto.isEmpty
                          ? Icon(LineIcons.user,
                              color: AppColors.primaryText, size: iconSize)
                          : null,
                    ),
                  ),
                ),
                if (!hasValidStory)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: badgeSize,
                      height: badgeSize,
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.background, width: 1),
                      ),
                      child: Center(
                        child: Icon(
                          isUserStory
                              ? LineIcons.plus
                              : LineIcons.exclamationCircle,
                          color: AppColors.primaryText,
                          size: badgeSize * 0.6,
                        ),
                      ),
                    ),
                  )
              ],
            ),
            SizedBox(height: 4), // Sabit yükseklik kullanarak taşmaları önledik
            SizedBox(
              width: circleSize,
              child: Text(
                name,
                style: TextStyle(
                  color: textColor,
                  fontSize: 11, // Sabit font boyutu
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddStoryItem() {
    final screenSize = MediaQuery.of(context).size;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final Color accentColor =
        isDarkMode ? AppColors.accent : AppColors.lightAccent;
    final Color primaryColor =
        isDarkMode ? AppColors.background : AppColors.lightBackground;
    final Color textColor =
        isDarkMode ? AppColors.primaryText : AppColors.lightPrimaryText;

    // Boyutları diğer hikaye öğeleriyle uyumlu hale getiriyoruz
    final double circleSize = screenSize.width * 0.16;
    final double iconSize = circleSize * 0.33;

    return GestureDetector(
      onTap: () async {
        final refreshNeeded = await Navigator.push(
            context, MaterialPageRoute(builder: (context) => AddStoryScreen()));

        if (refreshNeeded == true) {
          _loadData();
        }
      },
      child: Container(
        width: circleSize + 8, // Sabit genişlik belirledik
        margin:
            EdgeInsets.symmetric(horizontal: 4), // Kenar boşluklarını azalttık
        child: Column(
          mainAxisSize: MainAxisSize.min, // Yükseklik taşmalarını önledik
          children: [
            Container(
              width: circleSize,
              height: circleSize,
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
                      width: circleSize * 0.5, // İç dairenin boyutunu ayarladık
                      height: circleSize * 0.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor,
                      ),
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: iconSize,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 4), // Sabit yükseklik
            SizedBox(
              width: circleSize,
              child: Text(
                'Hikaye Ekle',
                style: TextStyle(
                  color: textColor,
                  fontSize: 11, // Sabit font boyutu (diğer öğelerle aynı)
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

  Widget _buildPostsLoadingShimmer() {
    final screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 350;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final Color shimmerBaseColor =
        isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;
    final Color shimmerHighlightColor = isDarkMode
        ? Color(0xFF3A3A3A)
        : AppColors.lightSecondaryText.withOpacity(0.3);

    // Ekran boyutuna bağlı olarak güvenli değerler kullan
    final double profileSize = isSmallScreen ? 32 : 40;
    final double cardHeight =
        math.min(screenSize.height * 0.45, 400.0); // Max değer belirle

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Shimmer.fromColors(
              baseColor: shimmerBaseColor,
              highlightColor: shimmerHighlightColor,
              child: Container(
                height: cardHeight,
                decoration: BoxDecoration(
                  color: shimmerBaseColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kullanıcı bilgisi - sabit padding ve boyutlar
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: profileSize,
                            height: profileSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.secondaryText.withOpacity(0.24),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 120,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(7),
                                    color: AppColors.secondaryText
                                        .withOpacity(0.24),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  width: 80,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    color: AppColors.secondaryText
                                        .withOpacity(0.24),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // İçerik - Flexible ile taşmaları önle
                    Flexible(
                      fit: FlexFit.tight,
                      child: Container(
                        color: AppColors.secondaryText.withOpacity(0.24),
                      ),
                    ),

                    // Alt bilgiler - sabit değerler
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 100,
                                height: 16,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color:
                                      AppColors.secondaryText.withOpacity(0.24),
                                ),
                              ),
                              Spacer(),
                              Container(
                                width: 60,
                                height: 16,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color:
                                      AppColors.secondaryText.withOpacity(0.24),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            height: 12,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: AppColors.secondaryText.withOpacity(0.24),
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            width: screenSize.width * 0.7,
                            height: 12,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: AppColors.secondaryText.withOpacity(0.24),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        childCount: 3,
      ),
    );
  }

  Widget _buildPostsSection() {
    final screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 350;

    if (posts.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.secondaryText,
                  size: isSmallScreen ? 48 : 56,
                ),
                SizedBox(height: 16),
                Text(
                  'Henüz gönderi yok',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 300),
                  child: Text(
                    'Takip ettikleriniz bir şeyler paylaştığında burada görünecek',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
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

            // Check if post has video content
            bool hasVideoContent = false;
            if (post.content.isNotEmpty) {
              hasVideoContent =
                  post.content.any((url) => VideoHelper.isVideoFile(url));
            }

            // PostItem'a gönderilecek verileri kontrol et
            print('PostItem için hazırlanan veri: ${postData.keys.join(", ")}');
            if (postData['content'] is List) {
              print(
                  'Content listesi uzunluğu: ${(postData['content'] as List).length}');
            } else {
              print(
                  'Content listesi değil! Tipi: ${postData['content'].runtimeType}');
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
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Ekran genişliğine göre sınırlar belirleyelim
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth,
                          // İçeriği sınırla ama min yüksekliği belirle
                          minHeight: 100,
                        ),
                        child: VisibilityDetector(
                          key: Key('post-${post.postId}'),
                          onVisibilityChanged: (visibilityInfo) {
                            // Post görünürlüğü %70'den fazlaysa video otomatik başlasın
                            // Bu mantık PostItem içinde de uygulanıyor, bu bir ekstra kontrol
                            final double visiblePercentage =
                                visibilityInfo.visibleFraction * 100;
                            print(
                                'Post ${post.postId} görünürlüğü: $visiblePercentage%');
                          },
                          child: PostItem(
                            post: postData,
                            skipInvalidContent: false,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          } catch (e) {
            print('Gönderi #$index oluşturulurken hata: $e');
            return Container(
              margin: EdgeInsets.all(screenSize.width * 0.04),
              padding: EdgeInsets.all(screenSize.width * 0.04),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(screenSize.width * 0.03),
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
                      fontSize: screenSize.width * 0.04,
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.01),
                  Text(
                    e.toString(),
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: screenSize.width * 0.035,
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

  // Yeni eklenen metod: Hikaye görüntüleyiciye geçiş
  void _navigateToStoryViewer(dynamic story, {required bool userStories}) {
    print("=== NAVIGATE TO STORY VIEWER - START ===");
    print("Story type: ${story.runtimeType}, isUserStories: $userStories");

    // Eğer story bir HomeStoryDTO değilse, o formata çevir
    HomeStoryDTO storyDTO;
    try {
      if (story is HomeStoryDTO) {
        storyDTO = story;
        print(
            "Using HomeStoryDTO - Username: ${storyDTO.username}, Photos: ${storyDTO.photos.length}");
      } else {
        // Try to safely extract fields
        List<String> storyIds = [];
        if (story['storyId'] != null) {
          if (story['storyId'] is List) {
            storyIds = List<String>.from(story['storyId']);
          } else {
            print(
                "WARNING: storyId is not a list, it's a ${story['storyId'].runtimeType}");
            // Create a single element list if it's a string
            if (story['storyId'] is String) {
              storyIds = [story['storyId']];
            }
          }
        }

        List<String> photos = [];
        if (story['photos'] != null) {
          if (story['photos'] is List) {
            photos = List<String>.from(story['photos']);
            print("Photos extracted successfully, count: ${photos.length}");
            if (photos.isNotEmpty) {
              print("First photo URL: ${photos.first}");
            }
          } else {
            print(
                "WARNING: photos is not a list, it's a ${story['photos'].runtimeType}");
          }
        } else {
          print("WARNING: No photos field in story data");
        }

        storyDTO = HomeStoryDTO(
          storyId: storyIds,
          studentId: story['studentId'] ?? 0,
          username: story['username'] ?? 'Kullanıcı',
          photos: photos,
          profilePhoto: story['profilePhoto'] ?? '',
          isVisited: story['visited'] ?? false,
        );
        print(
            "Converted to HomeStoryDTO - Username: ${storyDTO.username}, Photos: ${storyDTO.photos.length}");
      }
    } catch (e) {
      print("ERROR converting story to HomeStoryDTO: $e");
      // Show error message and return
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Hikaye verisi dönüştürülürken hata oluştu: $e')));
      return;
    }

    // Hikaye listesini oluştur
    List<HomeStoryDTO> allStories = [];

    try {
      if (userStories) {
        // Kullanıcının kendi hikayeleri
        print("Processing user stories, count: ${this.userStories.length}");
        for (var userStory in this.userStories) {
          if (userStory is! HomeStoryDTO) {
            try {
              // Get photos safely
              List<String> photos = [];
              if (userStory['photos'] != null) {
                if (userStory['photos'] is List) {
                  photos = List<String>.from(userStory['photos']);
                }
              }

              // Get storyIds safely
              List<String> storyIds = [];
              if (userStory['storyId'] != null) {
                if (userStory['storyId'] is List) {
                  storyIds = List<String>.from(userStory['storyId']);
                } else if (userStory['storyId'] is String) {
                  storyIds = [userStory['storyId']];
                }
              }

              allStories.add(HomeStoryDTO(
                storyId: storyIds,
                studentId: userStory['studentId'] ?? 0,
                username: userStory['username'] ?? 'Kullanıcı',
                photos: photos,
                profilePhoto: userStory['profilePhoto'] ?? '',
                isVisited: userStory['visited'] ?? false,
              ));
              print(
                  "Added user story for ${userStory['username']}, photos: ${photos.length}");
            } catch (e) {
              print("ERROR converting user story: $e");
            }
          } else {
            allStories.add(userStory);
            print(
                "Added user story for ${userStory.username}, photos: ${userStory.photos.length}");
          }
        }
      } else {
        // Diğer kullanıcıların hikayeleri
        print("Using all friend stories, count: ${this.stories.length}");
        allStories.addAll(this.stories);

        // Debug stories data
        for (int i = 0; i < allStories.length; i++) {
          final story = allStories[i];
          print(
              "Story $i - User: ${story.username}, Photos: ${story.photos.length}");
        }
      }
    } catch (e) {
      print("ERROR creating stories list: $e");
    }

    // Eğer hikaye listesi boşsa, seçili hikayeyi ekle
    if (allStories.isEmpty) {
      print("No stories in list, adding the selected story");
      allStories.add(storyDTO);
    }

    // Hikaye indeksini bul
    int initialIndex = 0;
    try {
      for (int i = 0; i < allStories.length; i++) {
        if (allStories[i].studentId == storyDTO.studentId) {
          initialIndex = i;
          print("Found matching story at index $i");
          break;
        }
      }
    } catch (e) {
      print("ERROR finding initial index: $e");
    }

    print(
        "Navigating to story viewer - Initial index: $initialIndex, Total stories: ${allStories.length}");

    // Check if stories have photos
    bool hasValidPhotos = false;
    for (var story in allStories) {
      if (story.photos.isNotEmpty) {
        hasValidPhotos = true;
        break;
      }
    }

    if (!hasValidPhotos) {
      print("WARNING: No stories with photos found");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gösterilecek hikaye bulunamadı')));
      return;
    }

    // StoryViewerScreen'e git
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewerScreen(
          story: storyDTO,
          allStories: allStories,
          initialIndex: initialIndex,
        ),
      ),
    ).then((_) {
      // Hikaye görüntülendikten sonra yenile
      _loadStories();
    });

    print("=== NAVIGATE TO STORY VIEWER - END ===");
  }

  // Load stories directly without waiting for _loadData
  Future<void> _loadStoriesDirect() async {
    print("=== LOADING STORIES - START ===");
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null || accessToken.isEmpty) {
      print("ERROR: Access token is null or empty");
      setState(() {
        isLoadingStories = false;
      });
      return;
    }

    print(
        "Calling getHomeStories with access token: ${accessToken.substring(0, math.min(10, accessToken.length))}...");

    try {
      final response = await _studentService.getHomeStories(accessToken, 0);

      print(
          "API Response received - Success: ${response.isSuccess}, Message: ${response.message}");

      if (response.isSuccess &&
          response.data != null &&
          response.data!.isNotEmpty) {
        final storyData = response.data!;
        print("Stories data loaded, count: ${storyData.length}");

        for (int i = 0; i < storyData.length; i++) {
          final story = storyData[i];
          print(
              "Story $i - User: ${story.username}, Photos: ${story.photos.length}, StoryIds: ${story.storyId.length}");
        }

        setState(() {
          stories = storyData;
          isLoadingStories = false;
        });

        print("setState called, stories updated in UI");
      } else {
        print("API error or empty data: ${response.message}");
        setState(() {
          isLoadingStories = false;
          stories = []; // Boş liste ata
        });
      }
    } catch (e) {
      print("Exception loading stories: $e");
      setState(() {
        isLoadingStories = false;
        stories = []; // Hata durumunda boş liste ata
      });
    }

    print("=== LOADING STORIES - END ===");
  }

  // Debug function for stories
  void _debugPrintStoriesInfo() {
    // Wait a bit for the stories to load
    Future.delayed(Duration(seconds: 5), () {
      print("========== DEBUG STORIES INFO ==========");
      print("Total stories: ${stories.length}");
      print("Is loading stories: $isLoadingStories");
      print("Is refreshing: $isRefreshing");

      if (stories.isEmpty) {
        print("No stories available. Check if the API call was successful.");

        // Check userStories as well
        print("User stories: ${userStories.length}");
        if (userStories.isNotEmpty) {
          print("User has stories, but no friend stories.");
        }
      } else {
        print("Stories available:");
        for (int i = 0; i < stories.length; i++) {
          final story = stories[i];
          print(
              "Story $i - User: ${story.username}, Photos: ${story.photos.length}, Visited: ${story.isVisited}");
        }
      }
      print("========================================");
    });
  }

  // Chatbot butonu - geliştirilmiş tasarım
  Widget _buildChatbotButton() {
    // Kullanıcı ekranına bağlı olarak güvenli bir boyut hesapla
    final screenSize = MediaQuery.of(context).size;
    final buttonSize = math.min(screenSize.width * 0.15,
        60.0); // Maximum değer ekleyerek taşma riskini azalttık
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final Color chatbotButtonColor =
        isDarkMode ? AppColors.accent : AppColors.lightAccent;

    return AnimatedScale(
      scale: _isChatbotExpanded ? 1.1 : 1.0,
      duration: Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: chatbotButtonColor.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: FloatingActionButton(
            key: _chatbotKey,
            onPressed: () {
              // Chatbot sayfasına git
              _navigateToChatbot();
            },
            backgroundColor: chatbotButtonColor,
            elevation: 4,
            highlightElevation: 8,
            mini: screenSize.width < 350, // Küçük ekranlarda daha küçük buton
            child: FittedBox(
              fit: BoxFit.contain, // İçeriği sınırlar içinde tut
              child: Padding(
                padding: EdgeInsets.all(screenSize.width < 350 ? 8.0 : 12.0),
                child: Icon(
                  Icons.psychology,
                  color: AppColors.buttonText,
                ),
              ),
            ),
          ),
        ),
      )
          .animate(
            onPlay: (controller) => controller.repeat(reverse: true),
          )
          .shimmer(
            duration: 2000.ms,
            color: AppColors.primaryText.withOpacity(0.3),
          ),
    );
  }

  // Chatbot öneri kartı - geliştirilmiş tasarım
  Widget _buildChatbotSuggestion() {
    final screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 350;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final Color chatbotGradientStart =
        isDarkMode ? AppColors.accent : AppColors.lightAccent;
    final Color chatbotGradientEnd =
        isDarkMode ? Color(0xFF9C27B0) : Color(0xFF673AB7);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            chatbotGradientStart,
            chatbotGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: chatbotGradientStart.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToChatbot,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primaryText.withOpacity(0.1),
          highlightColor: AppColors.primaryText.withOpacity(0.05),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Asistan ikonu - sabit boyutlu
                Container(
                  width: isSmallScreen ? 50 : 60,
                  height: isSmallScreen ? 50 : 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.buttonText,
                        AppColors.buttonText.withOpacity(0.8)
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.background.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [chatbotGradientStart, chatbotGradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Icon(
                        Icons.psychology,
                        color: AppColors.buttonText,
                        size: isSmallScreen ? 30 : 36,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                // Orta kısım - Expanded ile
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Overflow'u önlemek için
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'BinGoo Asistan',
                              style: TextStyle(
                                color: AppColors.buttonText,
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 16 : 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.buttonText.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'AI',
                              style: TextStyle(
                                color: AppColors.buttonText,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Kampüs hakkında sorularınızı yanıtlayabilirim!',
                        style: TextStyle(
                          color: AppColors.buttonText.withOpacity(0.9),
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      // Kaydırılabilir buton listesi
                      SizedBox(
                        height: 30,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          physics: BouncingScrollPhysics(),
                          children: [
                            _buildChatbotActionButton(
                                Icons.lightbulb_outline, 'Soru Sor'),
                            SizedBox(width: 8),
                            _buildChatbotActionButton(
                                Icons.photo_camera_outlined, 'Fotoğraf Gönder'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Sağ ok ikonu - sabit boyutlu
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.buttonText.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.buttonText,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Chatbot eylem butonları için yardımcı metod
  Widget _buildChatbotActionButton(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.buttonText.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.buttonText,
            size: 14,
          ),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: AppColors.buttonText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Chatbot ekranı
  void _navigateToChatbot() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatbotScreen(),
      ),
    );
  }

  // Önerilen Bağlantılar Bölümü
  Widget _buildSuggestedConnectionsSection() {
    final screenSize = MediaQuery.of(context).size;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final Color cardColor =
        isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;
    final Color accentColor =
        isDarkMode ? AppColors.accent : AppColors.lightAccent;
    final Color textColor =
        isDarkMode ? AppColors.primaryText : AppColors.lightPrimaryText;

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              screenSize.width * 0.04,
              screenSize.height * 0.02,
              screenSize.width * 0.04,
              screenSize.height * 0.01,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_alt_outlined,
                  color: accentColor,
                  size: screenSize.width * 0.06,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tanıyor Olabileceğin Kişiler',
                    style: TextStyle(
                      color: textColor,
                      fontSize: screenSize.width * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (suggestedUsers.length > 3)
                  TextButton.icon(
                    onPressed: () async {
                      final refreshNeeded = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AllSuggestedUsersScreen(
                            suggestedUsers: suggestedUsers,
                          ),
                        ),
                      );

                      if (refreshNeeded == true) {
                        _fetchSuggestedUsers();
                      }
                    },
                    icon: Icon(Icons.arrow_forward_ios,
                        size: 12, color: AppColors.link),
                    label: Text(
                      'Tümünü Gör',
                      style: TextStyle(
                        color: AppColors.link,
                        fontSize: screenSize.width * 0.035,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            height: screenSize.height * 0.15,
            margin: EdgeInsets.symmetric(vertical: 8),
            child: _isSuggestedUsersLoading
                ? _buildSuggestedUsersLoadingShimmer()
                : suggestedUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search,
                                size: 32, color: AppColors.secondaryText),
                            SizedBox(height: 8),
                            Text(
                              "Önerilen kişi bulunamadı",
                              style: TextStyle(color: AppColors.secondaryText),
                            )
                          ],
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(
                            horizontal: screenSize.width * 0.03),
                        itemCount: suggestedUsers.length,
                        itemBuilder: (context, index) {
                          final user = suggestedUsers[index];
                          return _buildSuggestedUserItem(
                            username: user['username'] ?? 'Kullanıcı',
                            profilePhoto: user['profilePhotoUrl'] ?? '',
                          );
                        },
                      ),
          ),
          SizedBox(height: screenSize.height * 0.01),
        ],
      ),
    );
  }

  Widget _buildSuggestedUsersLoadingShimmer() {
    final screenSize = MediaQuery.of(context).size;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final Color shimmerBaseColor =
        isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;
    final Color shimmerHighlightColor = isDarkMode
        ? Color(0xFF3A3A3A)
        : AppColors.lightSecondaryText.withOpacity(0.3);

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.03),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: shimmerBaseColor,
          highlightColor: shimmerHighlightColor,
          child: Container(
            width: screenSize.width * 0.32,
            margin: EdgeInsets.symmetric(
                horizontal: screenSize.width * 0.02, vertical: 5),
            decoration: BoxDecoration(
              color: shimmerBaseColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.background.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: screenSize.width * 0.06,
                    backgroundColor: shimmerBaseColor,
                  ),
                  SizedBox(height: 6),
                  Container(
                    width: screenSize.width * 0.2,
                    height: 14,
                    decoration: BoxDecoration(
                      color: shimmerBaseColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: screenSize.width * 0.18,
                    height: 24,
                    decoration: BoxDecoration(
                      color: shimmerBaseColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestedUserItem({
    required String username,
    required String profilePhoto,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final Color cardColor =
        isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;
    final Color accentColor =
        isDarkMode ? AppColors.accent : AppColors.lightAccent;

    return Container(
      width: screenSize.width * 0.32,
      margin: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.02,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withOpacity(0.15),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    userProfile.UserProfileScreen(username: username),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(8), // padding biraz küçüldü
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profil Fotoğrafı
                Container(
                  padding: EdgeInsets.all(1), // biraz daha az padding
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.accent, AppColors.link],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: screenSize.width * 0.05, // biraz küçültüldü
                    backgroundColor: AppColors.cardBackground,
                    backgroundImage: profilePhoto.isNotEmpty
                        ? CachedNetworkImageProvider(profilePhoto)
                        : null,
                    child: profilePhoto.isEmpty
                        ? Icon(
                            LineIcons.user,
                            color: AppColors.primaryText,
                            size: screenSize.width * 0.055, // küçültüldü
                          )
                        : null,
                  ),
                ),

                SizedBox(height: 6), // az miktarda boşluk

                Flexible(
                  child: Text(
                    username,
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: screenSize.width * 0.037, // biraz küçültüldü
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                SizedBox(height: 8), // buton üstü boşluk küçültüldü

                SizedBox(
                  width: double.infinity,
                  height: 30, // buton yüksekliği biraz küçültüldü
                  child: ElevatedButton(
                    onPressed: () => _sendFriendRequest(username),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: AppColors.buttonText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      elevation: 1,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Arkadaş Ekle',
                        style: TextStyle(
                          fontSize: 11, // biraz küçültüldü
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Önerilen kullanıcıya arkadaşlık isteği gönderme fonksiyonu
  Future<void> _sendFriendRequest(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null || accessToken.isEmpty) {
        _showDevelopmentMessage('Oturum bilgisi bulunamadı!',
            color: AppColors.error);
        return;
      }

      // Yeni API çağrısı - Arkadaşlık isteği gönder
      final response = await http.post(
        Uri.parse(
            'http://192.168.89.61:8080/v1/api/friendsRequest/send/$username'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          _showDevelopmentMessage(
              '$username kullanıcısına arkadaşlık isteği gönderildi!',
              color: AppColors.success);

          // İstek gönderme işlemi başarılı olduysa önerileri güncelle
          _fetchSuggestedUsers();
        } else {
          _showDevelopmentMessage(
              responseData['message'] ?? 'İstek gönderilemedi',
              color: AppColors.error);
        }
      } else {
        _showDevelopmentMessage('İstek başarısız oldu: ${response.statusCode}',
            color: AppColors.error);
      }
    } catch (e) {
      _showDevelopmentMessage('Bir hata oluştu: $e', color: AppColors.error);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}

// Tüm önerilen kullanıcıları gösteren ekran - HomeScreenState sınıfı dışına taşındı
class AllSuggestedUsersScreen extends StatelessWidget {
  final List<dynamic> suggestedUsers;

  const AllSuggestedUsersScreen({
    Key? key,
    required this.suggestedUsers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Tanıyor Olabileceğin Kişiler'),
        backgroundColor: AppColors.background,
      ),
      body: suggestedUsers.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: AppColors.secondaryText,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Henüz önerilebilecek kullanıcı bulunamadı',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: suggestedUsers.length,
              itemBuilder: (context, index) {
                final user = suggestedUsers[index];
                return _buildUserListItem(
                  context: context,
                  username: user['username'] ?? 'Kullanıcı',
                  profilePhoto: user['profilePhotoUrl'] ?? '',
                );
              },
            ),
    );
  }

  Widget _buildUserListItem({
    required BuildContext context,
    required String username,
    required String profilePhoto,
  }) {
    // Ekran genişliğini al
    final screenSize = MediaQuery.of(context).size;

    return Card(
      margin: EdgeInsets.only(bottom: 10),
      color: AppColors.cardBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  userProfile.UserProfileScreen(username: username),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
          child: Row(
            children: [
              // Profil fotoğrafı
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.cardBackground,
                backgroundImage: profilePhoto.isNotEmpty
                    ? CachedNetworkImageProvider(profilePhoto)
                    : null,
                child: profilePhoto.isEmpty
                    ? Icon(LineIcons.user, color: AppColors.primaryText)
                    : null,
              ),

              // İçerik bölümü (kullanıcı adı)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Önerilen Bağlantı',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Buton - tam dinamik boyutlandırma
              Container(
                constraints: BoxConstraints(maxWidth: screenSize.width * 0.28),
                height: 36,
                child: ElevatedButton(
                  onPressed: () => _followUser(context, username),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.buttonText,
                    padding:
                        EdgeInsets.symmetric(horizontal: 8), // Minimum padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Arkadaş Ekle',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _followUser(BuildContext context, String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null || accessToken.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Oturum bilgisi bulunamadı!'),
              backgroundColor: AppColors.error),
        );
        return;
      }

      // Yeni API çağrısı - Arkadaşlık isteği gönder
      final response = await http.post(
        Uri.parse(
            'http://192.168.89.61:8080/v1/api/friendsRequest/send/$username'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('$username kullanıcısına arkadaşlık isteği gönderildi!'),
              backgroundColor: AppColors.success,
            ),
          );

          // İşlem başarılı olduysa ana sayfaya dön ve yenile
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(responseData['message'] ?? 'İstek gönderilemedi'),
                backgroundColor: AppColors.error),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('İstek başarısız oldu: ${response.statusCode}'),
              backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Bir hata oluştu: $e'),
            backgroundColor: AppColors.error),
      );
    }
  }
}
