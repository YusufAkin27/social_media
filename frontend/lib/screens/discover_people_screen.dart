import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media/models/suggest_user_request.dart';
import 'package:social_media/models/search_account_dto.dart';
import 'package:social_media/models/data_response_message.dart';
import 'package:social_media/services/studentService.dart';
import 'package:social_media/services/followRelationService.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dio/dio.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:social_media/theme/theme_provider.dart';

class DiscoverPeopleScreen extends StatefulWidget {
  const DiscoverPeopleScreen({Key? key}) : super(key: key);

  @override
  _DiscoverPeopleScreenState createState() => _DiscoverPeopleScreenState();
}

class _DiscoverPeopleScreenState extends State<DiscoverPeopleScreen>
    with SingleTickerProviderStateMixin {
  final StudentService _studentService = StudentService();
  final FollowRelationService _followService = FollowRelationService(Dio());
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<SuggestUserRequest> _suggestedUsers = [];
  List<SearchAccountDTO> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  bool _loadingSearchResults = false;
  String? _errorMessage;
  int _currentSearchPage = 0;

  // UI related
  final List<String> _categories = [
    'Önerilen',
    'En Popüler',
    'Fakültemden',
    'Bölümümden',
    'Yeni Kullanıcılar'
  ];
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _loadSuggestedUsers();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestedUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await _studentService.fetchSuggestedUsers(accessToken);

      if (response.isSuccess) {
        // Add some fake data for demo purposes
        final users = response.data ?? [];

        // Enhance with fake data if response is too simple
        if (users.isNotEmpty && users.every((u) => u.fullName == null)) {
          final enhancedUsers = users.map((user) {
            final random = math.Random();
            return SuggestUserRequest(
              username: user.username,
              profilePhotoUrl: user.profilePhotoUrl,
              fullName: _generateRandomName(),
              department: _getRandomDepartment(),
              mutualConnections: random.nextInt(15) + 1,
              isFollowing: false,
            );
          }).toList();

          setState(() {
            _suggestedUsers = enhancedUsers;
            _isLoading = false;
          });
        } else {
          setState(() {
            _suggestedUsers = users;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Kullanıcı önerileri alınamadı: ${response.message}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Bağlantı hatası: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _loadingSearchResults = true;
      _isSearching = true;
      _currentSearchPage = 0;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response =
          await _studentService.search(accessToken, query, _currentSearchPage);

      if (response.isSuccess) {
        setState(() {
          _searchResults = response.data ?? [];
          _loadingSearchResults = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Arama sonuçları alınamadı: ${response.message}';
          _loadingSearchResults = false;
          _searchResults = [];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Arama yaparken hata oluştu: $e';
        _loadingSearchResults = false;
        _searchResults = [];
      });
    }
  }

  Future<void> _followUser(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      // Here we would call the follow API
      // This is a placeholder since we don't have the actual follow API

      // Update UI optimistically
      setState(() {
        for (var i = 0; i < _suggestedUsers.length; i++) {
          if (_suggestedUsers[i].username == username) {
            final updatedUser = SuggestUserRequest(
              username: _suggestedUsers[i].username,
              profilePhotoUrl: _suggestedUsers[i].profilePhotoUrl,
              fullName: _suggestedUsers[i].fullName,
              department: _suggestedUsers[i].department,
              mutualConnections: _suggestedUsers[i].mutualConnections,
              isFollowing: true,
            );
            _suggestedUsers[i] = updatedUser;
            break;
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$username kullanıcısını takip ediyorsun'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Takip işlemi başarısız: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _unfollowUser(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      // Here we would call the unfollow API
      // This is a placeholder since we don't have the actual unfollow API

      // Update UI optimistically
      setState(() {
        for (var i = 0; i < _suggestedUsers.length; i++) {
          if (_suggestedUsers[i].username == username) {
            final updatedUser = SuggestUserRequest(
              username: _suggestedUsers[i].username,
              profilePhotoUrl: _suggestedUsers[i].profilePhotoUrl,
              fullName: _suggestedUsers[i].fullName,
              department: _suggestedUsers[i].department,
              mutualConnections: _suggestedUsers[i].mutualConnections,
              isFollowing: false,
            );
            _suggestedUsers[i] = updatedUser;
            break;
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$username kullanıcısını takip etmeyi bıraktın'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Takibi bırakma işlemi başarısız: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _changeCategory(int index) {
    setState(() {
      _selectedCategoryIndex = index;
    });

    // In a real app, you'd fetch different data based on the category
    // For now, just show the same suggested users
  }

  // Helpers for demo data
  String _generateRandomName() {
    final List<String> firstNames = [
      'Ali',
      'Ayşe',
      'Mehmet',
      'Fatma',
      'Ahmet',
      'Zeynep',
      'Mustafa',
      'Emine',
      'Hüseyin',
      'Hatice',
      'İbrahim',
      'Merve',
      'Yusuf',
      'Elif',
      'Ömer',
      'Selin'
    ];
    final List<String> lastNames = [
      'Yılmaz',
      'Kaya',
      'Demir',
      'Çelik',
      'Şahin',
      'Yıldız',
      'Çetin',
      'Şen',
      'Özdemir',
      'Aydın',
      'Arslan',
      'Doğan',
      'Kılıç',
      'Aslan',
      'Çelik',
      'Kurt'
    ];

    final random = math.Random();
    return '${firstNames[random.nextInt(firstNames.length)]} ${lastNames[random.nextInt(lastNames.length)]}';
  }

  String _getRandomDepartment() {
    final List<String> departments = [
      'Bilgisayar Mühendisliği',
      'Elektrik-Elektronik Mühendisliği',
      'Makine Mühendisliği',
      'Endüstri Mühendisliği',
      'İnşaat Mühendisliği',
      'Tıp',
      'Psikoloji',
      'İşletme',
      'Hukuk',
      'Edebiyat'
    ];

    return departments[math.Random().nextInt(departments.length)];
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Kişileri Keşfet',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, size: 18),
            color: theme.colorScheme.onSurface,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.refresh, size: 20),
              color: theme.colorScheme.onSurface,
              onPressed: _loadSuggestedUsers,
              tooltip: 'Yenile',
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.colorScheme.surface,
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Kullanıcı ara...',
                      hintStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      prefixIcon:
                          Icon(Icons.search, color: theme.colorScheme.primary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear,
                                  color: theme.colorScheme.primary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _isSearching = false;
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    cursorColor: theme.colorScheme.primary,
                    onChanged: (value) {
                      if (value.isEmpty) {
                        setState(() {
                          _isSearching = false;
                        });
                      }
                    },
                    onSubmitted: _searchUsers,
                  ),
                ),
              ),

              // Categories
              if (!_isSearching)
                Container(
                  height: 50,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final isSelected = _selectedCategoryIndex == index;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: GestureDetector(
                          onTap: () => _changeCategory(index),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _categories[index],
                              style: TextStyle(
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Content Area
              Expanded(
                child: _isLoading
                    ? _buildLoadingView(theme)
                    : _errorMessage != null
                        ? _buildErrorView(theme)
                        : _isSearching
                            ? _buildSearchResultsView(theme)
                            : _buildSuggestedUsersView(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceVariant,
      highlightColor: theme.colorScheme.surface,
      child: ListView.builder(
        itemCount: 10,
        padding: EdgeInsets.all(16),
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: 16),
            height: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
            size: 60,
          ),
          SizedBox(height: 16),
          Text(
            'Bir Hata Oluştu',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              _errorMessage ?? 'Bilinmeyen bir hata oluştu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadSuggestedUsers,
            icon: Icon(Icons.refresh),
            label: Text('Tekrar Dene'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsView(ThemeData theme) {
    if (_loadingSearchResults) {
      return _buildLoadingView(theme);
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              size: 60,
            ),
            SizedBox(height: 16),
            Text(
              'Kullanıcı Bulunamadı',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Farklı bir arama terimi deneyin.',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildSearchResultItem(user, theme);
      },
    );
  }

  Widget _buildSearchResultItem(SearchAccountDTO user, ThemeData theme) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: theme.colorScheme.surface,
      elevation: 2,
      shadowColor: theme.shadowColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          backgroundImage: user.profilePhoto.isNotEmpty
              ? CachedNetworkImageProvider(user.profilePhoto)
              : null,
          child: user.profilePhoto.isEmpty
              ? Icon(Icons.person, color: theme.colorScheme.primary)
              : null,
        ),
        title: Text(
          user.fullName ?? '@${user.username}',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          user.fullName != null ? '@${user.username}' : '',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        trailing: OutlinedButton(
          onPressed: () {
            if (user.isFollow == true) {
              _unfollowUser(user.username);
            } else {
              _followUser(user.username);
            }
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: user.isFollow == true
                ? Colors.transparent
                : theme.colorScheme.primary,
            side: BorderSide(
              color: user.isFollow == true
                  ? theme.colorScheme.outline.withOpacity(0.5)
                  : theme.colorScheme.primary,
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(
            user.isFollow == true ? 'Takip Ediliyor' : 'Takip Et',
            style: TextStyle(
              color: user.isFollow == true
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
        onTap: () {
          // Navigate to user profile
          Navigator.pushNamed(
            context,
            '/user-profile',
            arguments: {'userId': user.id},
          );
        },
      ),
    );
  }

  Widget _buildSuggestedUsersView(ThemeData theme) {
    if (_suggestedUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_off,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              size: 60,
            ),
            SizedBox(height: 16),
            Text(
              'Öneri Bulunamadı',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Şu anda önerilebilecek kullanıcı bulunmuyor.',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        itemCount: _suggestedUsers.length,
        padding: EdgeInsets.all(16),
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildSuggestedUserCard(_suggestedUsers[index], theme),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuggestedUserCard(SuggestUserRequest user, ThemeData theme) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      color: theme.colorScheme.surface,
      elevation: 2,
      shadowColor: theme.shadowColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Profile photo
                GestureDetector(
                  onTap: () {
                    // Navigate to user profile
                  },
                  child: Hero(
                    tag: 'profile-${user.username}',
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(33),
                        child: user.profilePhotoUrl != null &&
                                user.profilePhotoUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: user.profilePhotoUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: theme.colorScheme.surfaceVariant,
                                  child: Icon(Icons.person,
                                      color: theme.colorScheme.primary,
                                      size: 40),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: theme.colorScheme.surfaceVariant,
                                  child: Icon(Icons.error,
                                      color: theme.colorScheme.error, size: 30),
                                ),
                              )
                            : Container(
                                color: theme.colorScheme.surfaceVariant,
                                child: Icon(Icons.person,
                                    color: theme.colorScheme.primary, size: 40),
                              ),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 16),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName ?? '@${user.username}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Text(
                        '@${user.username}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                      if (user.department != null) ...[
                        SizedBox(height: 4),
                        Text(
                          user.department!,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (user.mutualConnections != null &&
                          user.mutualConnections! > 0) ...[
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${user.mutualConnections} ortak bağlantı',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Follow button
                OutlinedButton(
                  onPressed: () {
                    if (user.isFollowing == true) {
                      _unfollowUser(user.username);
                    } else {
                      _followUser(user.username);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: user.isFollowing == true
                        ? Colors.transparent
                        : theme.colorScheme.primary,
                    side: BorderSide(
                      color: user.isFollowing == true
                          ? theme.colorScheme.outline.withOpacity(0.5)
                          : theme.colorScheme.primary,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    user.isFollowing == true ? 'Takip Ediliyor' : 'Takip Et',
                    style: TextStyle(
                      color: user.isFollowing == true
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            // Additional UI elements could be added here, like recent posts, etc.
          ],
        ),
      ),
    );
  }
}
