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

class FollowersScreen extends StatefulWidget {
  final String username;

  const FollowersScreen({Key? key, required this.username}) : super(key: key);

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _followers = [];
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredFollowers = [];
  bool _isSearching = false;
  late AnimationController _animationController;
  String? _accessToken;

  @override
  void initState() {
    super.initState();
    _loadToken();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('accessToken');
      _fetchFollowers();
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
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Kullanıcı profiline güvenli yönlendirme fonksiyonu
  void _navigateToUserProfile(Map<String, dynamic> user) {
    if (_accessToken == null || _accessToken!.isEmpty) {
      _showErrorMessage(
          'Oturum bilgisi bulunamadı. Lütfen tekrar giriş yapın.');
      return;
    }

    if (user['username'] == null || user['username'].toString().isEmpty) {
      _showErrorMessage('Geçersiz kullanıcı adı.');
      return;
    }

    String username = user['username'].toString();
    int userId = user['id'] ?? -1;

    if (userId == -1) {
      _showErrorMessage('Kullanıcı ID bilgisi bulunamadı.');
      return;
    }

    print('Navigating to user profile: $username (ID: $userId)');

    // UserProfileScreen'e yönlendir ve userId parametresini geçir
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          username: username,
          userId: userId, // UserProfileScreen'e userId parametresi eklendi
        ),
      ),
    ).then((value) {
      // Ekrandan dönüldüğünde yapılacak işlemler
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

  void _filterFollowers(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredFollowers = _followers;
        _isSearching = false;
      });
      return;
    }

    final filteredList = _followers.where((follower) {
      final fullName = follower['fullName'] ?? '';
      final username = follower['username'] ?? '';
      return fullName.toLowerCase().contains(query.toLowerCase()) ||
          username.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredFollowers = filteredList;
      _isSearching = true;
    });
  }

  Future<void> _fetchFollowers() async {
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
            'http://192.168.89.61:8080/v1/api/follow-relations/followers/${widget.username}'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            _followers = responseData['data'];
            _filteredFollowers = _followers;
            _isLoading = false;
          });
          _animationController.reset();
          _animationController.forward();
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage =
                responseData['message'] ?? 'Takipçi listesi alınamadı.';
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
              onRefresh: _fetchFollowers,
              color: textColor,
              backgroundColor: primaryColor,
              child: _isLoading
                  ? _buildLoadingScreen(primaryColor, textColor)
                  : _errorMessage != null
                      ? _buildErrorScreen(
                          cardColor, textColor, textSecondaryColor)
                      : _filteredFollowers.isEmpty
                          ? _isSearching
                              ? _buildNoSearchResultsScreen(cardColor,
                                  accentColor, textColor, textSecondaryColor)
                              : _buildEmptyScreen(cardColor, primaryColor,
                                  textColor, textSecondaryColor)
                          : _buildFollowersList(backgroundColor, primaryColor,
                              accentColor, textColor, textSecondaryColor),
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
      elevation: 0,
      title: Text(
        '${widget.username} Takipçileri',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(CupertinoIcons.refresh, color: primaryColor),
          onPressed: _fetchFollowers,
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
          onChanged: _filterFollowers,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'Takipçi Ara...',
            hintStyle: TextStyle(color: textSecondaryColor),
            prefixIcon: Icon(CupertinoIcons.search, color: primaryColor),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(CupertinoIcons.clear_circled_solid),
                    color: Colors.grey.shade500,
                    onPressed: () {
                      _searchController.clear();
                      _filterFollowers('');
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

  Widget _buildLoadingScreen(Color primaryColor, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Takipçiler yükleniyor...',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(
      Color cardColor, Color textColor, Color textSecondaryColor) {
    final isConnectionError =
        _errorMessage?.toLowerCase().contains('bağlantı') == true;
    final errorColor = isConnectionError ? Colors.orange : Colors.red;

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
                    color: errorColor.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                isConnectionError
                    ? CupertinoIcons.wifi_slash
                    : CupertinoIcons.exclamationmark_circle,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isConnectionError ? 'Bağlantı Hatası' : 'Bir hata oluştu',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: errorColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _errorMessage ?? 'Bilinmeyen bir hata oluştu',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(CupertinoIcons.refresh),
              label: const Text(
                'Tekrar Dene',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: _fetchFollowers,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyScreen(Color cardColor, Color primaryColor, Color textColor,
      Color textSecondaryColor) {
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
              CupertinoIcons.person_2_fill,
              size: 70,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Henüz takipçi yok',
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
                color: primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              '${widget.username} kullanıcısının henüz takipçisi bulunmuyor.',
              style: TextStyle(
                fontSize: 16,
                color: textSecondaryColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
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
              '"${_searchController.text}" aramasıyla eşleşen takipçi bulunamadı.',
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
              _filterFollowers('');
            },
            icon: Icon(CupertinoIcons.arrow_left, color: accentColor),
            label: Text(
              'Tüm Takipçileri Göster',
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

  Widget _buildFollowersList(Color backgroundColor, Color primaryColor,
      Color accentColor, Color textColor, Color textSecondaryColor) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: _filteredFollowers.length,
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      cacheExtent: 500,
      itemBuilder: (context, index) {
        if (index >= _filteredFollowers.length) return null;

        final follower = _filteredFollowers[index];
        final isDefaultPhoto = follower['profilePhoto'] == null ||
            follower['profilePhoto'].isEmpty ||
            follower['profilePhoto'] ==
                'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg';
        final isActive = follower['isActive'] == true;

        return RepaintBoundary(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: isActive
                    ? primaryColor.withOpacity(0.3)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _navigateToUserProfile(follower);
                  },
                  splashColor: primaryColor.withOpacity(0.1),
                  highlightColor: primaryColor.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                _navigateToUserProfile(follower);
                              },
                              child: Hero(
                                tag: 'profile_${follower['id']}',
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
                                    color: isActive
                                        ? null
                                        : Theme.of(context).cardColor,
                                    border: !isActive
                                        ? Border.all(
                                            color: Colors.grey.shade700,
                                            width: 1)
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
                                              imageUrl:
                                                  follower['profilePhoto'],
                                              fit: BoxFit.cover,
                                              memCacheWidth: 120,
                                              memCacheHeight: 120,
                                              maxWidthDiskCache: 200,
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Container(
                                                color: backgroundColor,
                                                child: Icon(
                                                  CupertinoIcons.person_fill,
                                                  color: Colors.grey.shade500,
                                                  size: 30,
                                                ),
                                              ),
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          follower['fullName'] ?? '',
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (follower['isPrivate'] == true)
                                        Container(
                                          margin:
                                              const EdgeInsets.only(left: 4),
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.amber.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            CupertinoIcons.lock_fill,
                                            color: Colors.amber,
                                            size: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '@${follower['username'] ?? ''}',
                                    style: TextStyle(
                                      color: accentColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (follower['bio'] != null &&
                                      follower['bio']
                                          .toString()
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      follower['bio'],
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
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (follower['followedDate'] != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.time,
                                      color: accentColor,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(follower['followedDate']),
                                      style: TextStyle(
                                        color: textSecondaryColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (follower['popularityScore'] != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.star_fill,
                                      color: _getPopularityColor(
                                          follower['popularityScore']),
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${follower['popularityScore']}',
                                      style: TextStyle(
                                        color: textSecondaryColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const Spacer(),
                            OutlinedButton(
                              onPressed: () {
                                _navigateToUserProfile(follower);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                side: BorderSide(color: primaryColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(CupertinoIcons.eye, size: 16),
                                  SizedBox(width: 6),
                                  Text('Görüntüle'),
                                ],
                              ),
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
              delay: Duration(milliseconds: index < 10 ? 50 * index : 0),
              controller: _animationController,
              autoPlay: index < 10,
            )
            .fadeIn(
              duration: index < 10
                  ? const Duration(milliseconds: 300)
                  : Duration.zero,
            )
            .slideY(
              begin: index < 10 ? 0.1 : 0,
              end: 0,
              duration: index < 10
                  ? const Duration(milliseconds: 300)
                  : Duration.zero,
              curve: Curves.easeOutCubic,
            );
      },
    );
  }

  String _formatDate(dynamic dateData) {
    if (dateData == null) return 'Bilinmeyen tarih';

    DateTime? date;
    if (dateData is String) {
      try {
        date = DateTime.parse(dateData);
      } catch (e) {
        return 'Geçersiz tarih';
      }
    } else if (dateData is int) {
      try {
        date = DateTime.fromMillisecondsSinceEpoch(dateData);
      } catch (e) {
        return 'Geçersiz tarih';
      }
    }

    if (date == null) return 'Bilinmeyen tarih';

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
      return DateFormat('dd MMM yyyy').format(date);
    }
  }

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
