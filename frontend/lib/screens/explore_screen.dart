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
import 'package:social_media/services/postService.dart';
import 'package:social_media/services/storyService.dart';
import 'package:social_media/models/story_dto.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:social_media/models/post_dto.dart';
import 'package:social_media/widgets/sidebar.dart';
import 'package:social_media/models/student_dto.dart';
import 'package:social_media/screens/user_profile_screen.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';
import 'package:social_media/widgets/video_player_widget.dart';
import 'package:provider/provider.dart';
import 'package:social_media/theme/theme_provider.dart';
import 'package:social_media/screens/story_viewer_screen.dart';
import 'package:social_media/models/home_story_dto.dart';
import 'package:flutter/services.dart';
import 'package:social_media/screens/post_details_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingUsers = false;
  bool _isLoadingPosts = false;
  bool _isLoadingStories = false;
  List<BestPopularityAccount> _trendingUsers = [];
  List<PostDTO> _trendingPosts = [];
  List<StoryDTO> _trendingStories = [];
  List<SearchAccountDTO> _searchResults = [];
  bool _isSearching = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  StudentDTO? _profileData;

  final StudentService _studentService = StudentService();
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    sendTimeout: const Duration(seconds: 60),
    validateStatus: (status) {
      return status != null && status < 500;
    },
  ));

  late final PostService _postService;
  late final StoryService _storyService;

  int _currentRetryCount = 0;
  final int _maxRetryCount = 3;

  // Debounce için timer
  Timer? _debounce;
  final Duration _debounceDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();

    _postService = PostService(_dio);
    _storyService = StoryService(_dio);

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

    _configureDio();

    print('=== DIAGNOSTIC INFO ===');
    print('Dio configuration:');
    print('Connect timeout: ${_dio.options.connectTimeout}');
    print('Receive timeout: ${_dio.options.receiveTimeout}');
    print('Send timeout: ${_dio.options.sendTimeout}');
    print('========================');

    _loadDataWithFallback();
    _searchController.addListener(_onSearchControllerChanged);
    _animationController.forward();

    _loadUserProfile();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _debounce?.cancel(); // Debounce timer'ı temizle
    super.dispose();
  }

  // Controller listener için kullanılacak parametre almayan fonksiyon
  void _onSearchControllerChanged() {
    final query = _searchController.text.trim();
    _handleSearchQueryChange(query);
  }

  // TextField onChanged olayı için kullanılacak String parametreli fonksiyon
  void _onSearchTextChanged(String value) {
    _handleSearchQueryChange(value.trim());
  }

  // Her iki durumda da çağrılacak ortak fonksiyon
  void _handleSearchQueryChange(String query) {
    // İlk olarak debounce zamanlayıcısını iptal et
    _debounce?.cancel();

    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    } else if (query.length >= 2) {
      // Arama durumunu güncelle
      setState(() {
        _isSearching = true;
      });

      // Yeni bir debounce zamanlayıcısı ayarla
      _debounce = Timer(_debounceDuration, () {
        print('Debounce timeout - executing search for: "$query"');
        _performSearch(query);
      });
    }
  }

  void _configureDio() {
    _dio.interceptors.add(InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) {
      print('Dio error: ${error.type} - ${error.message}');
      print('Error URL: ${error.requestOptions.uri}');
      print('Error status code: ${error.response?.statusCode}');
      print('Error response: ${error.response?.data}');

      if (error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        if (_currentRetryCount < _maxRetryCount) {
          _currentRetryCount++;
          final retryDelay = Duration(
              milliseconds: 2000 * _currentRetryCount * _currentRetryCount);

          print(
              'Retrying request (${_currentRetryCount}/${_maxRetryCount}) after ${retryDelay.inMilliseconds}ms');

          Future.delayed(retryDelay, () {
            print('Executing retry attempt ${_currentRetryCount}');
            final options = error.requestOptions;
            options.receiveTimeout =
                Duration(seconds: 60 + (_currentRetryCount * 15));
            options.connectTimeout =
                Duration(seconds: 60 + (_currentRetryCount * 15));
            options.sendTimeout =
                Duration(seconds: 60 + (_currentRetryCount * 15));

            _dio.fetch(options).then(
              (response) => handler.resolve(response),
              onError: (e) {
                print('Retry attempt ${_currentRetryCount} failed: $e');
                handler.reject(e);
              },
            );
          });
          return;
        } else {
          print(
              'Maximum retry attempts (${_maxRetryCount}) reached. Giving up.');
        }
      }
      return handler.next(error);
    }, onRequest: (options, handler) {
      options.receiveTimeout = const Duration(seconds: 60);
      options.connectTimeout = const Duration(seconds: 60);
      options.sendTimeout = const Duration(seconds: 60);

      print('Sending request to: ${options.uri}');
      print('Request method: ${options.method}');
      print('Request headers: ${options.headers}');
      print('Request data: ${options.data}');

      return handler.next(options);
    }, onResponse: (response, handler) {
      _currentRetryCount = 0;
      print(
          'Response received from: ${response.requestOptions.uri} - Status: ${response.statusCode}');
      print('Response data: ${response.data}');
      return handler.next(response);
    }));
  }

  Future<void> _loadDataWithFallback() async {
    try {
      await _loadAllData();
    } catch (e) {
      print('Error in initial data load: $e');
      await _loadEssentialDataOnly();
    }
  }

  Future<void> _loadEssentialDataOnly() async {
    try {
      await _loadTrendingUsers();
    } catch (e) {
      print('Critical error: Even essential data failed to load: $e');
      setState(() {
        _errorMessage =
            'Uygulama verilerine erişilemiyor. Lütfen internet bağlantınızı kontrol edin ve tekrar deneyin.';
      });
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
    if (mounted) {
      setState(() {
        _isLoadingUsers = true;
        _errorMessage = null;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      _currentRetryCount = 0;

      final response = await _studentService.fetchBestPopularity(accessToken);

      final isSuccess = response.isSuccess ?? false;

      if (mounted) {
        if (isSuccess) {
          setState(() {
            _trendingUsers = response.data ?? [];
            _isLoadingUsers = false;
          });
        } else {
          setState(() {
            _errorMessage =
                'Popüler kullanıcılar yüklenirken hata: ${response.message}';
            _isLoadingUsers = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Kullanıcı verisi yüklenirken hata: $e';
          _isLoadingUsers = false;
          print('Profil verileri yüklenirken hata detayı: $e');
        });
      }
    }
  }

  Future<void> _loadTrendingPosts() async {
    if (mounted) {
      setState(() {
        _isLoadingPosts = true;
        _errorMessage = null;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      _currentRetryCount = 0;

      print('Fetching popular posts...');
      final response = await _postService.getPopularity(accessToken);
      print(
          'Popular posts response received with success: ${response.isSuccess}');

      if (mounted) {
        if (response.isSuccess ?? false) {
          setState(() {
            _trendingPosts = response.data ?? [];
            _isLoadingPosts = false;
          });
        } else {
          setState(() {
            _errorMessage =
                'Popüler gönderiler yüklenirken hata: ${response.message}';
            _isLoadingPosts = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        print('Gönderi verisi yüklenirken hata: $e');
        if (e
            .toString()
            .contains("type 'String' is not a subtype of type 'int'")) {
          setState(() {
            _errorMessage =
                'Veri formatı hatası. Lütfen geliştiriciyle iletişime geçin.';
            _isLoadingPosts = false;
          });
        } else if (e is DioException) {
          String errorMessage;
          switch (e.type) {
            case DioExceptionType.receiveTimeout:
            case DioExceptionType.connectionTimeout:
            case DioExceptionType.sendTimeout:
              errorMessage =
                  'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.';
              break;
            default:
              errorMessage = 'Bağlantı hatası: ${e.message}';
          }
          setState(() {
            _errorMessage = errorMessage;
            _isLoadingPosts = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Popüler gönderiler yüklenirken hata oluştu: $e';
            _isLoadingPosts = false;
          });
        }
      }
    }
  }

  Future<void> _loadTrendingStories() async {
    if (mounted) {
      setState(() {
        _isLoadingStories = true;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      _currentRetryCount = 0;

      print('Fetching popular stories...');
      final response = await _storyService.getPopularStories(accessToken);
      print(
          'Popular stories response received with success: ${response.isSuccess}');

      if (mounted) {
        if (response.isSuccess ?? false) {
          setState(() {
            _trendingStories = response.data ?? [];
            _isLoadingStories = false;
          });
        } else {
          setState(() {
            _isLoadingStories = false;
            _errorMessage =
                'Popüler hikayeler yüklenirken hata: ${response.message}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        print('Hikaye verisi yüklenirken hata: $e');
        if (e
            .toString()
            .contains("type 'String' is not a subtype of type 'int'")) {
          setState(() {
            _errorMessage =
                'Hikaye verisi format hatası. Lütfen geliştiriciyle iletişime geçin.';
            _isLoadingStories = false;
          });
        } else if (e is DioException) {
          String errorMessage;
          switch (e.type) {
            case DioExceptionType.receiveTimeout:
            case DioExceptionType.connectionTimeout:
            case DioExceptionType.sendTimeout:
              errorMessage =
                  'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.';
              break;
            default:
              errorMessage = 'Bağlantı hatası: ${e.message}';
          }
          setState(() {
            _errorMessage = errorMessage;
            _isLoadingStories = false;
          });
        } else {
          setState(() {
            _isLoadingStories = false;
            _errorMessage = 'Hikayeler yüklenirken hata: $e';
          });
        }
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      if (accessToken.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isSearching = false;
          _errorMessage = "Oturum bilgisi bulunamadı";
        });
        return;
      }

      _currentRetryCount = 0;

      // URL'i encode et (boşluklar ve özel karakterler için)
      final encodedQuery = Uri.encodeComponent(query);

      print('Searching for: "$query" (encoded: $encodedQuery)');

      // Direkt API endpointine istek at
      final response = await _dio.get(
        'http://192.168.89.61:8080/v1/api/student/search?query=$encodedQuery&page=0',
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
          validateStatus: (status) => true, // Tüm durum kodlarını kabul et
        ),
      );

      print('Search response: ${response.statusCode}');
      print('Response data structure: ${response.data.runtimeType}');
      print(
          'Response data keys: ${response.data is Map ? (response.data as Map).keys : "Not a Map"}');

      if (!mounted) return;

      if (response.statusCode != 200) {
        setState(() {
          _isSearching = false;
          _errorMessage = 'Sunucu hatası: ${response.statusCode}';
        });
        return;
      }

      final Map<String, dynamic> responseBody = response.data;
      final bool isSuccess = responseBody['success'] ?? false;

      if (isSuccess) {
        final List<dynamic> searchData = responseBody['data'] ?? [];

        print('Raw search data: $searchData');

        // API yanıtını SearchAccountDTO'ya dönüştür
        final List<SearchAccountDTO> searchResults = [];

        for (var userData in searchData) {
          try {
            if (userData is Map<String, dynamic>) {
              // Safe getter functions for different data types
              int safeGetInt(String key, {int defaultValue = 0}) {
                final value = userData[key];
                if (value == null) return defaultValue;
                if (value is int) return value;
                if (value is String) {
                  try {
                    return int.parse(value);
                  } catch (e) {
                    print('Error parsing $key as int: $e');
                    return defaultValue;
                  }
                }
                if (value is num) return value.toInt();
                return defaultValue;
              }

              String safeGetString(String key, {String defaultValue = ''}) {
                final value = userData[key];
                if (value == null) return defaultValue;
                if (value is String) return value;
                return value.toString();
              }

              searchResults.add(SearchAccountDTO(
                id: safeGetInt('id'),
                username: safeGetString('username'),
                fullName: userData['fullName'] as String?,
                profilePhoto: safeGetString('profilePhoto'),
                isPrivate: userData['isPrivate'] as bool?,
                isFollow: userData['isFollow'] as bool?,
              ));
            }
          } catch (e) {
            print('Error creating SearchAccountDTO: $e');
            print('Problematic data: $userData');
          }
        }

        setState(() {
          _searchResults = searchResults;
          _isSearching = false;
        });
        print('Found ${_searchResults.length} results');

        // Kullanıcı nesnelerini debug log'a yazdır
        if (_searchResults.isNotEmpty) {
          print('First user in results: ${_searchResults.first.username}');
          print(
              'Sample user data: id=${_searchResults.first.id}, fullName=${_searchResults.first.fullName}');
        }
      } else {
        setState(() {
          _errorMessage =
              'Arama yapılırken hata: ${responseBody['message'] ?? 'Bilinmeyen hata'}';
          _isSearching = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      print('Arama hatası: $e');
      if (e is DioException) {
        String errorMessage;
        switch (e.type) {
          case DioExceptionType.receiveTimeout:
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
            errorMessage =
                'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.';
            break;
          case DioExceptionType.badResponse:
            errorMessage =
                'Sunucu yanıt vermedi (Hata: ${e.response?.statusCode}).';
            print('Server response error data: ${e.response?.data}');
            break;
          case DioExceptionType.connectionError:
            errorMessage = 'İnternet bağlantınızı kontrol edin.';
            break;
          default:
            errorMessage = 'Bağlantı hatası: ${e.message}';
        }

        setState(() {
          _errorMessage = errorMessage;
          _isSearching = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Bağlantı hatası: $e';
          _isSearching = false;
        });
        print('Arama yapılırken hata detayı: $e');
      }
    }
  }

  Future<void> _retrySearch() async {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      await _performSearch(query);
    }
  }

  bool _isAllContentLoading() {
    return _isLoadingUsers || _isLoadingPosts || _isLoadingStories;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Tema renkleri
    final backgroundColor = themeProvider.currentTheme.scaffoldBackgroundColor;
    final cardColor = themeProvider.currentTheme.cardColor;
    final textColor = themeProvider.currentTheme.textTheme.bodyLarge?.color ??
        (isDarkMode ? Colors.white : Colors.black);
    final textSecondaryColor =
        themeProvider.currentTheme.textTheme.bodyMedium?.color ??
            (isDarkMode ? Colors.white70 : Colors.black87);
    final primaryColor = themeProvider.currentTheme.colorScheme.primary;
    final accentColor = themeProvider.currentTheme.colorScheme.secondary;
    final errorColor = themeProvider.currentTheme.colorScheme.error;
    final dividerColor = themeProvider.currentTheme.dividerColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Row(
          children: [
            Text(
              'Keşfet',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 26,
                fontFamily: 'Roboto',
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(width: 8),
            Icon(LineIcons.compass, color: accentColor, size: 24),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeProvider.currentTheme.colorScheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(LineIcons.bell, color: textColor, size: 20),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 5, 16, 12),
            child: _buildSearchField(),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadDataWithFallback(),
        color: primaryColor,
        backgroundColor: cardColor,
        strokeWidth: 3.0,
        displacement: 40,
        child: _isAllContentLoading()
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: primaryColor,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'İçerikler yükleniyor...',
                      style: TextStyle(
                        color: textSecondaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : _errorMessage != null
                ? _buildErrorWidget()
                : Stack(
                    children: [
                      _buildExploreContent(),
                      if (_isSearching || _searchController.text.isNotEmpty)
                        _buildBlurredSearchResults(),
                    ],
                  ),
      ),
      bottomNavigationBar: Theme(
        data: themeProvider.currentTheme,
        child: Sidebar(
          initialIndex: 1,
          profilePhotoUrl: _profileData?.profilePhoto ?? '',
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final primaryColor = themeProvider.currentTheme.colorScheme.primary;
    final cardColor = themeProvider.currentTheme.cardColor;
    final borderColor = themeProvider.currentTheme.dividerColor;
    final hintColor = themeProvider.currentTheme.hintColor;
    final textColor = themeProvider.currentTheme.textTheme.bodyLarge?.color ??
        (isDarkMode ? Colors.white : Colors.black);

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _searchController.text.isNotEmpty
              ? primaryColor.withOpacity(0.7)
              : borderColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
            color: textColor, fontSize: 15, fontWeight: FontWeight.w400),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: 'Kullanıcı, bölüm veya konu ara...',
          hintStyle: TextStyle(
              color: hintColor, fontSize: 14, fontWeight: FontWeight.w300),
          prefixIcon: Container(
            padding: EdgeInsets.all(12),
            child: _isSearching
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: primaryColor,
                      strokeWidth: 2,
                    ))
                : Icon(CupertinoIcons.search, color: primaryColor, size: 20),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 40,
                    maxHeight: 40,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        _searchController.clear();
                        setState(() {
                          _isSearching = false;
                          _searchResults = [];
                          FocusScope.of(context).unfocus();
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(4),
                        margin: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: borderColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            CupertinoIcons.clear,
                            color: textColor,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          filled: true,
          fillColor: cardColor.withOpacity(0.8),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide:
                BorderSide(color: primaryColor.withOpacity(0.7), width: 1.5),
          ),
        ),
        onSubmitted: (query) {
          // Doğrudan arama yapmak için debounce temizle ve hemen ara
          _debounce?.cancel();
          if (query.trim().isNotEmpty) {
            _performSearch(query);
          }
        },
        onChanged: _onSearchTextChanged,
        textInputAction: TextInputAction.search,
      ),
    );
  }

  Widget _buildErrorWidget() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final cardColor = themeProvider.currentTheme.cardColor;
    final textColor = themeProvider.currentTheme.textTheme.bodyLarge?.color ??
        (themeProvider.isDarkMode ? Colors.white : Colors.black);
    final textSecondaryColor =
        themeProvider.currentTheme.textTheme.bodyMedium?.color ??
            (themeProvider.isDarkMode ? Colors.white70 : Colors.black87);
    final errorColor = themeProvider.currentTheme.colorScheme.error;
    final warningColor = themeProvider.currentTheme.colorScheme.secondary;
    final primaryColor = themeProvider.currentTheme.colorScheme.primary;

    final bool isTimeoutError =
        _errorMessage?.toLowerCase().contains('zaman') == true ||
            _errorMessage?.toLowerCase().contains('timeout') == true ||
            _errorMessage?.toLowerCase().contains('bağlantı') == true;

    return Center(
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          margin: EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isTimeoutError ? Icons.wifi_off : Icons.error_outline,
                  size: 65, color: isTimeoutError ? warningColor : errorColor),
              SizedBox(height: 20),
              Text(
                isTimeoutError ? 'Bağlantı Sorunu' : 'Hata',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor),
              ),
              SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  isTimeoutError
                      ? 'Sunucuya bağlanırken zaman aşımı oluştu. Lütfen internet bağlantınızı kontrol edin ve tekrar deneyin.'
                      : (_errorMessage ?? 'Bilinmeyen bir hata oluştu'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textSecondaryColor,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(height: 25),
              ElevatedButton.icon(
                onPressed: () => isTimeoutError
                    ? _loadDataWithFallback()
                    : _loadDataWithFallback(),
                icon: Icon(Icons.refresh, size: 20),
                label: Text(
                  'Tekrar Dene',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isTimeoutError ? warningColor : primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlurredSearchResults() {
    final bgColor = Provider.of<ThemeProvider>(context).isDarkMode
        ? Colors.black.withOpacity(0.75)
        : Colors.grey.shade800.withOpacity(0.75);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: bgColor,
              child: _buildSearchResults(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final cardColor = themeProvider.currentTheme.cardColor;
    final textColor =
        themeProvider.currentTheme.textTheme.bodyLarge?.color ?? Colors.white;
    final textSecondaryColor =
        themeProvider.currentTheme.textTheme.bodyMedium?.color ??
            Colors.white70;
    final accentColor = themeProvider.currentTheme.colorScheme.secondary;
    final primaryColor = themeProvider.currentTheme.colorScheme.primary;
    final backgroundColor = themeProvider.currentTheme.scaffoldBackgroundColor;
    final dividerColor = themeProvider.currentTheme.dividerColor;

    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              strokeWidth: 3,
            ),
            SizedBox(height: 20),
            Text(
              'Aranıyor...',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LineIcons.searchMinus, size: 70, color: textSecondaryColor),
              SizedBox(height: 20),
              Text(
                'Sonuç bulunamadı',
                style: TextStyle(
                    fontSize: 22,
                    color: textColor,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  '"${_searchController.text}" aramasıyla eşleşen sonuç bulunamadı. Farklı bir arama terimi deneyin.',
                  style: TextStyle(
                      color: textSecondaryColor, fontSize: 15, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _isSearching = false;
                    _searchResults = [];
                    FocusScope.of(context).unfocus();
                  });
                },
                icon: Icon(CupertinoIcons.clear_circled_solid),
                label: Text('Aramayı Temizle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: cardColor.withOpacity(0.95),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
            border: Border(
              bottom: BorderSide(color: dividerColor, width: 1),
            ),
          ),
          child: Row(
            children: [
              Icon(LineIcons.search, color: primaryColor, size: 18),
              SizedBox(width: 12),
              Text(
                '"${_searchController.text}" için ${_searchResults.length} sonuç',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Spacer(),
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _isSearching = false;
                    _searchResults = [];
                    FocusScope.of(context).unfocus();
                  });
                },
                icon: Icon(Icons.close, size: 16, color: primaryColor),
                label: Text('Temizle',
                    style: TextStyle(color: primaryColor, fontSize: 14)),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: primaryColor.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _searchResults.isEmpty
              ? Center(
                  child: Text(
                    'Sonuç bulunamadı',
                    style: TextStyle(color: textSecondaryColor, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return _buildUserListItem(user);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildUserListItem(SearchAccountDTO user) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final cardColor = themeProvider.currentTheme.cardColor;
    final textColor =
        themeProvider.currentTheme.textTheme.bodyLarge?.color ?? Colors.white;
    final textSecondaryColor =
        themeProvider.currentTheme.textTheme.bodyMedium?.color ??
            Colors.white70;
    final primaryColor = themeProvider.currentTheme.colorScheme.primary;
    final accentColor = themeProvider.currentTheme.colorScheme.secondary;
    final dividerColor = themeProvider.currentTheme.dividerColor;

    // Kullanıcı arayüz değerleri için varsayılan değerler
    final bool isPrivate = user.isPrivate ?? false;
    final bool isFollow = user.isFollow ?? false;

    // Profil bilgilerini debug çıktısına yazdır
    print(
        'Rendering user: ${user.username}, profile: ${user.profilePhoto}, id: ${user.id}');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerColor.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            print('Navigating to profile with username: ${user.username}');

            try {
              final prefs = await SharedPreferences.getInstance();
              final accessToken = prefs.getString('accessToken') ?? '';

              if (accessToken.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        'Oturum bilgisi bulunamadı. Lütfen tekrar giriş yapın.')));
                return;
              }

              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfileScreen(
                      username: user.username,
                      userId: user.id,
                    ),
                  ));
            } catch (e) {
              print('Error navigating to profile: $e');
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Kullanıcı profiline erişilemiyor: $e')));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: user.profilePhoto != null &&
                            user.profilePhoto.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: user.profilePhoto,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: cardColor.withOpacity(0.5),
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      primaryColor),
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) {
                              print(
                                  'Error loading image: $error for URL: $url');
                              return Container(
                                color: cardColor.withOpacity(0.5),
                                child: Center(
                                  child: Text(
                                    user.username.isNotEmpty
                                        ? user.username[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: cardColor.withOpacity(0.5),
                            child: Center(
                              child: Text(
                                user.username.isNotEmpty
                                    ? user.username[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.fullName ?? user.username,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isPrivate)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(Icons.lock,
                                  color: textSecondaryColor, size: 14),
                            ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        '@${user.username}',
                        style:
                            TextStyle(color: textSecondaryColor, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 110),
                  child: ElevatedButton(
                    child: Text(
                      isFollow ? 'Takip Ediliyor' : 'Takip Et',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    onPressed: () async {
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        final accessToken =
                            prefs.getString('accessToken') ?? '';

                        if (accessToken.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Oturum bilgisi bulunamadı. Lütfen tekrar giriş yapın.'),
                              backgroundColor:
                                  themeProvider.currentTheme.colorScheme.error,
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _isSearching =
                              true; // İşlem sırasında yükleniyor göster
                        });

                        // Yeni endpoint kullanımı
                        final endpoint = isFollow
                            ? '/follow/unfollow/${user.id}' // Takipten çıkma hala aynı endpoint
                            : '/friendsRequest/send/${user.username}'; // Yeni takip etme endpointi - kullanıcı adı ile

                        print('Sending follow request to: $endpoint');

                        // API isteği
                        final response = await _dio.post(
                          'http://192.168.89.61:8080/v1/api$endpoint',
                          options: Options(headers: {
                            'Authorization': 'Bearer $accessToken'
                          }),
                        );

                        print('Follow response: ${response.statusCode}');
                        print('Response data: ${response.data}');

                        if (response.statusCode == 200 ||
                            response.statusCode == 201) {
                          setState(() {
                            for (var i = 0; i < _searchResults.length; i++) {
                              if (_searchResults[i].id == user.id) {
                                final updatedUser = _searchResults[i];
                                _searchResults[i] = SearchAccountDTO(
                                  id: updatedUser.id,
                                  username: updatedUser.username,
                                  fullName: updatedUser.fullName,
                                  profilePhoto: updatedUser.profilePhoto,
                                  isPrivate: updatedUser.isPrivate,
                                  isFollow: !(updatedUser.isFollow ?? false),
                                );
                                break;
                              }
                            }
                            _isSearching = false;
                          });

                          // Başarılı mesaj göster
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isFollow
                                  ? 'Takipten çıkıldı'
                                  : 'Takip isteği gönderildi'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else {
                          setState(() {
                            _isSearching = false;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'İşlem başarısız: ${response.data['message'] ?? 'Bilinmeyen hata'}'),
                              backgroundColor:
                                  themeProvider.currentTheme.colorScheme.error,
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() {
                          _isSearching = false;
                        });

                        print('Error following/unfollowing: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('İşlem başarısız: ${e.toString()}'),
                            backgroundColor:
                                themeProvider.currentTheme.colorScheme.error,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isFollow ? cardColor.withOpacity(0.7) : primaryColor,
                      foregroundColor: isFollow ? textColor : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isFollow ? dividerColor : Colors.transparent,
                          width: isFollow ? 1 : 0,
                        ),
                      ),
                      elevation: isFollow ? 0 : 3,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
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

  Widget _buildExploreContent() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor =
        themeProvider.currentTheme.textTheme.bodyLarge?.color ?? Colors.white;
    final textSecondaryColor =
        themeProvider.currentTheme.textTheme.bodyMedium?.color ??
            Colors.white70;

    if (_trendingUsers.isEmpty &&
        _trendingPosts.isEmpty &&
        _trendingStories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LineIcons.fire, size: 60, color: textSecondaryColor),
            SizedBox(height: 16),
            Text(
              'Henüz trend içerik yok',
              style: TextStyle(fontSize: 18, color: textColor),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      physics: BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _buildCategoriesHeader(),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Popüler Kullanıcılar',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                    itemCount:
                        _trendingUsers.length > 10 ? 10 : _trendingUsers.length,
                    itemBuilder: (context, index) {
                      final user = _trendingUsers[index];
                      return _buildPopularUserCard(user);
                    },
                  ),
                ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 32, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Popüler Gönderiler',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _loadTrendingPosts,
                  icon: Icon(Icons.refresh, color: Colors.blue, size: 16),
                  label: Text(
                    'Yenile',
                    style: TextStyle(color: Colors.blue, fontSize: 14),
                  ),
                  style: TextButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                )
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _isLoadingPosts
              ? Container(
                  height: 280,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                )
              : _trendingPosts.isEmpty
                  ? Container(
                      height: 280,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LineIcons.exclamationTriangle,
                                color: Colors.amber, size: 40),
                            SizedBox(height: 16),
                            Text(
                              _errorMessage ??
                                  'Bağlantı hatası. Lütfen tekrar deneyin.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadTrendingPosts,
                              icon: Icon(Icons.refresh),
                              label: Text('Tekrar Dene'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 4,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      height: 280,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: _trendingPosts.length > 10
                            ? 10
                            : _trendingPosts.length,
                        itemBuilder: (context, index) {
                          return _buildPopularPostCard(_trendingPosts[index]);
                        },
                      ),
                    ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 32, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Popüler Hikayeler',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                      height: 200,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: _trendingStories.length > 10
                            ? 10
                            : _trendingStories.length,
                        itemBuilder: (context, index) {
                          final story = _trendingStories[index];
                          return _buildPopularStoryCard(story);
                        },
                      ),
                    ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildCategoriesHeader() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.currentTheme.colorScheme.primary;
    final textColor =
        themeProvider.currentTheme.textTheme.bodyLarge?.color ?? Colors.white;

    // Temaya özgü kategori renkleri
    final categoryColors = [
      [
        themeProvider.currentTheme.colorScheme.primary,
        themeProvider.currentTheme.colorScheme.primary.withOpacity(0.7)
      ],
      [
        themeProvider.currentTheme.colorScheme.secondary,
        themeProvider.currentTheme.colorScheme.secondary.withOpacity(0.7)
      ],
      [Colors.pink.shade700, Colors.pink.shade500],
      [Colors.orange.shade700, Colors.orange.shade500],
      [Colors.green.shade700, Colors.green.shade500],
      [Colors.blue.shade700, Colors.blue.shade500],
    ];

    final categories = [
      {
        'icon': LineIcons.university,
        'name': 'Akademik',
        'gradient': categoryColors[0]
      },
      {'icon': LineIcons.book, 'name': 'Eğitim', 'gradient': categoryColors[1]},
      {'icon': LineIcons.music, 'name': 'Sanat', 'gradient': categoryColors[2]},
      {'icon': LineIcons.futbol, 'name': 'Spor', 'gradient': categoryColors[3]},
      {
        'icon': LineIcons.microphone,
        'name': 'Etkinlik',
        'gradient': categoryColors[4]
      },
      {
        'icon': LineIcons.coffee,
        'name': 'Sosyal',
        'gradient': categoryColors[5]
      },
    ];

    return Container(
      height: 110,
      padding: EdgeInsets.only(top: 16),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 10),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _searchController.text = category['name'] as String;
                _performSearch(category['name'] as String);
              });
            },
            child: Container(
              width: 80,
              margin: EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: category['gradient'] as List<Color>,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (category['gradient'] as List<Color>)
                              .first
                              .withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      category['icon'] as IconData,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    category['name'] as String,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopularUserCard(BestPopularityAccount user) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final cardColor = themeProvider.currentTheme.cardColor;
    final textColor =
        themeProvider.currentTheme.textTheme.bodyLarge?.color ?? Colors.white;
    final textSecondaryColor =
        themeProvider.currentTheme.textTheme.bodyMedium?.color ??
            Colors.white70;
    final primaryColor = themeProvider.currentTheme.colorScheme.primary;
    final accentColor = themeProvider.currentTheme.colorScheme.secondary;
    final dividerColor = themeProvider.currentTheme.dividerColor;

    final bool isPrivate = user.isPrivate ?? false;
    final int followerCount = user.followerCount ?? 0;
    final int popularityScore = user.popularityScore ?? 0;

    return GestureDetector(
      onTap: () async {
        print('Navigating to profile with username: ${user.username}');

        try {
          final prefs = await SharedPreferences.getInstance();
          final accessToken = prefs.getString('accessToken') ?? '';

          if (accessToken.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    'Oturum bilgisi bulunamadı. Lütfen tekrar giriş yapın.')));
            return;
          }

          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileScreen(
                  username: user.username,
                  userId: user.userId,
                ),
              ));
        } catch (e) {
          print('Error navigating to profile: $e');
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Kullanıcı profiline erişilemiyor: $e')));
        }
      },
      child: Container(
        width: 150,
        margin: EdgeInsets.only(right: 12, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(color: dividerColor.withOpacity(0.5), width: 1),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, accentColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: user.profilePhoto.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: user.profilePhoto,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.person,
                              color: Colors.white.withOpacity(0.7),
                              size: 40,
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.person,
                              color: Colors.white.withOpacity(0.7),
                              size: 40,
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LineIcons.fire, color: Colors.amber, size: 14),
                        SizedBox(width: 4),
                        Text(
                          '$popularityScore',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isPrivate)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white38, width: 1),
                      ),
                      child: Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.username,
                      style: TextStyle(
                        color: textColor,
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
                          LineIcons.userFriends,
                          color: primaryColor,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          _formatNumber(followerCount),
                          style: TextStyle(
                            color: textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                        Spacer(),
                        Icon(
                          LineIcons.star,
                          color: Colors.amber,
                          size: 14,
                        ),
                      ],
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

  Widget _buildPopularPostCard(PostDTO post) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final cardColor = themeProvider.currentTheme.cardColor;
    final textColor =
        themeProvider.currentTheme.textTheme.bodyLarge?.color ?? Colors.white;
    final textSecondaryColor =
        themeProvider.currentTheme.textTheme.bodyMedium?.color ??
            Colors.white70;
    final primaryColor = themeProvider.currentTheme.colorScheme.primary;
    final accentColor = themeProvider.currentTheme.colorScheme.secondary;
    final dividerColor = themeProvider.currentTheme.dividerColor;

    final String username = post.username ?? 'Kullanıcı';
    final String? profilePhoto = post.profilePhoto;
    final String? content = post.content.isNotEmpty ? post.content[0] : null;
    final String? text = post.description;
    final int likeCount = post.like ?? 0;
    final int commentCount = post.comment ?? 0;
    final String createdAt = _formatTimeAgo(post.createdAt);
    final bool isVideo = content != null && _isVideoContent(content);
    final int userId = post.userId ?? 0;

    return GestureDetector(
      onTap: () {
        // Post detaylarına yönlendir
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PostDetailsScreen(postId: post.postId.toString()),
          ),
        );
      },
      child: Container(
        width: 300,
        margin: EdgeInsets.only(right: 16, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(color: dividerColor.withOpacity(0.5), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      // Kullanıcı profiline yönlendir
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(
                            username: username,
                            userId: userId, // userId parametresini kullanıyoruz
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: cardColor.withOpacity(0.7),
                        backgroundImage:
                            profilePhoto != null && profilePhoto.isNotEmpty
                                ? CachedNetworkImageProvider(profilePhoto)
                                : null,
                        child: profilePhoto == null || profilePhoto.isEmpty
                            ? Icon(Icons.person,
                                size: 20, color: textSecondaryColor)
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Kullanıcı profiline yönlendirme
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfileScreen(
                              username: username,
                              userId:
                                  userId, // userId parametresini kullanıyoruz
                            ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            createdAt,
                            style: TextStyle(
                              color: textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LineIcons.heart,
                          color: Colors.red[400],
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          _formatNumber(likeCount),
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.5),
                ),
                child: content == null || content.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            text ?? '',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : isVideo
                        ? _buildVideoPlayer(content)
                        : CachedNetworkImage(
                            imageUrl: content,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(primaryColor),
                                strokeWidth: 2,
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Icon(Icons.broken_image,
                                  color: textSecondaryColor, size: 40),
                            ),
                          ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (text != null && text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        text,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Row(
                    children: [
                      _buildInteractionButton(
                          LineIcons.heart, Colors.red[400]!, 'Beğen'),
                      SizedBox(width: 16),
                      _buildInteractionButton(LineIcons.comment, primaryColor,
                          '$commentCount yorum'),
                      Spacer(),
                      _buildInteractionButton(
                          LineIcons.share, accentColor, 'Paylaş'),
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

  Widget _buildInteractionButton(IconData icon, Color color, String label) {
    final textSecondaryColor = Provider.of<ThemeProvider>(context)
            .currentTheme
            .textTheme
            .bodyMedium
            ?.color ??
        Colors.white70;

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: textSecondaryColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySection(String message) {
    final textSecondaryColor = Provider.of<ThemeProvider>(context)
            .currentTheme
            .textTheme
            .bodyMedium
            ?.color ??
        Colors.white70;

    return Container(
      height: 150,
      alignment: Alignment.center,
      child: Text(
        message,
        style: TextStyle(
          color: textSecondaryColor,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildPopularStoryCard(StoryDTO story) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final cardColor = themeProvider.currentTheme.cardColor;
    final primaryColor = themeProvider.currentTheme.colorScheme.primary;
    final accentColor = themeProvider.currentTheme.colorScheme.secondary;

    final String username = story.username ?? 'Kullanıcı';
    final String? profilePhoto = story.profilePhoto;
    final String? content = story.photo;
    final int viewCount = story.score ?? 0;
    final int userId = story.userId ?? 0;

    return GestureDetector(
      onTap: () async {
        try {
          // StoryDTO'yu HomeStoryDTO'ya dönüştür
          final HomeStoryDTO homeStoryDto =
              _convertStoryDTOToHomeStoryDTO(story);

          // Diğer hikayeleri de dönüştür
          final List<HomeStoryDTO> homeStories = _trendingStories
              .map((trendingStory) =>
                  _convertStoryDTOToHomeStoryDTO(trendingStory))
              .toList();

          // Hikayeyi görüntüleme ekranına yönlendir
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoryViewerScreen(
                story: homeStoryDto,
                allStories: homeStories,
                initialIndex: _trendingStories.indexOf(story),
              ),
            ),
          );
        } catch (e) {
          print('Hikaye görüntüleme hatası: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hikaye görüntülenirken bir hata oluştu')),
          );
        }
      },
      child: Container(
        width: 130,
        margin: EdgeInsets.only(right: 16, top: 8, bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor,
              accentColor,
              Colors.orange.shade400,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
            ),
            child: Stack(
              children: [
                content != null && content.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: content,
                        fit: BoxFit.cover,
                        height: double.infinity,
                        width: double.infinity,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(primaryColor),
                            strokeWidth: 2,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: cardColor.withOpacity(0.5),
                          child: Center(
                            child: Icon(
                              LineIcons.exclamationCircle,
                              color: Colors.white70,
                              size: 30,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: cardColor.withOpacity(0.5),
                        child: Center(
                          child: Icon(
                            LineIcons.book,
                            color: Colors.white70,
                            size: 30,
                          ),
                        ),
                      ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.9),
                          Colors.black.withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accentColor,
                                  width: 1.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 12,
                                backgroundImage: profilePhoto != null &&
                                        profilePhoto.isNotEmpty
                                    ? CachedNetworkImageProvider(profilePhoto)
                                    : null,
                                backgroundColor: cardColor.withOpacity(0.5),
                                child:
                                    profilePhoto == null || profilePhoto.isEmpty
                                        ? Text(
                                            username.isNotEmpty
                                                ? username[0].toUpperCase()
                                                : '',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                              ),
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                username,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
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
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white24,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LineIcons.eye, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          _formatNumber(viewCount),
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
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

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';

    return timeago.format(dateTime, locale: 'tr');
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';
      final response = await _studentService.fetchProfile(accessToken);

      if (mounted && response.isSuccess == true) {
        setState(() {
          _profileData = response.data;
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  // Check if content is a video
  bool _isVideoContent(String url) {
    return url.endsWith('.mp4') ||
        url.endsWith('.mov') ||
        url.endsWith('.avi') ||
        url.endsWith('.mkv') ||
        url.endsWith('.webm') ||
        url.endsWith('.m3u8') ||
        url.contains('video');
  }

  // Build video player widget
  Widget _buildVideoPlayer(String videoUrl) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: VideoPlayerWidget(
          videoUrl: videoUrl,
          autoPlay: false,
          looping: true,
          showControls: true,
          isInFeed: true,
          muted: true,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // Yeni eklenen converter fonksiyonu - StoryDTO'yu HomeStoryDTO'ya dönüştür
  HomeStoryDTO _convertStoryDTOToHomeStoryDTO(StoryDTO storyDto) {
    return HomeStoryDTO(
      storyId: [storyDto.storyId], // Story ID'sini bir liste içine alıyoruz
      studentId: storyDto.userId,
      username: storyDto.username,
      photos: [storyDto.photo], // Story photo'yu bir liste içine alıyoruz
      profilePhoto: storyDto.profilePhoto,
      isVisited: false, // Varsayılan olarak ziyaret edilmemiş
    );
  }
}
