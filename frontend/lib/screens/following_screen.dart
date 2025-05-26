import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:social_media/models/followed_user_dto.dart';
import 'package:social_media/services/followRelationService.dart';
import 'package:dio/dio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:social_media/screens/profile_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:social_media/screens/user_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:social_media/theme/theme_provider.dart';
import 'package:social_media/theme/app_theme.dart';

class FollowingScreen extends StatefulWidget {
  final String username;

  const FollowingScreen({Key? key, required this.username}) : super(key: key);

  @override
  _FollowingScreenState createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _followingList = [];
  String? _errorMessage;
  int _page = 0; // API kullanım için
  bool _hasMorePages = true;
  bool _isLoadingMore = false;
  bool _isSearchActive = false;
  final ScrollController _scrollController = ScrollController();
  late final FollowRelationService _followService;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  List<dynamic> _filteredList = [];
  String? _accessToken;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Initialize service with base URL
    final dio = Dio(BaseOptions(
      baseUrl: 'http://192.168.89.61:8080/v1/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    _followService = FollowRelationService(dio);

    _loadToken();
    _scrollController.addListener(_scrollListener);
  }

  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('accessToken');
      _fetchFollowing();
    } catch (e) {
      print("Token yükleme hatası: $e");
      setState(() {
        _errorMessage = 'Token yüklenemedi: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMorePages &&
        !_isSearchActive) {
      _loadMoreFollowing();
    }
  }

  void _filterFollowing(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredList = _followingList;
        _isSearchActive = false;
      });
      return;
    }

    final filteredList = _followingList.where((user) {
      final fullName = user['fullName'] ?? '';
      final username = user['username'] ?? '';
      final bio = user['bio'] ?? '';
      return fullName.toLowerCase().contains(query.toLowerCase()) ||
          username.toLowerCase().contains(query.toLowerCase()) ||
          bio.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredList = filteredList;
      _isSearchActive = true;
    });
  }

  Future<void> _fetchFollowing() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_accessToken == null || _accessToken!.isEmpty) {
        setState(() {
          _errorMessage =
              'Oturum bilgisi bulunamadı. Lütfen tekrar giriş yapın.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(
            'http://192.168.89.61:8080/v1/api/follow-relations/following/${widget.username}'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            _followingList = responseData['data'];
            _filteredList = _followingList;
            _isLoading = false;
          });
          _animationController.reset();
          _animationController.forward();
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = responseData['message'] ??
                'Takip edilen kullanıcılar alınamadı.';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'HTTP Hatası: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Bağlantı hatası: $e';
      });
    }
  }

  Future<void> _loadMoreFollowing() async {
    if (_isLoadingMore || !_hasMorePages || _isSearchActive) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      if (_accessToken == null || _accessToken!.isEmpty) {
        setState(() {
          _errorMessage =
              'Oturum bilgisi bulunamadı. Lütfen tekrar giriş yapın.';
          _isLoadingMore = false;
        });
        return;
      }

      // Dio yerine http paket kullanarak API'den veri çekelim (_fetchFollowing ile tutarlı olması için)
      final response = await http.get(
        Uri.parse(
            'http://192.168.89.61:8080/v1/api/follow-relations/following/${widget.username}?page=$_page'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final newFollowing = responseData['data'] as List;

          if (newFollowing.isNotEmpty) {
            setState(() {
              _followingList.addAll(newFollowing);
              _filteredList = _followingList;
              _isLoadingMore = false;
              _hasMorePages = newFollowing.length >= 10;
              _page++;
            });
            _animationController.reset();
            _animationController.forward();
          } else {
            setState(() {
              _hasMorePages = false;
              _isLoadingMore = false;
            });
          }
        } else {
          setState(() {
            _errorMessage = responseData['message'] ??
                'Daha fazla takip edilen kullanıcı yüklenemedi.';
            _isLoadingMore = false;
          });
        }
      } else {
        setState(() {
          _isLoadingMore = false;
          _errorMessage = 'HTTP Hatası: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Bağlantı hatası: $e';
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _unfollowUser(int userId) async {
    try {
      final response =
          await _followService.removeFollowing(_accessToken!, userId);

      if (response.isSuccess) {
        setState(() {
          _followingList.removeWhere((user) => user['id'] == userId);
          if (_isSearchActive) {
            // Arama aktifse, filtreyi yeniden uygulayalım
            _filterFollowing(_searchController.text);
          } else {
            // Arama aktif değilse, filtrelenmiş listeyi ana listeyle eşitleyelim
            _filteredList = _followingList;
          }
        });

        if (!mounted) return;
        _showSnackBar('Takibi bıraktın', isError: false);
      } else {
        if (!mounted) return;
        _showSnackBar('Takipten çıkarılamadı: ${response.message}',
            isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Bağlantı hatası: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Tamam',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _refreshFollowing() {
    setState(() {
      _page = 0;
      _followingList = [];
      _filteredList = [];
      _isSearchActive = false;
      _searchController.clear();
    });
    _fetchFollowing();
  }

  // Refresh için Future<void> döndüren yeni metod
  Future<void> _handleRefresh() async {
    _refreshFollowing();
    // RefreshIndicator için bir Future dönmemiz gerekiyor
    return Future.delayed(const Duration(milliseconds: 500));
  }

  String _formatDate(dynamic dateData) {
    try {
      if (dateData == null) return 'Bilinmeyen tarih';

      DateTime date;
      if (dateData is String) {
        date = DateTime.parse(dateData);
      } else if (dateData is DateTime) {
        date = dateData;
      } else if (dateData is int) {
        date = DateTime.fromMillisecondsSinceEpoch(dateData);
      } else {
        return 'Geçersiz tarih formatı';
      }

      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays < 1) {
        if (difference.inHours < 1) {
          return '${difference.inMinutes} dakika önce';
        }
        return '${difference.inHours} saat önce';
      } else if (difference.inDays < 30) {
        return '${difference.inDays} gün önce';
      } else {
        return DateFormat('dd MMM yyyy', 'tr_TR').format(date);
      }
    } catch (e) {
      return 'Bilinmeyen tarih: $e';
    }
  }

  // Kullanıcı profiline güvenli yönlendirme için yardımcı fonksiyon
  void _navigateToUserProfile(dynamic following) {
    if (_accessToken == null || _accessToken!.isEmpty) {
      _showErrorMessage(
          'Oturum bilgisi bulunamadı. Lütfen tekrar giriş yapın.');
      return;
    }

    // User ID ve username kontrolü
    if (following == null) {
      _showErrorMessage('Geçersiz kullanıcı bilgisi.');
      return;
    }

    final String username = following['username']?.toString() ?? '';
    final int userId = following['id'] ?? -1;

    if (username.isEmpty || userId == -1) {
      _showErrorMessage('Kullanıcı bilgileri eksik. Yönlendirme yapılamadı.');
      return;
    }

    print('Navigating to user profile: $username (ID: $userId)');

    // UserProfileScreen'e yönlendir ve userId parametresini geçir
    // Account-details API'si ile çalışacak şekilde
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          username: username,
          userId: userId, // UserProfileScreen'e userId parametresi eklenmeli!
        ),
      ),
    ).then((value) {
      // Profil ekranından geri dönüldüğünde ihtiyaç olursa işlemler yapılabilir
    }).catchError((error) {
      print('UserProfile yönlendirme hatası: $error');
      _showErrorMessage('Profil sayfası yüklenirken hata oluştu: $error');
    });
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Tema renklerini al
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final primaryColor = theme.colorScheme.primary;
    final accentColor = theme.colorScheme.secondary;
    final textColor = theme.colorScheme.onBackground;
    final textSecondaryColor =
        theme.textTheme.bodySmall?.color ?? Colors.white70;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(backgroundColor, primaryColor, textColor),
      body: Column(
        children: [
          _buildSearchBar(
              cardColor, primaryColor, textColor, textSecondaryColor),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: textColor,
              backgroundColor: primaryColor,
              child: _isLoading
                  ? _buildLoadingIndicator(primaryColor, textColor)
                  : _errorMessage != null
                      ? _buildErrorWidget(backgroundColor, cardColor,
                          primaryColor, textColor, textSecondaryColor)
                      : _filteredList.isEmpty
                          ? _isSearchActive
                              ? _buildNoSearchResultsScreen(cardColor,
                                  accentColor, textColor, textSecondaryColor)
                              : _buildEmptyWidget(cardColor, primaryColor,
                                  textColor, textSecondaryColor)
                          : _buildFollowingList(
                              backgroundColor,
                              cardColor,
                              primaryColor,
                              accentColor,
                              textColor,
                              textSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      Color backgroundColor, Color primaryColor, Color textColor) {
    return AppBar(
      backgroundColor: backgroundColor,
      title: Text('${widget.username} Takip Ettikleri',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          )),
      titleSpacing: 0,
      iconTheme: IconThemeData(color: primaryColor),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(CupertinoIcons.refresh, color: primaryColor),
          onPressed: _refreshFollowing,
          tooltip: 'Yenile',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.1),
                primaryColor.withOpacity(0.5),
                primaryColor.withOpacity(0.1),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(Color cardColor, Color primaryColor, Color textColor,
      Color textSecondaryColor) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _filterFollowing,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'Takip ettiklerini ara...',
            hintStyle: TextStyle(color: textSecondaryColor),
            prefixIcon: Icon(CupertinoIcons.search, color: primaryColor),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(CupertinoIcons.clear_circled_solid),
                    color: Colors.grey.shade500,
                    onPressed: () {
                      _searchController.clear();
                      _filterFollowing('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(Color primaryColor, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              color: primaryColor,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Takip edilenler yükleniyor...',
            style: TextStyle(color: textColor, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(
          color: Colors.grey,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(Color backgroundColor, Color cardColor,
      Color primaryColor, Color textColor, Color textSecondaryColor) {
    final isConnectionError =
        _errorMessage?.toLowerCase().contains('bağlantı') == true;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isConnectionError
                      ? [
                          Colors.orange.withOpacity(0.7),
                          Colors.deepOrange.withOpacity(0.7)
                        ]
                      : [
                          Colors.redAccent.withOpacity(0.7),
                          Colors.red.withOpacity(0.7)
                        ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isConnectionError
                        ? Colors.orange.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                isConnectionError
                    ? CupertinoIcons.wifi_slash
                    : CupertinoIcons.exclamationmark_circle,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isConnectionError ? 'Bağlantı Hatası' : 'Bir hata oluştu',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isConnectionError
                      ? Colors.orange.withOpacity(0.3)
                      : Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _errorMessage ?? 'Takip edilenler yüklenirken bir hata oluştu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondaryColor, height: 1.4),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshFollowing,
              icon: const Icon(CupertinoIcons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(Color cardColor, Color primaryColor, Color textColor,
      Color textSecondaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cardColor,
                  cardColor.withOpacity(0.8),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              CupertinoIcons.person_2_fill,
              color: primaryColor,
              size: 70,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Henüz takip edilen kullanıcı yok',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 22,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              '${widget.username} henüz kimseyi takip etmiyor.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textSecondaryColor,
                height: 1.5,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 400));
  }

  Widget _buildNoSearchResultsScreen(Color cardColor, Color accentColor,
      Color textColor, Color textSecondaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cardColor,
                  cardColor.withOpacity(0.8),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              CupertinoIcons.search,
              size: 70,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sonuç bulunamadı',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accentColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              '"${_searchController.text}" aramasıyla eşleşen takip edilen kullanıcı bulunamadı.',
              style: TextStyle(
                fontSize: 16,
                color: textSecondaryColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () {
              _searchController.clear();
              _filterFollowing('');
            },
            icon: Icon(CupertinoIcons.arrow_left, color: accentColor),
            label: Text(
              'Tüm Takip Edilenleri Göster',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              backgroundColor: accentColor.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowingList(
      Color backgroundColor,
      Color cardColor,
      Color primaryColor,
      Color accentColor,
      Color textColor,
      Color textSecondaryColor) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount:
          _filteredList.length + (_hasMorePages && !_isSearchActive ? 1 : 0),
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      cacheExtent: 500,
      itemBuilder: (context, index) {
        if (index == _filteredList.length) {
          return _buildLoadingMoreIndicator();
        }

        if (index >= _filteredList.length) return null;

        final following = _filteredList[index];
        return _buildFollowingItem(backgroundColor, cardColor, primaryColor,
            accentColor, textColor, textSecondaryColor, following, index);
      },
    );
  }

  Widget _buildFollowingItem(
      Color backgroundColor,
      Color cardColor,
      Color primaryColor,
      Color accentColor,
      Color textColor,
      Color textSecondaryColor,
      dynamic following,
      int index) {
    // Handle nullability safely
    final String displayName = (following['fullName'] != null &&
            following['fullName'].toString().isNotEmpty)
        ? following['fullName'].toString()
        : (following['username'] != null &&
                following['username'].toString().isNotEmpty)
            ? following['username'].toString()
            : 'Kullanıcı';

    final isActive = following['isActive'] == true;
    final isDefaultPhoto = following['profilePhoto'] == null ||
        following['profilePhoto'].toString().isEmpty ||
        following['profilePhoto'] ==
            'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg';

    // Optimize edilmiş, daha verimli takip edilen kişi kartı
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? accentColor.withOpacity(0.3) : Colors.transparent,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), // Daha hafif gölge
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToUserProfile(following),
              splashColor: accentColor.withOpacity(0.1),
              highlightColor: accentColor.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Photo - optimize edilmiş
                        GestureDetector(
                          onTap: () => _navigateToUserProfile(following),
                          child: Hero(
                            tag: 'profile_${following['id']}',
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: isActive
                                    ? LinearGradient(
                                        colors: [accentColor, primaryColor],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: isActive ? null : cardColor,
                                border: !isActive
                                    ? Border.all(
                                        color: Colors.grey.shade700, width: 1)
                                    : null,
                              ),
                              padding: const EdgeInsets.all(2),
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: !isDefaultPhoto
                                      ? CachedNetworkImage(
                                          imageUrl: following['profilePhoto'],
                                          fit: BoxFit.cover,
                                          memCacheWidth:
                                              120, // Önbellek optimizasyonu
                                          memCacheHeight: 120,
                                          maxWidthDiskCache: 200,
                                          placeholder: (context, url) =>
                                              Container(
                                            color: backgroundColor,
                                            child: const Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                              Color>(
                                                          Colors.white54),
                                                ),
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                            color: backgroundColor,
                                            child: Icon(
                                              CupertinoIcons.person_fill,
                                              color: Colors.grey.shade500,
                                              size: 30,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: backgroundColor,
                                          child: Icon(
                                            CupertinoIcons.person_fill,
                                            color: Colors.grey.shade500,
                                            size: 30,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // User Info - hızlandırılmış
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      displayName,
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (following['isPrivate'] == true)
                                    Container(
                                      margin: const EdgeInsets.only(left: 4),
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.lock_fill,
                                        color: Colors.amber,
                                        size: 12,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '@${following['username']}',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (following['bio'] != null &&
                                  following['bio'].toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  following['bio'],
                                  style: TextStyle(
                                    color: textSecondaryColor,
                                    fontSize: 13,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Follow info and button
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Meta info - optimize edilmiş
                        Wrap(
                          spacing: 8,
                          runSpacing: 8, // Dikey aralık ekledim
                          children: [
                            // Follow time
                            if (following['followedDate'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      CupertinoIcons.time,
                                      color: accentColor,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(following['followedDate']),
                                      style: TextStyle(
                                        color: textSecondaryColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Popularity score
                            if (following['popularityScore'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      CupertinoIcons.star_fill,
                                      color: _getPopularityColor(
                                          following['popularityScore']),
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${following['popularityScore']}',
                                      style: TextStyle(
                                        color: textSecondaryColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        // Buttons - daha kompakt ve optimize edilmiş
                        Row(
                          children: [
                            // Unfollow Button
                            SizedBox(
                              height: 32,
                              child: OutlinedButton(
                                onPressed: () {
                                  // Show confirmation dialog
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: cardColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: Text(
                                        'Takibi Bırak',
                                        style: TextStyle(color: textColor),
                                      ),
                                      content: Text(
                                        '$displayName adlı kullanıcıyı takip etmeyi bırakmak istediğinize emin misiniz?',
                                        style: TextStyle(
                                            color: textSecondaryColor),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text(
                                            'İptal',
                                            style: TextStyle(
                                                color: textSecondaryColor),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _unfollowUser(following['id']);
                                          },
                                          child: const Text(
                                            'Takibi Bırak',
                                            style: TextStyle(
                                                color: Colors.redAccent),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: accentColor,
                                  side: BorderSide(
                                    color: accentColor.withOpacity(0.7),
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 0),
                                ),
                                child: const Text(
                                  'Takip Ediliyor',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),

                            // View profile button
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 32,
                              child: ElevatedButton(
                                onPressed: () =>
                                    _navigateToUserProfile(following),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 0),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(CupertinoIcons.eye, size: 14),
                                    SizedBox(width: 4),
                                    Text('Görüntüle',
                                        style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    )
        .animate(
            delay: Duration(
                milliseconds:
                    index < 10 ? 50 * index : 0), // İlk 10 öğe için animasyon
            controller: _animationController,
            autoPlay: index < 10) // Sadece ilk 10 için otomatik oynatma
        .fadeIn(
          duration:
              index < 10 ? const Duration(milliseconds: 300) : Duration.zero,
        )
        .slideY(
            begin: index < 10 ? 0.1 : 0,
            end: 0,
            duration:
                index < 10 ? const Duration(milliseconds: 300) : Duration.zero,
            curve: Curves.easeOutCubic);
  }

  // Popülerlik renkleri için tema bazlı renkler
  Color _getPopularityColor(int score) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    if (themeProvider.themeType == ThemeType.vaporwave) {
      if (score >= 201)
        return const Color(0xFFFF00FF); // Bright pink for vaporwave
      if (score >= 101) return const Color(0xFF00FFFF); // Cyan for vaporwave
      if (score >= 51) return const Color(0xFFFFD200); // Yellow for vaporwave
      if (score >= 21) return const Color(0xFF00FFAA); // Green for vaporwave
      return Colors.grey;
    } else if (themeProvider.themeType == ThemeType.nature) {
      if (score >= 201) return const Color(0xFF4CAF50); // More natural greens
      if (score >= 101) return const Color(0xFF81C784);
      if (score >= 51) return const Color(0xFFA5D6A7);
      if (score >= 21) return const Color(0xFFC8E6C9);
      return Colors.grey;
    } else if (themeProvider.themeType == ThemeType.cream) {
      if (score >= 201)
        return const Color(0xFFFF9800); // Warmer tones for cream
      if (score >= 101) return const Color(0xFFFFA726);
      if (score >= 51) return const Color(0xFFFFB74D);
      if (score >= 21) return const Color(0xFFFFCC80);
      return Colors.grey;
    } else {
      // Default colors
      if (score >= 201) return const Color(0xFFFF9D3D); // Orange
      if (score >= 101) return const Color(0xFFD55AC0); // Purple
      if (score >= 51) return const Color(0xFF45C4B0); // Teal
      if (score >= 21) return const Color(0xFF9DDE70); // Green
      return Colors.grey;
    }
  }
}
